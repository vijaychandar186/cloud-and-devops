# Lab 12 — Kubernetes Manifests (Without Helm)

## Objectives

By the end of this lab you will be able to:

- Write Kubernetes YAML manifests for a Namespace, ConfigMap, Deployment, and Service
- Understand the difference between imperative `kubectl` commands and declarative `kubectl apply`
- Apply a set of manifests to a running cluster and verify the result
- Scale a Deployment and perform a zero-downtime rolling image update
- Explain what Helm adds on top of raw manifests and when you need it

---

## Background

### Imperative vs Declarative

| Approach | How you interact | Example |
|---|---|---|
| **Imperative** | Tell Kubernetes what to do right now | `kubectl create deployment nginx --image=nginx` |
| **Declarative** | Describe the desired state in a file | `kubectl apply -f deployment.yaml` |

The declarative approach is the industry standard for production because:

- **Idempotent** — running `kubectl apply` twice produces the same result
- **Version-controllable** — YAML files live in Git; changes are tracked and reviewed
- **Self-documenting** — the file describes exactly what is running
- **Auditable** — Git history shows who changed what and when

Lab 11 used imperative commands for speed and clarity while learning. This lab uses declarative manifests, which is how real teams manage Kubernetes.

### YAML Manifest Structure

Every Kubernetes manifest has four top-level fields:

| Field | Purpose | Example |
|---|---|---|
| `apiVersion` | Which API group and version defines this resource type | `apps/v1`, `v1`, `networking.k8s.io/v1` |
| `kind` | The resource type | `Deployment`, `Service`, `ConfigMap` |
| `metadata` | Identity: name, namespace, labels, annotations | `name: lab12-nginx` |
| `spec` | The desired state — differs per `kind` | replicas, containers, ports, selectors |

### Kubernetes Resource Types

| Resource | What it does |
|---|---|
| **Namespace** | Virtual cluster; isolates resources for different teams or environments |
| **ConfigMap** | Stores non-sensitive config as key/value pairs; injected into Pods as env vars or files |
| **Secret** | Like ConfigMap but for sensitive data (passwords, tokens); base64-encoded |
| **Deployment** | Manages a set of identical, stateless Pods; handles rolling updates and self-healing |
| **ReplicaSet** | Created by a Deployment; ensures the correct number of Pod replicas are running |
| **Pod** | The smallest deployable unit; one or more containers sharing network and storage |
| **Service** | Stable network endpoint (DNS + virtual IP) that routes to matching Pods |

### Rolling Update Strategy

When you update a Deployment (change the image tag, env vars, resource limits), Kubernetes performs a **rolling update** by default:

```
Before:  [Pod v1] [Pod v1] [Pod v1]
Step 1:  [Pod v1] [Pod v1] [Pod v2]  ← new Pod becomes Ready
Step 2:  [Pod v1] [Pod v2] [Pod v2]  ← old Pod terminated
Step 3:  [Pod v2] [Pod v2] [Pod v2]  ← update complete
```

Traffic is only sent to Ready Pods, so users never hit a Pod that is still starting up. The old ReplicaSet is kept (scaled to 0) for a configurable number of revisions, enabling `kubectl rollout undo`.

Default parameters (configurable in `spec.strategy`):

| Parameter | Default | Meaning |
|---|---|---|
| `maxUnavailable` | 25% | Maximum Pods that may be unavailable during the update |
| `maxSurge` | 25% | Maximum extra Pods that may exist temporarily above the replica count |

### Manifests in This Lab

```
manifests/
├── namespace.yaml    — Creates the "lab12" namespace
├── configmap.yaml    — APP_ENV and APP_VERSION config values
├── deployment.yaml   — 2 replicas of nginx:alpine, consuming the ConfigMap
└── service.yaml      — NodePort Service routing to the Deployment's Pods
```

Apply them in this order: namespace → configmap → deployment → service (the deployment references the configmap, which must exist first).

---

## Helm: What It Adds on Top of Raw Manifests

Raw YAML manifests are sufficient for static deployments, but they have limitations as complexity grows:

| Limitation | How Helm addresses it |
|---|---|
| Values are hardcoded in every file | `values.yaml` + template syntax (`{{ .Values.image.tag }}`) — one place to change |
| No concept of "install" vs "upgrade" vs "rollback" | Helm tracks **releases** with revision history |
| Deploying the same app to dev/staging/prod requires duplicated files | Pass different `values.yaml` files per environment |
| No dependency management | `Chart.yaml` `dependencies:` section pulls in sub-charts (e.g., PostgreSQL) |
| Sharing reusable configs is ad-hoc | Charts are packaged and published to registries (Artifact Hub) |

In short: raw manifests are the foundation; Helm adds **templating**, **packaging**, and **release management**. Start with raw manifests to understand the underlying objects, then adopt Helm when you need parameterisation or are distributing software.

---

## Scripts

Run from the `lab-12-kubernetes-manifests/` directory. This lab reuses the `lab11` kind cluster if it exists, creating a `lab12` cluster only if needed.

### 01-write-manifests-demo.sh

Prints each manifest file with explanations of every key field. Does not apply anything to the cluster — purely educational.

### 02-apply-manifests.sh

Applies all four manifests in dependency order and waits for the Deployment rollout to complete.

### 03-scale-and-rollout.sh

Scales the Deployment from 2 to 3 replicas, then performs a rolling image update from `nginx:alpine` to `nginx:1.25-alpine`. Shows rollout history and the `rollout undo` command.

### 04-verify.sh

Prints all resources in the `lab12` namespace, shows the ConfigMap YAML, describes the Deployment, and tests HTTP access via `kubectl port-forward` on `localhost:8091`.

### cleanup.sh

Deletes the `lab12` namespace (removing all resources inside it). Deletes the `lab12` kind cluster if one was created; leaves `lab11` intact.

---

## Running the Lab

```bash
cd /workspaces/cloud-and-devops/exercises/lab-12-kubernetes-manifests

# (Optional but recommended) Run Lab 11 first so the lab11 cluster exists
bash scripts/01-write-manifests-demo.sh
bash scripts/02-apply-manifests.sh
bash scripts/03-scale-and-rollout.sh
bash scripts/04-verify.sh

# When finished:
bash scripts/cleanup.sh
```

---

## What to Observe

- After `02-apply-manifests.sh`: `kubectl get all -n lab12` shows 2 Pods, 1 Deployment, 1 Service
- Inside a Pod, `echo $APP_ENV` returns `devcontainer` (injected from the ConfigMap)
- After `03-scale-and-rollout.sh`: 3 Pods running, revision history shows 2 entries
- After `04-verify.sh`: curl returns the nginx welcome page HTML on port 8091
