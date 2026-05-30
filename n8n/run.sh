#!/bin/sh
set -e

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

docker volume create n8n_data

docker run -it --rm -d \
    --name n8n \
    -p 5678:5678 \
    --env-file "$PROJECT_ROOT/.env" \
    --entrypoint /bin/sh \
    -e GENERIC_TIMEZONE="Asia/Taipei" \
    -e TZ="Asia/Taipei" \
    -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
    -v n8n_data:/home/node/.n8n \
    -v "$PROJECT_ROOT/scripts:/scripts:ro" \
    -v "$PROJECT_ROOT/n8n:/import/workflows:ro" \
    -v "$PROJECT_ROOT/n8n/credentials:/import/credentials:ro" \
    docker.n8n.io/n8nio/n8n \
    /scripts/n8n-entrypoint.sh
