#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Verify Deployment ==="
echo ""

# 1. Check that the container is running
echo "--- Container status ---"
if docker ps --filter "name=lab14-server" --filter "status=running" | grep -q "lab14-server"; then
    echo "lab14-server is running."
else
    echo "ERROR: lab14-server container is not running." >&2
    echo "Run scripts/03-run-pipeline.sh first." >&2
    exit 1
fi
echo ""

# 2. Root endpoint — give the server a moment to bind after container start
sleep 2
echo "--- GET http://localhost:8888/ ---"
ROOT_RESPONSE=$(curl -sf http://localhost:8888/)
echo "$ROOT_RESPONSE"
echo ""

# 3. Health endpoint
echo "--- GET http://localhost:8888/health ---"
HEALTH_RESPONSE=$(curl -sf http://localhost:8888/health)
echo "$HEALTH_RESPONSE"
echo ""

# 4. docker ps summary for lab14-server
echo "--- docker ps (lab14-server) ---"
docker ps --filter "name=lab14-server" \
    --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "-------------------------------------------------------"
echo "In production this would be a health check from a load"
echo "balancer. The load balancer polls /health periodically;"
echo "if it returns a non-200 response the instance is taken"
echo "out of rotation and traffic is redirected to healthy"
echo "replicas until the problem is resolved."
echo "-------------------------------------------------------"
