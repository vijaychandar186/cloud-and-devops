#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Lab 12 — Script 01: Walk through the manifest files and explain key concepts
#
# This script does NOT apply anything to the cluster. It is a guided tour of
# the YAML files in the manifests/ directory, explaining every important field.
# -----------------------------------------------------------------------------

# Resolve the manifests directory relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "${SCRIPT_DIR}")"
MANIFESTS_DIR="${LAB_DIR}/manifests"

echo "============================================================"
echo " Lab 12 — Manifest Walkthrough"
echo " Manifests directory: ${MANIFESTS_DIR}"
echo "============================================================"

# ── Imperative vs Declarative ─────────────────────────────────────────────────
cat <<'EXPLAIN'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 IMPERATIVE vs DECLARATIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Imperative  (Lab 11 approach):
    kubectl create deployment nginx --image=nginx
    kubectl expose deployment nginx --port=80 --type=NodePort

    → You issue commands that describe WHAT TO DO right now.
    → Not stored anywhere; hard to reproduce; can't be reviewed in Git.

  Declarative (Lab 12 approach):
    kubectl apply -f manifests/deployment.yaml
    kubectl apply -f manifests/service.yaml

    → You write YAML files that describe the DESIRED STATE.
    → kubectl apply reads the file and figures out what to create/update/delete.
    → Idempotent: running apply twice is safe.
    → Version-controllable: stored in Git, reviewed in PRs, auditable.
    → The industry standard for all production Kubernetes work.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EXPLAIN

# ── namespace.yaml ───────────────────────────────────────────────────────────
cat <<'EXPLAIN'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 manifests/namespace.yaml — Namespace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  A Namespace is a virtual cluster within a physical cluster.
  It isolates resources so that teams or environments do not
  interfere with each other.

  All resources in this lab live in the "lab12" namespace,
  keeping them separate from the "default" namespace used in Lab 11.
EXPLAIN

echo ""
cat "${MANIFESTS_DIR}/namespace.yaml"

# ── configmap.yaml ───────────────────────────────────────────────────────────
cat <<'EXPLAIN'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 manifests/configmap.yaml — ConfigMap
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  A ConfigMap stores non-sensitive configuration data as key/value
  pairs. It decouples configuration from the container image so you
  can change settings without rebuilding or retagging images.

  The Deployment uses "envFrom: configMapRef" to inject every key
  from this ConfigMap as an environment variable inside the container.

  For sensitive data (passwords, API keys) use a Secret instead —
  the syntax is almost identical but the data is base64-encoded
  (and optionally encrypted at rest by the cluster).
EXPLAIN

echo ""
cat "${MANIFESTS_DIR}/configmap.yaml"

# ── deployment.yaml ──────────────────────────────────────────────────────────
cat <<'EXPLAIN'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 manifests/deployment.yaml — Deployment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  The Deployment is the most important object for running stateless
  workloads. Every field is annotated inline in the YAML file.
  Key points:

  apiVersion: apps/v1
    → Deployments live in the "apps" API group, version v1.
      Core objects (Pod, Service, Namespace) use just "v1".

  spec.replicas: 2
    → Kubernetes ensures exactly 2 Pods are always running.
      If one crashes, a new one is created within seconds.

  spec.selector.matchLabels
    → Connects the Deployment to the Pods it manages.
      Must match spec.template.metadata.labels exactly.

  spec.template
    → The blueprint for every Pod. Contains the container
      definition, environment variables, volume mounts, etc.

  envFrom: configMapRef
    → Injects all ConfigMap keys as env vars without hardcoding
      values in the Deployment itself.
EXPLAIN

echo ""
cat "${MANIFESTS_DIR}/deployment.yaml"

# ── service.yaml ─────────────────────────────────────────────────────────────
cat <<'EXPLAIN'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 manifests/service.yaml — Service
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  The Service uses a label selector to discover the Pods it should
  route traffic to. When Pods are replaced (e.g., during a rolling
  update), the Service automatically starts routing to the new Pods
  because they carry the same labels.

  spec.ports.port vs targetPort:
    port        → the port the Service itself listens on (inside cluster)
    targetPort  → the port on the Pod that the Service forwards to

  type: NodePort
    → A random port in the 30000-32767 range is opened on every node.
    → On AWS, replace with type: LoadBalancer to provision an ELB.
EXPLAIN

echo ""
cat "${MANIFESTS_DIR}/service.yaml"

echo ""
echo "============================================================"
echo " Walkthrough complete."
echo " Next step: bash scripts/02-apply-manifests.sh"
echo "============================================================"
