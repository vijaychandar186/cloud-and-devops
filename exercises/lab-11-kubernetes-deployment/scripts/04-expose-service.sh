#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 11 — Script 04: Expose the nginx Deployment as a Service
#
# CONCEPT: Services
# ──────────────────────────────────────────────────────────────────────────────
# Pods are ephemeral — they come and go, and each gets a new IP address.
# A Service provides a stable DNS name and virtual IP that always routes to the
# correct Pods, regardless of how many times they have been restarted.
#
# SERVICE TYPES
# ──────────────────────────────────────────────────────────────────────────────
#   ClusterIP    → reachable only within the cluster (default)
#   NodePort     → reachable on each node's IP at a static high port (30000-32767)
#   LoadBalancer → cloud provider provisions an external load balancer + public IP
#
# This lab uses NodePort because kind has no cloud provider.
# On AWS/GCP/Azure you would use --type=LoadBalancer and get a public IP or DNS
# name automatically (e.g., from an AWS Application Load Balancer).
#
# kubectl port-forward is used here to tunnel localhost → cluster Service for
# verification purposes. It is a development tool, not a production pattern.
# -----------------------------------------------------------------------------

CLUSTER_NAME="lab11"
CTX="kind-${CLUSTER_NAME}"
LOCAL_PORT=8090

echo "============================================================"
echo " Lab 11 — Expose nginx as a Service"
echo " Context: ${CTX}"
echo "============================================================"

# ── Prerequisite check ───────────────────────────────────────────────────────
if ! kubectl get deployment nginx --context "${CTX}" &>/dev/null 2>&1; then
  echo "ERROR: Deployment 'nginx' not found."
  echo "       Run scripts/03-deploy-nginx.sh first."
  exit 1
fi

# ── Create Service (idempotent) ──────────────────────────────────────────────
echo ""
echo "--- Creating Service ---"

if kubectl get service nginx --context "${CTX}" &>/dev/null 2>&1; then
  echo "Service 'nginx' already exists. Skipping creation."
else
  echo "Running: kubectl expose deployment nginx --port=80 --type=NodePort"
  echo ""
  echo "  This creates a Service that:"
  echo "    • Selects all Pods with label app=nginx"
  echo "    • Listens on port 80 (cluster-internal)"
  echo "    • Assigns a random NodePort (30000-32767) for external access on each node"
  echo ""
  kubectl expose deployment nginx --port=80 --type=NodePort --context "${CTX}"
fi

echo ""
echo "--- Services ---"
kubectl get services --context "${CTX}"

# ── Port-forward and verify ──────────────────────────────────────────────────
echo ""
echo "--- Verifying with port-forward ---"
echo "Forwarding localhost:${LOCAL_PORT} → service/nginx:80 in the cluster..."
echo "(port-forward is a dev/debug tool; in production, use LoadBalancer or Ingress)"
echo ""

# Start port-forward in the background
kubectl port-forward service/nginx "${LOCAL_PORT}:80" --context "${CTX}" &
PF_PID=$!

# Give the tunnel a moment to establish
sleep 3

echo "Sending HTTP request to http://localhost:${LOCAL_PORT} ..."
echo ""
curl -s --max-time 10 "http://localhost:${LOCAL_PORT}" | head -5 || {
  echo "WARNING: curl failed. The port-forward may still be starting."
  echo "         Try manually: curl http://localhost:${LOCAL_PORT}"
}

# Clean up the background port-forward
echo ""
echo "Stopping port-forward (PID: ${PF_PID})..."
kill "${PF_PID}" 2>/dev/null || true
wait "${PF_PID}" 2>/dev/null || true

# ── Cloud note ───────────────────────────────────────────────────────────────
echo ""
echo "------------------------------------------------------------"
echo " Cloud note:"
echo "   On a real AWS cluster (EKS), use:"
echo "     kubectl expose deployment nginx --port=80 --type=LoadBalancer"
echo ""
echo "   AWS will provision an ELB and populate EXTERNAL-IP automatically."
echo "   kubectl get service nginx  →  shows the public DNS name."
echo "------------------------------------------------------------"

echo ""
echo "============================================================"
echo " Service exposed. nginx responded on localhost:${LOCAL_PORT}."
echo "============================================================"
echo ""
echo "Next step: bash scripts/05-verify.sh"
