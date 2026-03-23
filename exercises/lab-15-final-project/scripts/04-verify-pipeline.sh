#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

LOCAL_PORT=18080
PF_PID=""

cleanup_pf() {
  if [ -n "${PF_PID}" ]; then
    kill "${PF_PID}" 2>/dev/null || true
    PF_PID=""
  fi
}
trap cleanup_pf EXIT

echo ""
echo "============================================================"
echo "  === Final Pipeline Verification ==="
echo "============================================================"
echo ""

# --- Detect kind cluster ---
echo ">>> Detecting kind cluster..."
CLUSTER=$(kind get clusters 2>/dev/null | grep -E "^(lab11|lab12|lab15)$" | head -1 || true)

if [ -z "${CLUSTER}" ]; then
  echo ""
  echo "ERROR: No lab11/lab12/lab15 kind cluster found."
  echo "  Run the earlier pipeline stages first."
  exit 1
fi
echo "    Using cluster: ${CLUSTER}"
KUBE_CONTEXT="kind-${CLUSTER}"

# --- Show pod state ---
echo ""
echo ">>> Current pods in namespace lab15:"
kubectl get pods -n lab15 --context "${KUBE_CONTEXT}"

# --- Port-forward ---
echo ""
echo ">>> Starting port-forward: localhost:${LOCAL_PORT} -> service/lab15-app:80 ..."
kubectl port-forward service/lab15-app "${LOCAL_PORT}:80" -n lab15 \
  --context "${KUBE_CONTEXT}" &
PF_PID=$!
sleep 3

# --- HTTP tests ---
echo ""
echo ">>> GET http://localhost:${LOCAL_PORT}/"
ROOT_RESPONSE=$(curl -sf "http://localhost:${LOCAL_PORT}/")
echo "    Response: ${ROOT_RESPONSE}"

echo ""
echo ">>> GET http://localhost:${LOCAL_PORT}/health"
HEALTH_RESPONSE=$(curl -sf "http://localhost:${LOCAL_PORT}/health")
echo "    Response: ${HEALTH_RESPONSE}"

# Validate health status
HEALTH_STATUS=$(echo "${HEALTH_RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])" 2>/dev/null || true)
if [ "${HEALTH_STATUS}" != "ok" ]; then
  echo ""
  echo "ERROR: /health did not return status=ok (got: '${HEALTH_STATUS}')"
  exit 1
fi
echo "    Health check passed (status=ok)."

# --- Stop port-forward ---
cleanup_pf

# --- Pipeline summary table ---
echo ""
echo "------------------------------------------------------------"
echo "  Lab 15 --- Final Project Pipeline Summary"
echo "------------------------------------------------------------"
echo "  Stage         | Tool            | What was done"
echo "  --------------|-----------------|------------------------"
echo "  1. Infra      | Terraform       | S3 + SNS on LocalStack"
echo "  2. Build      | Docker          | lab15-app:latest image"
echo "  3. Deploy     | Kubernetes      | 2 replicas in lab15 ns"
echo "  4. Verify     | curl / kubectl  | HTTP 200 /health"
echo "------------------------------------------------------------"
echo ""
echo "  All pipeline stages completed successfully."
echo ""
