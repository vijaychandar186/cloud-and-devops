#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ""
echo "============================================================"
echo "  Stage 2: Build Docker Image"
echo "============================================================"
echo ""

# --- Build image ---
echo ">>> Building lab15-app:latest from ${LAB_DIR}/app/ ..."
docker build -t lab15-app:latest "${LAB_DIR}/app/"

echo ""
echo ">>> Local image list:"
docker images lab15-app

echo ""
echo "------------------------------------------------------------"
echo "  NOTE: The Kubernetes manifest uses imagePullPolicy: Never."
echo "  This tells kind to use the locally loaded image instead of"
echo "  pulling from a registry. The 'kind load docker-image'"
echo "  command below imports the image directly into the cluster's"
echo "  container runtime so Kubernetes can schedule it."
echo "------------------------------------------------------------"
echo ""

# --- Detect or create kind cluster ---
echo ">>> Detecting kind cluster..."
CLUSTER=$(kind get clusters 2>/dev/null | grep -E "^(lab11|lab12|lab15)$" | head -1 || true)

if [ -z "${CLUSTER}" ]; then
  echo "    No existing lab11/lab12/lab15 cluster found — creating lab15..."
  kind create cluster --name lab15 --wait 60s
  CLUSTER="lab15"
else
  echo "    Using existing cluster: ${CLUSTER}"
fi

# --- Load image into kind ---
echo ""
echo ">>> Loading lab15-app:latest into kind cluster '${CLUSTER}'..."
kind load docker-image lab15-app:latest --name "${CLUSTER}"

# --- Confirm image is present in the cluster runtime ---
echo ""
echo ">>> Confirming image inside cluster node (crictl):"
docker exec "${CLUSTER}-control-plane" crictl images 2>/dev/null | grep lab15 || \
  echo "    (crictl output not available — image load reported success above)"

echo ""
echo "  Stage 2 complete."
echo ""
