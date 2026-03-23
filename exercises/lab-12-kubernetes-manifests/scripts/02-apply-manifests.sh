#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 12 — Script 02: Apply all manifests to the cluster (declarative approach)
#
# Cluster selection:
#   1. Prefer the "lab11" cluster created in Lab 11 (reuse, no extra setup)
#   2. Fall back to a "lab12" cluster if lab11 does not exist
#   3. Create a new "lab12" cluster if neither exists
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "${SCRIPT_DIR}")"
MANIFESTS_DIR="${LAB_DIR}/manifests"

echo "============================================================"
echo " Lab 12 — Apply Manifests"
echo "============================================================"

# ── Prerequisite check ───────────────────────────────────────────────────────
for tool in kubectl kind; do
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: '${tool}' is not installed."
    echo "       Run lab-11/scripts/01-install-tools.sh first."
    exit 1
  fi
done

# ── Cluster selection ────────────────────────────────────────────────────────
echo ""
echo "--- Selecting cluster ---"
EXISTING_CLUSTERS="$(kind get clusters 2>/dev/null || true)"
echo "Available kind clusters: ${EXISTING_CLUSTERS:-<none>}"

if echo "${EXISTING_CLUSTERS}" | grep -qx "lab11"; then
  CLUSTER="lab11"
  echo "Using existing cluster: lab11"
elif echo "${EXISTING_CLUSTERS}" | grep -qx "lab12"; then
  CLUSTER="lab12"
  echo "Using existing cluster: lab12"
else
  CLUSTER="lab12"
  echo "No existing cluster found. Creating cluster: lab12"
  kind create cluster --name lab12 --wait 60s
fi

CTX="kind-${CLUSTER}"
echo "Context: ${CTX}"

# ── Apply manifests in dependency order ──────────────────────────────────────
echo ""
echo "--- Applying namespace ---"
echo "  kubectl apply -f manifests/namespace.yaml"
kubectl apply -f "${MANIFESTS_DIR}/namespace.yaml" --context "${CTX}"

echo ""
echo "--- Applying ConfigMap ---"
echo "  kubectl apply -f manifests/configmap.yaml"
kubectl apply -f "${MANIFESTS_DIR}/configmap.yaml" --context "${CTX}"

echo ""
echo "--- Applying Deployment ---"
echo "  kubectl apply -f manifests/deployment.yaml"
kubectl apply -f "${MANIFESTS_DIR}/deployment.yaml" --context "${CTX}"

echo ""
echo "--- Waiting for Deployment rollout (up to 120s) ---"
kubectl rollout status deployment/lab12-nginx -n lab12 --context "${CTX}" --timeout=120s

echo ""
echo "--- Applying Service ---"
echo "  kubectl apply -f manifests/service.yaml"
kubectl apply -f "${MANIFESTS_DIR}/service.yaml" --context "${CTX}"

# ── Show final state ─────────────────────────────────────────────────────────
echo ""
echo "--- All resources in namespace lab12 ---"
kubectl get all -n lab12 --context "${CTX}"

echo ""
echo "--- ConfigMap ---"
kubectl get configmap lab12-config -n lab12 --context "${CTX}"

echo ""
echo "============================================================"
echo " All manifests applied. Cluster: ${CLUSTER}"
echo "============================================================"
echo ""
echo "Next step: bash scripts/03-scale-and-rollout.sh"
