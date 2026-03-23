#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 12 — cleanup.sh: Remove all lab12 resources
#
# Deletes the "lab12" namespace (which removes all resources inside it).
# If the cluster used was named "lab12", deletes that cluster too.
# If the cluster was "lab11", leaves it alone — cleanup.sh in Lab 11 handles it.
# -----------------------------------------------------------------------------

echo "============================================================"
echo " Lab 12 — Cleanup"
echo "============================================================"

# ── Cluster selection ────────────────────────────────────────────────────────
echo ""
echo "--- Selecting cluster ---"
EXISTING_CLUSTERS="$(kind get clusters 2>/dev/null || true)"

if echo "${EXISTING_CLUSTERS}" | grep -qx "lab11"; then
  CLUSTER="lab11"
elif echo "${EXISTING_CLUSTERS}" | grep -qx "lab12"; then
  CLUSTER="lab12"
else
  echo "No lab11 or lab12 cluster found. Nothing to clean up."
  exit 0
fi

CTX="kind-${CLUSTER}"
echo "Using cluster: ${CLUSTER} (context: ${CTX})"

# ── Delete the namespace (cascades to all resources inside it) ───────────────
echo ""
echo "--- Deleting namespace lab12 (and all resources within it) ---"
kubectl delete namespace lab12 --context "${CTX}" 2>/dev/null || true

# ── Delete the cluster if it was created for Lab 12 ─────────────────────────
echo ""
if [[ "${CLUSTER}" == "lab12" ]]; then
  echo "--- Deleting kind cluster 'lab12' ---"
  kind delete cluster --name lab12
  echo "Cluster 'lab12' deleted."
else
  echo "--- Cluster 'lab11' is shared with Lab 11 — leaving it intact. ---"
  echo "    To delete it, run: bash lab-11-kubernetes-deployment/scripts/cleanup.sh"
fi

echo ""
echo "============================================================"
echo " Cleanup complete. All Lab 12 resources have been removed."
echo "============================================================"
