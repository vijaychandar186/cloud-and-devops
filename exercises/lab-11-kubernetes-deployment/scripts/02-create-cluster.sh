#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 11 — Script 02: Create a kind cluster named "lab11"
#
# kind (Kubernetes in Docker) runs a full Kubernetes control-plane and worker
# as Docker containers, making it ideal for devcontainers and CI.
#
# kubeadm equivalent (for real VMs / bare-metal):
#   sudo kubeadm init --pod-network-cidr=192.168.0.0/16
#   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
#   sudo kubeadm join <control-plane-host>:<port> --token <token> ...
#
# With kind we skip all of that and get a working cluster in ~60 seconds.
# -----------------------------------------------------------------------------

CLUSTER_NAME="lab11"

echo "============================================================"
echo " Lab 11 — Create kind Cluster: ${CLUSTER_NAME}"
echo "============================================================"

# ── Prerequisite check ───────────────────────────────────────────────────────
for tool in kubectl kind docker; do
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: '${tool}' is not installed. Run scripts/01-install-tools.sh first."
    exit 1
  fi
done

# ── Check if cluster already exists ─────────────────────────────────────────
echo ""
echo "--- Checking existing kind clusters ---"
EXISTING=$(kind get clusters 2>/dev/null || true)
echo "Existing clusters: ${EXISTING:-<none>}"

if echo "${EXISTING}" | grep -qx "${CLUSTER_NAME}"; then
  echo "Cluster '${CLUSTER_NAME}' already exists. Skipping creation."
else
  echo ""
  echo "--- Creating cluster '${CLUSTER_NAME}' ---"
  echo "This runs a K8s control-plane + worker node inside Docker containers."
  echo "Equivalent to 'kubeadm init' on a real machine, but fully automated."
  echo ""

  kind create cluster --name "${CLUSTER_NAME}" --wait 60s

  echo ""
  echo "Cluster '${CLUSTER_NAME}' created successfully."
fi

# ── Cluster info ─────────────────────────────────────────────────────────────
echo ""
echo "--- Cluster Info ---"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo ""
echo "--- Nodes ---"
# The control-plane node acts as both control-plane and worker in a single-node kind setup
kubectl get nodes --context "kind-${CLUSTER_NAME}"

echo ""
echo "--- Kubernetes version ---"
kubectl version --context "kind-${CLUSTER_NAME}"

echo ""
echo "============================================================"
echo " Cluster '${CLUSTER_NAME}' is ready."
echo " Context: kind-${CLUSTER_NAME}"
echo "============================================================"
echo ""
echo "Next step: bash scripts/03-deploy-nginx.sh"
