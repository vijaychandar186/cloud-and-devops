#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 11 — Script 05: Verify the Deployment and cluster state
# -----------------------------------------------------------------------------

CLUSTER_NAME="lab11"
CTX="kind-${CLUSTER_NAME}"

echo "============================================================"
echo " Lab 11 — Verify Cluster State"
echo " Context: ${CTX}"
echo "============================================================"

# ── All resources in default namespace ───────────────────────────────────────
echo ""
echo "--- All resources (default namespace) ---"
kubectl get all --context "${CTX}"

# ── Deployment details ───────────────────────────────────────────────────────
echo ""
echo "--- Deployment: nginx (key fields) ---"
kubectl describe deployment nginx --context "${CTX}" | grep -E \
  "^Name:|^Namespace:|^Replicas:|^StrategyType:|^Image:|^Port:|^Labels:|^Selector:|^NewReplicaSet:|Conditions:"

echo ""
echo "--- Full Deployment description ---"
kubectl describe deployment nginx --context "${CTX}"

# ── Pod details ──────────────────────────────────────────────────────────────
echo ""
echo "--- Pod list with node assignment ---"
kubectl get pods --context "${CTX}" -o wide

# ── Recent events ────────────────────────────────────────────────────────────
echo ""
echo "--- Recent cluster events (last 10) ---"
echo "Events show the lifecycle: Scheduled → Pulling → Pulled → Created → Started"
kubectl get events --context "${CTX}" --sort-by='.lastTimestamp' | tail -10

echo ""
echo "============================================================"
echo " Verification complete."
echo " Run 'bash scripts/cleanup.sh' when you are done with Lab 11."
echo "============================================================"
