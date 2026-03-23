#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ""
echo "============================================================"
echo "  Stage 3: Deploy to Kubernetes"
echo "============================================================"
echo ""

# --- Detect kind cluster ---
echo ">>> Detecting kind cluster..."
CLUSTER=$(kind get clusters 2>/dev/null | grep -E "^(lab11|lab12|lab15)$" | head -1 || true)

if [ -z "${CLUSTER}" ]; then
  echo ""
  echo "ERROR: No lab11/lab12/lab15 kind cluster found."
  echo "  Run scripts/02-build-image.sh first — it will create the cluster."
  exit 1
fi
echo "    Using cluster: ${CLUSTER}"
KUBE_CONTEXT="kind-${CLUSTER}"

# --- Apply manifests ---
echo ""
echo ">>> Applying namespace..."
kubectl apply -f "${LAB_DIR}/k8s/namespace.yaml" --context "${KUBE_CONTEXT}"

echo ""
echo ">>> Applying ConfigMap..."
kubectl apply -f "${LAB_DIR}/k8s/configmap.yaml" --context "${KUBE_CONTEXT}"

echo ""
echo ">>> Applying Deployment..."
kubectl apply -f "${LAB_DIR}/k8s/deployment.yaml" --context "${KUBE_CONTEXT}"

echo ""
echo ">>> Waiting for rollout to complete (timeout 120s)..."
kubectl rollout status deployment/lab15-app -n lab15 --timeout=120s --context "${KUBE_CONTEXT}"

echo ""
echo ">>> Applying Service..."
kubectl apply -f "${LAB_DIR}/k8s/service.yaml" --context "${KUBE_CONTEXT}"

echo ""
echo ">>> All resources in namespace lab15:"
kubectl get all -n lab15 --context "${KUBE_CONTEXT}"

echo ""
echo "  Stage 3 complete."
echo ""
