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
|   |-- dockerfile
|   `-- run.sh
`-- docker-compose.yaml
```

## Services

### n8n

n8n is used as the workflow automation layer. In the current setup it runs on port `5678` and stores its data in a Docker volume named `n8n_data`.

Configured environment values:

- `GENERIC_TIMEZONE=Asia/Taipei`
- `TZ=Asia/Taipei`
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true`
- `N8N_RUNNERS_ENABLED=true`

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
docker compose up -d
```

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

This script creates the `n8n_data` volume and starts an `n8n` container directly with Docker.

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