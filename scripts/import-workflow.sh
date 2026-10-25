#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${1:-n8n}"
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/workflows"

echo "==> Verifying n8n container '$CONTAINER_NAME' is running..."
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Error: Container '${CONTAINER_NAME}' is not currently running."
  exit 1
fi

echo "==> Copying workflow files to container..."
for wf in "$WORKFLOW_DIR"/*.json; do
  filename="$(basename "$wf")"
  echo "  - Copying $filename"
  docker cp "$wf" "${CONTAINER_NAME}:/tmp/${filename}"
  echo "  - Importing $filename into n8n..."
  docker exec "$CONTAINER_NAME" n8n import:workflow --input="/tmp/${filename}"
done

echo ""
echo "==> Active workflows in n8n:"
docker exec "$CONTAINER_NAME" n8n list:workflow

echo ""
echo "==> All workflows imported successfully!"

