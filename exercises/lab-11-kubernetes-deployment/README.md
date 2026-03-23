# Lab 11 — Kubernetes Deployment

## Objectives

By the end of this lab you will be able to:

- Install `kubectl` and `kind` in a devcontainer environment
- Create a local Kubernetes cluster using kind (Kubernetes in Docker)
- Deploy an nginx workload using imperative `kubectl` commands
- Expose a Deployment as a Service and verify it responds to HTTP requests
- Understand the relationship between Deployments, ReplicaSets, and Pods
- Understand when to use LoadBalancer vs NodePort vs ClusterIP

---

## Background

### What is Kubernetes?

Kubernetes (K8s) is an open-source container orchestration platform originally developed by Google and donated to the CNCF in 2014. It automates the deployment, scaling, and management of containerised applications across a cluster of machines.

The core problem Kubernetes solves: running containers on a single host (as in Lab 10) is fine for development, but in production you need:

- **High availability** — if one machine dies, containers must restart elsewhere
- **Scaling** — add or remove replicas in response to load
- **Rolling updates** — deploy new versions without downtime
- **Service discovery** — containers must find each other by name, not IP
- **Resource management** — pack workloads efficiently across nodes

### Key Concepts

| Concept | What it is |
|---|---|
| **Node** | A physical or virtual machine that runs containerised workloads. A cluster has at least one control-plane node and one or more worker nodes. |
| **Pod** | The smallest deployable unit in Kubernetes. A Pod wraps one or more containers that share a network namespace and storage volumes. |
| **Deployment** | A higher-level object that declares the desired state for a set of Pods (image, replica count, update strategy). Kubernetes continuously reconciles the actual state to match. |
| **ReplicaSet** | Created automatically by a Deployment to ensure the correct number of Pod replicas are running. You rarely interact with ReplicaSets directly. |
| **Service** | A stable network endpoint (DNS name + virtual IP) that load-balances traffic across the Pods selected by a label. |
| **Namespace** | A virtual cluster within a physical cluster. Namespaces isolate resources for different teams or environments. |
| **kubectl** | The command-line tool for interacting with the Kubernetes API server. |
| **kind** | "Kubernetes in Docker" — runs a full K8s cluster inside Docker containers, ideal for local development and CI. |

### Cluster Bootstrapping — kubeadm vs kind vs minikube vs Docker Desktop

| Tool | Best for | How it works | Multi-node | Cloud parity |
|---|---|---|---|---|
| **kubeadm** | Production-like bare-metal or VM clusters | Installs and configures real K8s components on existing Linux hosts | Yes | High |
| **kind** | Local dev, CI pipelines, devcontainers | Runs K8s control-plane and workers as Docker containers | Yes (via config) | Medium |
| **minikube** | Local dev on a laptop | Starts a single-node VM or Docker container | Limited | Medium |
| **Docker Desktop** | Developer workstations (macOS/Windows) | Bundled K8s single-node, GUI toggle | No | Low |

This lab uses **kind** because the devcontainer has Docker-in-Docker. kubeadm would require real VMs or bare-metal hosts.

> **Production note:** In a real environment (AWS EKS, self-managed EC2), you would use `kubeadm init` on the control-plane node and `kubeadm join` on each worker. The kubectl commands you learn here are identical — only the cluster setup differs.

### The kubectl Workflow

```
You                 kubectl                API Server           etcd
 │                     │                       │                  │
 │── kubectl apply ──► │── HTTPS REST ────────►│── store state ──►│
 │                     │                       │                  │
 │                     │◄─ 200 OK ─────────────│                  │
 │                     │                       │                  │
 │                     │       Controller Manager watches etcd    │
 │                     │       and reconciles actual → desired    │
 │                     │       state by creating/deleting Pods    │
```

### Service Types

| Type | Reachable from | Use case |
|---|---|---|
| **ClusterIP** | Only within the cluster | Internal microservice communication |
| **NodePort** | Any node's IP on a static port (30000–32767) | Local dev, simple external access |
| **LoadBalancer** | External IP provisioned by cloud provider | Production workloads on AWS/GCP/Azure |

kind does not have a cloud provider, so `LoadBalancer` services stay in `<Pending>` state. This lab uses **NodePort** with `kubectl port-forward` to simulate external access.

---

## Scripts

Run the scripts in order from the `lab-11-kubernetes-deployment/` directory.

### 01-install-tools.sh

Checks whether `kubectl` and `kind` are installed and installs them if missing. Prints the version of each tool.

### 02-create-cluster.sh

Creates a kind cluster named `lab11`. Skips creation if the cluster already exists. Prints cluster-info and the node list.

### 03-deploy-nginx.sh

Creates an nginx Deployment imperatively using `kubectl create deployment`. Waits for the rollout to complete, then prints Deployments and Pods.

### 04-expose-service.sh

Exposes the Deployment as a NodePort Service. Uses `kubectl port-forward` to make the Service reachable on `localhost:8090` and verifies it with curl.

### 05-verify.sh

Prints a full summary: all resources, Deployment description, and recent cluster events.

### cleanup.sh

Deletes the nginx Deployment and Service, then destroys the kind cluster.

---

## Running the Lab

```bash
cd /workspaces/cloud-and-devops/exercises/lab-11-kubernetes-deployment

bash scripts/01-install-tools.sh
bash scripts/02-create-cluster.sh
bash scripts/03-deploy-nginx.sh
bash scripts/04-expose-service.sh
bash scripts/05-verify.sh

# When finished:
bash scripts/cleanup.sh
```

---

## What to Observe

- After `02-create-cluster.sh`: one node appears in `kubectl get nodes`, status `Ready`
- After `03-deploy-nginx.sh`: one Pod in `Running` state, Deployment shows `1/1 READY`
- After `04-expose-service.sh`: curl returns the nginx welcome page HTML
- After `05-verify.sh`: events show the Pod being scheduled and the container being pulled/started
