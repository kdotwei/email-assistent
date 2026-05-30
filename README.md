# Email Assistant

Email Assistant is an early-stage project for turning email streams into actionable tasks and reminders. The current repository focuses on the infrastructure layer for experimenting with workflow automation and LLM orchestration using n8n and Langflow.

The original project direction is to help students process high-volume school email more efficiently, such as identifying announcements, extracting deadlines, and surfacing messages that require action.

## Current Status

This repository is still in the setup phase.

- `docker-compose.yaml` starts two services: `n8n` and `langflow`.
- `n8n/run.sh` provides a standalone way to run `n8n` with a named Docker volume.
- `app/` exists as a placeholder for future application code.
- `langflow/` is currently empty and reserved for future project assets or configuration.
- `app/dockerfile` and `n8n/dockerfile` are present but currently empty.

## Repository Structure

```text
.
|-- app/
|   `-- dockerfile
|-- docs/
|   `-- IDEAS_MEMO.md
|-- langflow/
|-- n8n/
|   |-- credentials/       # credential templates (no real secrets)
|   |-- workflow/          # bundled workflow JSON files
|   |-- dockerfile
|   `-- run.sh
|-- scripts/
|   `-- n8n-entrypoint.sh  # container startup script
`-- docker-compose.yaml
```

## Services

### n8n

n8n is used as the workflow automation layer. In the current setup it runs on port `5678` and stores its data in a Docker volume named `n8n_data`.

Configured environment values:

- `GENERIC_TIMEZONE=Asia/Taipei`
- `TZ=Asia/Taipei`
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true`
- `N8N_ENCRYPTION_KEY` from `.env`

### Langflow

Langflow is used as the visual LLM orchestration interface. In the current setup it runs on port `7860` and stores its data in a Docker volume named `langflow_data`.

Configured environment values:

- `TZ=Asia/Taipei`
- `LANGFLOW_DATABASE_URL=sqlite:////app/langflow/langflow.db`

## Prerequisites

Before starting the project, make sure you have:

- Docker
- Docker Compose support

You can verify your environment with:

```bash
docker --version
docker compose version
```

## Getting Started

### Option 1: Start all services with Docker Compose

From the repository root:

```bash
cp .env.example .env
```

Open `.env` and set `N8N_ENCRYPTION_KEY` to a stable random value before starting the containers. You can generate one with:

```bash
openssl rand -hex 32
```

Then start the services:

```bash
docker compose up -d --wait
```

Before starting n8n, edit `.env` and set `N8N_ENCRYPTION_KEY` to a stable random value. If `N8N_ENCRYPTION_KEY` is empty, the startup script will exit immediately and the container will restart in a loop. Production environments must set this value explicitly. Do not rotate it casually: if it changes, n8n may no longer be able to decrypt existing credentials in the `n8n_data` volume.

`n8n` imports bundled workflows and supported credentials before it starts the server. The startup script then watches the n8n startup log and prints `n8n started; editor is ready at http://localhost:5678` only after n8n reports that the editor is accessible. `--wait` is still recommended so Docker Compose waits for the service health check too.

The root `.env` file is injected into the `n8n` container, so workflow expressions can read values such as `{{$env.NOTION_TOKEN}}`, `{{$env.GOOGLE_CLIENT_ID}}`, and `{{$env.GOOGLE_CLIENT_SECRET}}`.

To stop the services:

```bash
docker compose down
```

To stop the services and remove attached volumes:

```bash
docker compose down -v
```

After startup, the services should be available at:

- n8n: `http://localhost:5678`
- Langflow: `http://localhost:7860`

### Option 2: Start only n8n with the helper script

```bash
chmod +x n8n/run.sh
./n8n/run.sh
```

This script creates the `n8n_data` volume and starts an `n8n` container directly with Docker. It uses the same `.env`, workflow import, and credential import startup script as Docker Compose.

## Automatic Credential Import

The `n8n` container uses `scripts/n8n-entrypoint.sh` as its startup script. On container startup, the script checks `N8N_ENCRYPTION_KEY`, generates temporary credential JSON files in `/tmp`, imports the available credentials with `n8n import:credentials`, imports bundled workflow JSON files from `n8n/workflow/`, and then starts the n8n server.

Credential templates live in `n8n/credentials/` and do not contain real secrets. The generated files are created only inside the container and are removed when startup finishes.

Set these values in `.env` as needed:

```env
N8N_ENCRYPTION_KEY=
NOTION_TOKEN=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
LANGFLOW_API_KEY=
OPENAI_API_KEY=
```

Supported automatic credentials:

- `NOTION_TOKEN` imports a `Notion account` credential using the n8n `notionApi` type.
- `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` import a `Gmail account` OAuth2 credential using the n8n `gmailOAuth2` type.
- `LANGFLOW_API_KEY` imports a `Langflow API Key` header credential for HTTP Request nodes.
- `OPENAI_API_KEY` imports an `OpenAI API` credential using the n8n `openAiApi` type.

Google OAuth is only partially automated. The startup import can prefill the Google Client ID and Client Secret, but it cannot complete Google consent or create Gmail access and refresh tokens. After startup, open the `Gmail account` credential in the n8n UI and run `Sign in with Google` once.

To avoid duplicate credentials, the script checks for existing credentials by name and type and writes marker files under `/home/node/.n8n/.startup-imports` in the persistent `n8n_data` volume. If you change `.env` and need to import again, remove the relevant marker file from the container volume and delete or rename the old credential in the n8n UI first. To force all startup imports again without deleting the data volume:

```bash
docker compose exec n8n rm -f /home/node/.n8n/.startup-imports/*.imported
docker compose restart n8n
```

To disable automatic credential import, leave the optional credential variables empty in `.env`. `N8N_ENCRYPTION_KEY` is still required for Compose startup.

Common issues:

- If `N8N_ENCRYPTION_KEY` changes after credentials have been created, existing credentials may fail to decrypt. Restore the old key or recreate the credentials.
- Google OAuth redirect URI must match the URI shown by n8n. For local Compose usage this usually points to `http://localhost:5678/rest/oauth2-credential/callback`, but always copy the value from the n8n UI.
- `localhost` inside a container is the container itself, not the host machine. Use Docker service names such as `http://langflow:7860` for container-to-container calls on the Compose network.

## Project Direction

Based on the idea memo in `docs/IDEAS_MEMO.md`, the intended product direction includes ideas such as:

- scanning school email and identifying important messages
- extracting assignments, deadlines, or action-required items
- mapping course identifiers to readable course names
- optionally syncing extracted events to external tools such as calendars, Notion, Slack, or Discord

These features are not implemented in this repository yet.

## Notes

- The repository currently contains infrastructure scaffolding rather than a finished application.
- No application service is wired into `docker-compose.yaml` yet.
- The placeholder Dockerfiles in `app/` and `n8n/` should be completed before they are used in a custom image workflow.

## Next Steps

Reasonable next implementation steps for this repository are:

1. Define the email ingestion flow and source provider.
2. Build a first n8n workflow for email parsing and classification.
3. Add Langflow components or flows for extraction and summarization.
4. Implement an application layer in `app/` for persistence, UI, or integrations.
5. Add environment variable documentation and example configuration files.
