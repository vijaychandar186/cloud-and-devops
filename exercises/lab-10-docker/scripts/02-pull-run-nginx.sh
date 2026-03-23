#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 10 — Script 02: Pull and Run the Official nginx Image
# =============================================================================
# Pulls nginx:alpine from Docker Hub, starts it on port 8080, and verifies
# that it responds to HTTP requests.
# =============================================================================

CONTAINER_NAME="lab10-nginx"
HOST_PORT=8080

echo "============================================================"
echo " Lab 10 — Docker: Pull and Run nginx"
echo "============================================================"
echo ""

# ------------------------------------------------------------
# Cleanup any leftover container from a previous run
# ------------------------------------------------------------
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$" 2>/dev/null; then
    echo "INFO: Removing existing container '${CONTAINER_NAME}' from a previous run..."
    docker stop "${CONTAINER_NAME}" &>/dev/null || true
    docker rm   "${CONTAINER_NAME}" &>/dev/null || true
fi

# ------------------------------------------------------------
# 1. Pull the image
# ------------------------------------------------------------
echo "[1/5] Pulling nginx:alpine from Docker Hub..."
echo "      (--quiet suppresses the layer progress bars)"
docker pull nginx:alpine --quiet
echo "      Pull complete."
echo ""

# ------------------------------------------------------------
# 2. Run the container
# ------------------------------------------------------------
echo "[2/5] Starting container '${CONTAINER_NAME}' on port ${HOST_PORT}..."
echo "      docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:80 nginx:alpine"
echo ""
CONTAINER_ID=$(docker run -d --name "${CONTAINER_NAME}" -p "${HOST_PORT}:80" nginx:alpine)
echo "      Container ID: ${CONTAINER_ID}"
echo ""

# ------------------------------------------------------------
# 3. Show running containers
# ------------------------------------------------------------
echo "[3/5] Verifying container is running (docker ps):"
echo "------------------------------------------------------------"
docker ps --filter "name=${CONTAINER_NAME}"
echo ""

# ------------------------------------------------------------
# 4. Smoke-test with curl
# ------------------------------------------------------------
echo "[4/5] Sending HTTP request to http://localhost:${HOST_PORT} ..."
echo "      (waiting 1 second for nginx to be ready)"
sleep 1
echo "------------------------------------------------------------"
curl -s "http://localhost:${HOST_PORT}" | head -5
echo ""
echo "------------------------------------------------------------"
echo ""

# ------------------------------------------------------------
# 5. Summary
# ------------------------------------------------------------
echo "[5/5] Summary:"
echo ""
echo "  Nginx is running at http://localhost:${HOST_PORT}"
echo ""
echo "  Container ID : ${CONTAINER_ID}"
echo "  Container name: ${CONTAINER_NAME}"
echo ""
echo "  Useful commands:"
echo "    docker logs ${CONTAINER_NAME}          # view nginx access/error logs"
echo "    docker exec -it ${CONTAINER_NAME} sh   # open a shell inside the container"
echo "    docker stop ${CONTAINER_NAME}          # stop the container (keeps it)"
echo "    docker rm   ${CONTAINER_NAME}          # delete the stopped container"
echo "    docker stop ${CONTAINER_NAME} && docker rm ${CONTAINER_NAME}  # stop+remove"
echo ""
echo "  The container is left running for script 04 (commands demo)."
echo "  Run cleanup.sh when you are finished with the lab."
echo ""
echo "============================================================"
echo " nginx pulled and running. Proceed to script 03."
echo "============================================================"
