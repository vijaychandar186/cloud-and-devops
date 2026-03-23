#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 11 — Script 01: Install kubectl and kind
#
# Checks whether each tool is already present. Installs only what is missing.
# Designed to run inside the devcontainer (Docker-in-Docker enabled).
# -----------------------------------------------------------------------------

echo "============================================================"
echo " Lab 11 — Install Kubernetes Tools"
echo "============================================================"

# ── kubectl ──────────────────────────────────────────────────────────────────
echo ""
echo "--- Checking kubectl ---"

if command -v kubectl &>/dev/null; then
  echo "kubectl is already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  echo "kubectl not found. Installing..."

  # Fetch the latest stable release tag, then download the binary
  KUBECTL_VERSION="$(curl -sL https://dl.k8s.io/release/stable.txt)"
  echo "  Latest stable version: ${KUBECTL_VERSION}"

  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl

  echo "kubectl installed successfully."
fi

echo "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# ── kind ─────────────────────────────────────────────────────────────────────
echo ""
echo "--- Checking kind ---"

if command -v kind &>/dev/null; then
  echo "kind is already installed: $(kind version)"
else
  echo "kind not found. Installing v0.22.0..."

  curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
  chmod +x /tmp/kind
  sudo mv /tmp/kind /usr/local/bin/kind

  echo "kind installed successfully."
fi

echo "kind version: $(kind version)"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo " All tools are ready."
echo "  kubectl : $(command -v kubectl)"
echo "  kind    : $(command -v kind)"
echo "============================================================"
echo ""
echo "Next step: bash scripts/02-create-cluster.sh"
