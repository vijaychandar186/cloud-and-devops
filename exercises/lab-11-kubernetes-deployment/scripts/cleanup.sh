#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 11 — cleanup.sh: Remove all lab resources and destroy the kind cluster
# -----------------------------------------------------------------------------

CLUSTER_NAME="lab11"
CTX="kind-${CLUSTER_NAME}"

echo "============================================================"
echo " Lab 11 — Cleanup"
echo "============================================================"

echo ""
echo "--- Deleting nginx Deployment ---"
kubectl delete deployment nginx --context "${CTX}" 2>/dev/null || true

echo ""
echo "--- Deleting nginx Service ---"
kubectl delete service nginx --context "${CTX}" 2>/dev/null || true

echo ""
echo "--- Deleting kind cluster '${CLUSTER_NAME}' ---"
if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  kind delete cluster --name "${CLUSTER_NAME}"
  echo "Cluster '${CLUSTER_NAME}' deleted."
else
  echo "Cluster '${CLUSTER_NAME}' does not exist. Nothing to delete."
fi

echo ""
echo "============================================================"
echo " Cleanup complete. All Lab 11 resources have been removed."
echo "============================================================"
