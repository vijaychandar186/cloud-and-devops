#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 12 — Script 04: Verify all lab12 resources and test HTTP access
# -----------------------------------------------------------------------------

LOCAL_PORT=8091

echo "============================================================"
echo " Lab 12 — Verify Resources"
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
  echo "ERROR: No lab11 or lab12 cluster found."
  echo "       Run scripts/02-apply-manifests.sh first."
  exit 1
fi

CTX="kind-${CLUSTER}"
echo "Using cluster: ${CLUSTER} (context: ${CTX})"

# ── All resources in lab12 namespace ─────────────────────────────────────────
echo ""
echo "--- All resources in namespace lab12 ---"
kubectl get all -n lab12 --context "${CTX}"

# ── ConfigMap contents ────────────────────────────────────────────────────────
echo ""
echo "--- ConfigMap: lab12-config ---"
kubectl get configmap lab12-config -n lab12 --context "${CTX}" -o yaml

# ── Deployment details ────────────────────────────────────────────────────────
echo ""
echo "--- Deployment: lab12-nginx ---"
kubectl describe deployment lab12-nginx -n lab12 --context "${CTX}"

# ── HTTP test via port-forward ────────────────────────────────────────────────
echo ""
echo "--- HTTP test via port-forward (localhost:${LOCAL_PORT}) ---"
echo "Forwarding localhost:${LOCAL_PORT} → service/lab12-nginx:80 in namespace lab12..."

kubectl port-forward service/lab12-nginx "${LOCAL_PORT}:80" \
  -n lab12 --context "${CTX}" &
PF_PID=$!

sleep 3

echo ""
echo "Sending HTTP request to http://localhost:${LOCAL_PORT} ..."
echo ""
curl -s --max-time 10 "http://localhost:${LOCAL_PORT}" | head -5 || {
  echo "WARNING: curl failed. The port-forward may still be starting."
  echo "         Try manually: curl http://localhost:${LOCAL_PORT}"
}

echo ""
echo "Stopping port-forward (PID: ${PF_PID})..."
kill "${PF_PID}" 2>/dev/null || true
wait "${PF_PID}" 2>/dev/null || true

echo ""
echo "============================================================"
echo " Verification complete."
echo " Run 'bash scripts/cleanup.sh' when you are done with Lab 12."
echo "============================================================"
