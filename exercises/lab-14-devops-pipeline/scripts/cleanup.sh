#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Cleanup: Lab 14 DevOps Pipeline ==="
echo ""

echo "Stopping containers (if running)..."
docker stop lab14-server lab14-smoke 2>/dev/null || true

echo "Removing containers..."
docker rm lab14-server lab14-smoke 2>/dev/null || true

echo "Removing Docker image..."
docker rmi lab14-server:latest 2>/dev/null || true

echo ""
echo "Cleanup complete. All Lab 14 containers and images have been removed."
