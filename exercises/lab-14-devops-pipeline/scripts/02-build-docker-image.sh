#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../app"

echo "=== Stage: Build Docker Image ==="
echo ""
echo "Building Docker image from $APP_DIR/Dockerfile ..."
echo ""

cd "$APP_DIR"

docker build -t lab14-server:latest .

echo ""
echo "Build complete. Local image list:"
echo ""
docker images lab14-server

echo ""
echo "-----------------------------------------------"
echo "The image lab14-server:latest is now ready."
echo "-----------------------------------------------"
echo ""
echo "Because everything the application needs is baked into the image, it"
echo "can run identically on any host where Docker is available — a developer"
echo "laptop, a CI runner, a cloud VM, or a Kubernetes node. This is the"
echo "core promise of containerisation."
