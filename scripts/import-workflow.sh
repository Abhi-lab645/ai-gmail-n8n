#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${1:-n8n}"
WORKFLOW_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/workflows/rss-summarizer.json"

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: Workflow file not found at $WORKFLOW_FILE"
  exit 1
fi

echo "==> Verifying n8n container '$CONTAINER_NAME' is running..."
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Error: Container '${CONTAINER_NAME}' is not currently running."
  exit 1
fi

echo "==> Copying workflow to container..."
docker cp "$WORKFLOW_FILE" "${CONTAINER_NAME}:/tmp/rss-summarizer.json"

echo "==> Importing workflow into n8n..."
docker exec "$CONTAINER_NAME" n8n import:workflow --input=/tmp/rss-summarizer.json

echo "==> Current workflows in n8n:"
docker exec "$CONTAINER_NAME" n8n list:workflow

echo "==> Workflow imported successfully!"
