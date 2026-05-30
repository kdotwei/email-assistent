#!/bin/sh
set -e

N8N_HOME="${N8N_USER_FOLDER:-/home/node/.n8n}"
IMPORT_ROOT="/import"
WORKFLOW_DIR="${IMPORT_ROOT}/workflows"
CREDENTIAL_TEMPLATE_DIR="${IMPORT_ROOT}/credentials"
MARKER_DIR="${N8N_HOME}/.startup-imports"
TMP_DIR="$(mktemp -d /tmp/n8n-import.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [ -z "${N8N_ENCRYPTION_KEY:-}" ]; then
  echo "N8N_ENCRYPTION_KEY must be set before starting n8n." >&2
  exit 1
fi

mkdir -p "$MARKER_DIR"

render_template() {
  template_file="$1"
  output_file="$2"

  TEMPLATE_FILE="$template_file" OUTPUT_FILE="$output_file" node <<'NODE'
const fs = require('fs');

const templateFile = process.env.TEMPLATE_FILE;
const outputFile = process.env.OUTPUT_FILE;
const replacements = {
  __NOTION_TOKEN__: process.env.NOTION_TOKEN || '',
  __GOOGLE_CLIENT_ID__: process.env.GOOGLE_CLIENT_ID || '',
  __GOOGLE_CLIENT_SECRET__: process.env.GOOGLE_CLIENT_SECRET || '',
  __LANGFLOW_API_KEY__: process.env.LANGFLOW_API_KEY || '',
  __OPENAI_API_KEY__: process.env.OPENAI_API_KEY || '',
};

let content = fs.readFileSync(templateFile, 'utf8');
for (const [placeholder, value] of Object.entries(replacements)) {
  const escaped = JSON.stringify(value).slice(1, -1);
  content = content.split(placeholder).join(escaped);
}

JSON.parse(content);
fs.writeFileSync(outputFile, content, { mode: 0o600 });
NODE
}

credential_exists() {
  credential_name="$1"
  credential_type="$2"
  export_file="${TMP_DIR}/existing-credentials.json"

  if ! /docker-entrypoint.sh export:credentials --all --output="$export_file" >/dev/null 2>&1; then
    return 1
  fi

  CREDENTIAL_NAME="$credential_name" CREDENTIAL_TYPE="$credential_type" EXPORT_FILE="$export_file" node <<'NODE'
const fs = require('fs');

const exportFile = process.env.EXPORT_FILE;
const wantedName = process.env.CREDENTIAL_NAME;
const wantedType = process.env.CREDENTIAL_TYPE;

let credentials = [];
try {
  credentials = JSON.parse(fs.readFileSync(exportFile, 'utf8'));
} catch {
  process.exit(1);
}

if (!Array.isArray(credentials)) {
  credentials = [credentials];
}

const found = credentials.some((credential) => {
  return credential && credential.name === wantedName && credential.type === wantedType;
});

process.exit(found ? 0 : 1);
NODE
}

import_credential() {
  marker_name="$1"
  credential_name="$2"
  credential_type="$3"
  template_file="$4"

  marker_file="${MARKER_DIR}/credential-${marker_name}.imported"
  output_file="${TMP_DIR}/${marker_name}.credentials.json"

  if [ -f "$marker_file" ]; then
    echo "Skipping ${credential_name}; startup import marker already exists."
    return 0
  fi

  if credential_exists "$credential_name" "$credential_type"; then
    echo "Skipping ${credential_name}; credential already exists."
    touch "$marker_file"
    return 0
  fi

  render_template "$template_file" "$output_file"
  /docker-entrypoint.sh import:credentials --input="$output_file" >/dev/null
  touch "$marker_file"
  echo "Imported ${credential_name} credential."
}

