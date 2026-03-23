#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 11 — Script 03: Deploy nginx using an imperative kubectl command
#
# CONCEPT: Deployments
# ──────────────────────────────────────────────────────────────────────────────
# A Deployment is a Kubernetes object that describes the desired state for a
# set of identical Pods:
#
#   Deployment ──manages──► ReplicaSet ──manages──► Pod(s)
#
#   • You tell the Deployment: "I want 1 replica of nginx:latest"
#   • The Deployment creates a ReplicaSet to enforce that count
#   • The ReplicaSet creates (and restarts) Pods to match
#   • If a Pod dies, the ReplicaSet immediately creates a replacement
#
# IMPERATIVE vs DECLARATIVE
# ──────────────────────────────────────────────────────────────────────────────
# This script uses IMPERATIVE commands (kubectl create deployment ...).
# Lab 12 uses DECLARATIVE manifests (kubectl apply -f deployment.yaml).
#
# Imperative:  fast, good for one-off tasks and learning
# Declarative: version-controllable, idempotent, production-standard
# -----------------------------------------------------------------------------

CLUSTER_NAME="lab11"
CTX="kind-${CLUSTER_NAME}"

echo "============================================================"
echo " Lab 11 — Deploy nginx"
echo " Context: ${CTX}"
echo "============================================================"

# ── Prerequisite check ───────────────────────────────────────────────────────
if ! kubectl get nodes --context "${CTX}" &>/dev/null; then
  echo "ERROR: Cannot reach cluster '${CLUSTER_NAME}'."
  echo "       Run scripts/02-create-cluster.sh first."
  exit 1
fi

# ── Create deployment (idempotent) ───────────────────────────────────────────
echo ""
echo "--- Creating Deployment ---"

if kubectl get deployment nginx --context "${CTX}" &>/dev/null 2>&1; then
  echo "Deployment 'nginx' already exists. Skipping creation."
else
  echo "Running: kubectl create deployment nginx --image=nginx"
  echo ""
  echo "  This creates:"
  echo "    1 Deployment object  → holds desired state (1 replica, image=nginx)"
  echo "    1 ReplicaSet object  → ensures correct Pod count"
  echo "    1 Pod                → runs the nginx container"
  echo ""
  kubectl create deployment nginx --image=nginx --context "${CTX}"
fi

# ── Wait for rollout ─────────────────────────────────────────────────────────
echo ""
echo "--- Waiting for rollout (up to 120s) ---"
echo "Kubernetes will pull the nginx image and start the container."
kubectl rollout status deployment/nginx --context "${CTX}" --timeout=120s

# ── Show state ───────────────────────────────────────────────────────────────
echo ""
echo "--- Deployments ---"
kubectl get deployments --context "${CTX}"

echo ""
echo "--- Pods ---"
kubectl get pods --context "${CTX}"

echo ""
echo "--- ReplicaSets (created automatically by the Deployment) ---"
kubectl get replicasets --context "${CTX}"

echo ""
echo "============================================================"
echo " nginx is running. READY column should show 1/1."
echo "============================================================"
echo ""
echo "Next step: bash scripts/04-expose-service.sh"
