#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ""
echo "============================================================"
echo "  Lab 15 — Cleanup"
echo "============================================================"
echo ""

# --- Detect kind cluster ---
CLUSTER=$(kind get clusters 2>/dev/null | grep -E "^(lab11|lab12|lab15)$" | head -1 || true)
KUBE_CONTEXT=""
if [ -n "${CLUSTER}" ]; then
  KUBE_CONTEXT="kind-${CLUSTER}"
fi

# --- Terraform destroy ---
echo ">>> Destroying Terraform-managed infrastructure..."
TERRAFORM_DIR="${LAB_DIR}/terraform"
if [ -f "${TERRAFORM_DIR}/terraform.tfstate" ]; then
  cd "${TERRAFORM_DIR}"
  terraform destroy -auto-approve -input=false || echo "    (terraform destroy encountered an error — continuing cleanup)"
else
  echo "    No terraform.tfstate found — skipping terraform destroy."
fi

# --- Delete Kubernetes namespace ---
echo ""
echo ">>> Deleting Kubernetes namespace lab15..."
if [ -n "${KUBE_CONTEXT}" ]; then
  kubectl delete namespace lab15 --context "${KUBE_CONTEXT}" 2>/dev/null || \
    echo "    Namespace lab15 not found or already deleted."
else
  echo "    No kind cluster detected — skipping namespace deletion."
fi

# --- Delete kind cluster if it was named lab15 ---
echo ""
if [ "${CLUSTER}" = "lab15" ]; then
  echo ">>> Deleting kind cluster 'lab15'..."
  kind delete cluster --name lab15
else
  echo ">>> Cluster '${CLUSTER}' was not created by this lab — leaving it in place."
fi

# --- Remove Docker image ---
echo ""
echo ">>> Removing Docker image lab15-app:latest..."
docker rmi lab15-app:latest 2>/dev/null || echo "    Image not found — already removed."

# --- Summary ---
echo ""
echo "------------------------------------------------------------"
echo "  Cleanup complete. Resources removed:"
echo "    - Terraform state (LocalStack S3 bucket + SNS topic)"
echo "    - Kubernetes namespace lab15 (Deployment, Service, ConfigMap)"
if [ "${CLUSTER}" = "lab15" ]; then
  echo "    - kind cluster: lab15"
fi
echo "    - Docker image: lab15-app:latest"
echo "------------------------------------------------------------"
echo ""