import_workflows() {
  marker_file="${MARKER_DIR}/workflows.imported"

  if [ -f "$marker_file" ]; then
    echo "Skipping workflow import; startup import marker already exists."
    return 0
  fi

  found_workflow=0
  for workflow_file in "$WORKFLOW_DIR"/*.json; do
    if [ ! -f "$workflow_file" ]; then
      continue
    fi

    /docker-entrypoint.sh import:workflow --input="$workflow_file" >/dev/null
    found_workflow=1
  done

  if [ "$found_workflow" -eq 1 ]; then
    touch "$marker_file"
    echo "Imported bundled workflows."
  else
    echo "No bundled workflows found to import."
  fi
}

stop_n8n() {
  if [ -n "${N8N_PID:-}" ] && kill -0 "$N8N_PID" 2>/dev/null; then
    kill -TERM "$N8N_PID" 2>/dev/null || true
    wait "$N8N_PID" 2>/dev/null || true
  fi
  exit 143
}

forward_n8n_logs() {
  editor_line_seen=0

  while IFS= read -r log_line; do
    echo "$log_line"

    if [ "$editor_line_seen" -eq 1 ] && [ -n "$log_line" ]; then
      echo "n8n started; editor is ready at ${log_line}"
      touch "$N8N_STARTED_MARKER"
      editor_line_seen=2
      continue
    fi

    if [ "$log_line" = "Editor is now accessible via:" ]; then
      editor_line_seen=1
    fi
  done < "$N8N_LOG_PIPE"
}

wait_for_n8n() {
  attempts=0

  until [ -f "$N8N_STARTED_MARKER" ]; do
    if ! kill -0 "$N8N_PID" 2>/dev/null; then
      wait "$N8N_PID"
      exit $?
    fi

    attempts=$((attempts + 1))
    if [ "$attempts" -ge 60 ] && wget -q -O - http://127.0.0.1:5678/healthz >/dev/null 2>&1; then
      echo "n8n started; health check is passing at http://localhost:5678"
      touch "$N8N_STARTED_MARKER"
      return 0
    fi

    sleep 2
  done
}

if [ -n "${NOTION_TOKEN:-}" ]; then
  import_credential "notion" "Notion account" "notionApi" "${CREDENTIAL_TEMPLATE_DIR}/notion.credentials.json"
else
  echo "Skipping Notion credential; NOTION_TOKEN is not set."
fi

if [ -n "${GOOGLE_CLIENT_ID:-}" ] && [ -n "${GOOGLE_CLIENT_SECRET:-}" ]; then
  import_credential "google-oauth" "Gmail account" "gmailOAuth2" "${CREDENTIAL_TEMPLATE_DIR}/google-oauth.credentials.json"
else
  echo "Skipping Gmail OAuth2 credential; GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET is not set."
fi

if [ -n "${LANGFLOW_API_KEY:-}" ]; then
  import_credential "langflow" "Langflow API Key" "httpHeaderAuth" "${CREDENTIAL_TEMPLATE_DIR}/langflow.credentials.json"
else
  echo "Skipping Langflow credential; LANGFLOW_API_KEY is not set."
fi

if [ -n "${OPENAI_API_KEY:-}" ]; then
  import_credential "openai" "OpenAI API" "openAiApi" "${CREDENTIAL_TEMPLATE_DIR}/openai.credentials.json"
else
  echo "Skipping OpenAI credential; OPENAI_API_KEY is not set."
fi

import_workflows

N8N_LOG_PIPE="${TMP_DIR}/n8n-startup.log.pipe"
N8N_STARTED_MARKER="${TMP_DIR}/n8n.started"
mkfifo "$N8N_LOG_PIPE"

forward_n8n_logs &
N8N_LOG_PID="$!"

/docker-entrypoint.sh start > "$N8N_LOG_PIPE" 2>&1 &
N8N_PID="$!"

trap stop_n8n INT TERM

wait_for_n8n
set +e
wait "$N8N_PID"
N8N_EXIT_CODE="$?"
wait "$N8N_LOG_PID" 2>/dev/null || true
set -e
exit "$N8N_EXIT_CODE"
