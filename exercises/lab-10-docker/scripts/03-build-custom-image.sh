#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 10 — Script 03: Build a Custom Docker Image
# =============================================================================
# Builds the custom nginx image defined by the lab Dockerfile, runs it on
# port 8081, and explains the difference between pulling and building.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "${SCRIPT_DIR}")"

IMAGE_NAME="lab10-custom"
IMAGE_TAG="latest"
CONTAINER_NAME="lab10-custom"
HOST_PORT=8081

echo "============================================================"
echo " Lab 10 — Docker: Build a Custom Image"
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
# 1. Show the Dockerfile we are about to build
# ------------------------------------------------------------
echo "[1/5] Dockerfile at ${LAB_DIR}/Dockerfile:"
echo "------------------------------------------------------------"
cat "${LAB_DIR}/Dockerfile"
echo "------------------------------------------------------------"
echo ""
echo "      The Dockerfile starts FROM nginx:alpine and copies our"
echo "      custom index.html into the default nginx web root."
echo ""

# ------------------------------------------------------------
# 2. Build the image
# ------------------------------------------------------------
echo "[2/5] Building image '${IMAGE_NAME}:${IMAGE_TAG}'..."
echo "      docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ${LAB_DIR}"
echo ""
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" "${LAB_DIR}"
echo ""

# ------------------------------------------------------------
# 3. List the new image
# ------------------------------------------------------------
echo "[3/5] Verifying image exists (docker images):"
echo "------------------------------------------------------------"
docker images "${IMAGE_NAME}"
echo ""

# ------------------------------------------------------------
# 4. Run the custom image
# ------------------------------------------------------------
echo "[4/5] Starting container '${CONTAINER_NAME}' on port ${HOST_PORT}..."
CONTAINER_ID=$(docker run -d --name "${CONTAINER_NAME}" -p "${HOST_PORT}:80" "${IMAGE_NAME}:${IMAGE_TAG}")
echo "      Container ID: ${CONTAINER_ID}"
echo ""
echo "      Waiting 1 second for nginx to be ready..."
sleep 1

echo "      Verifying custom page is served:"
echo "------------------------------------------------------------"
curl -s "http://localhost:${HOST_PORT}" | grep "Lab 10" || {
    echo "WARNING: Expected 'Lab 10' in the response but did not find it."
    echo "         Full response:"
    curl -s "http://localhost:${HOST_PORT}" | head -20
}
echo ""
echo "------------------------------------------------------------"
echo ""

# ------------------------------------------------------------
# 5. Explain pull vs build
# ------------------------------------------------------------
echo "[5/5] Pulling a pre-built image vs building your own:"
echo ""
echo "  PULLING (docker pull / docker run <image>)"
echo "    - Downloads an image that someone else already built and pushed"
echo "      to a registry (e.g. Docker Hub)."
echo "    - Fast to get started; you trust the image author."
echo "    - Example: 'docker pull nginx:alpine' gives you the official"
echo "      nginx image maintained by the nginx team."
echo ""
echo "  BUILDING (docker build)"
echo "    - Reads a Dockerfile and creates a new image layer by layer."
echo "    - You control every byte: OS libs, config files, your app code."
echo "    - The resulting image can be pushed to any registry and pulled"
echo "      on any machine that has Docker."
echo "    - Example: our Dockerfile adds a custom index.html on top of"
echo "      the official nginx:alpine base — giving us lab10-custom."
echo ""
echo "  LAYERS & CACHING"
echo "    Each Dockerfile instruction creates a read-only layer. Docker"
echo "    caches layers; unchanged layers are reused on rebuilds, making"
echo "    subsequent builds much faster."
echo ""
echo "============================================================"
echo " Custom image built and running at http://localhost:${HOST_PORT}"
echo " Proceed to script 04."
echo "============================================================"
