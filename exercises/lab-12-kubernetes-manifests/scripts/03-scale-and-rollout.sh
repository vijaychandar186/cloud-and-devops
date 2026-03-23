#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 12 — Script 03: Scale the Deployment and perform a rolling update
#
# CONCEPT: Rolling Updates
# ──────────────────────────────────────────────────────────────────────────────
# A rolling update replaces old Pods with new ones incrementally, ensuring
# that some replicas are always available throughout the update.
#
# Default strategy (RollingUpdate):
#   maxUnavailable: 25%  → at most 25% of Pods can be down at once
#   maxSurge:       25%  → at most 25% extra Pods can exist temporarily
#
# This means a 3-replica Deployment will:
#   1. Start 1 new Pod with the new image
#   2. Wait until it is Ready
#   3. Terminate 1 old Pod
#   4. Repeat until all Pods are updated
#
# Zero downtime is achieved because there are always running Pods serving
# traffic throughout the process.
# -----------------------------------------------------------------------------

echo "============================================================"
echo " Lab 12 — Scale and Rolling Update"
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

# ── Verify the Deployment exists ─────────────────────────────────────────────
if ! kubectl get deployment lab12-nginx -n lab12 --context "${CTX}" &>/dev/null 2>&1; then
  echo "ERROR: Deployment 'lab12-nginx' not found in namespace 'lab12'."
  echo "       Run scripts/02-apply-manifests.sh first."
  exit 1
fi

# ── Scale up ─────────────────────────────────────────────────────────────────
echo ""
echo "--- Scaling Deployment to 3 replicas ---"
echo "Current state:"
kubectl get pods -n lab12 --context "${CTX}"
echo ""
echo "Running: kubectl scale deployment/lab12-nginx --replicas=3 -n lab12"
kubectl scale deployment/lab12-nginx --replicas=3 -n lab12 --context "${CTX}"

echo ""
echo "Waiting for scale-up rollout..."
kubectl rollout status deployment/lab12-nginx -n lab12 --context "${CTX}"

echo ""
echo "--- Pods after scale-up ---"
kubectl get pods -n lab12 --context "${CTX}" -o wide

# ── Rolling image update ──────────────────────────────────────────────────────
cat <<'EXPLAIN'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ROLLING UPDATE — Zero-downtime image change
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  We will update the nginx container from "nginx:alpine" to
  "nginx:1.25-alpine". Kubernetes will replace Pods one at a time,
  keeping at least 2 out of 3 running throughout the update.

  In production you would edit the image tag in deployment.yaml
  and run "kubectl apply -f deployment.yaml" — the declarative way.
  Using "kubectl set image" is the imperative shortcut shown here.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EXPLAIN

echo ""
echo "--- Updating image to nginx:1.25-alpine ---"
kubectl set image deployment/lab12-nginx nginx=nginx:1.25-alpine \
  -n lab12 --context "${CTX}"

echo ""
echo "--- Watching rolling update ---"
kubectl rollout status deployment/lab12-nginx -n lab12 --context "${CTX}"

echo ""
echo "--- Pods after rolling update ---"
kubectl get pods -n lab12 --context "${CTX}" -o wide

echo ""
echo "--- Deployment revision history ---"
kubectl rollout history deployment/lab12-nginx -n lab12 --context "${CTX}"

echo ""
echo "Tip: to roll back to the previous image:"
echo "  kubectl rollout undo deployment/lab12-nginx -n lab12 --context ${CTX}"

echo ""
echo "============================================================"
echo " Scale and rolling update complete."
echo "============================================================"
echo ""
echo "Next step: bash scripts/04-verify.sh"
