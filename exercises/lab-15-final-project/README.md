# Lab 15 — Final Mini Project: End-to-End DevOps Pipeline

## Objectives

This capstone lab brings together every tool introduced across the course into a single, cohesive end-to-end pipeline. You will use **Terraform** to provision cloud infrastructure (S3 and SNS) against **LocalStack**, **Docker** to build and tag a container image of a minimal Python web application, **kind** (Kubernetes-in-Docker) to deploy that image as a replicated workload, and **kubectl** port-forwarding plus **curl** to verify the running service. By completing this lab you will have exercised the full lifecycle of a modern cloud-native application — from infrastructure provisioning through containerisation, orchestration, and automated verification — entirely on your local machine.

---

## Architecture

```
                         Lab 15 Pipeline
  +-----------+
  |  Your     |
  |  machine  |
  +-----------+
       |
       v
  [Stage 1 — Terraform]
  Provisions LocalStack resources:
    - S3 bucket  (lab15-artifacts)       <- stores build artefacts
    - SNS topic  (lab15-pipeline-notifications)
       |
       v
  [Stage 2 — Docker]
  Builds lab15-app:latest
  Loads image into kind cluster
       |
       v
  [Stage 3 — Kubernetes (kind)]
  Deploys to namespace: lab15
    - ConfigMap
    - Deployment  (2 replicas, imagePullPolicy: Never)
    - Service     (NodePort, port 80 -> 8080)
       |
       v
  [Stage 4 — Verify]
  kubectl port-forward -> curl /  and  curl /health
  Validates HTTP 200 and JSON { "status": "ok" }
```

---

## Tool Map

| Tool            | First introduced | Role in this project                                      |
|-----------------|------------------|-----------------------------------------------------------|
| AWS CLI         | Lab 02           | Upload artefact to LocalStack S3, list bucket contents    |
| IAM / Security  | Lab 03           | Concepts: least-privilege; LocalStack skips real creds    |
| Linux / Bash    | Labs 04-05       | All pipeline scripts; SCRIPT_DIR pattern; set -euo pipefail |
| Shell config    | Lab 06           | PATH, environment variables used by the web server        |
| Terraform       | Lab 07           | Provision S3 bucket + SNS topic against LocalStack        |
| Ansible         | Labs 08-09       | Not used here; would handle node config in a larger setup |
| Docker          | Lab 10           | Build lab15-app:latest; Dockerfile best practices         |
| Kubernetes      | Lab 11           | kind cluster, Deployment, Service, namespace              |
| K8s manifests   | Lab 12           | ConfigMap, readinessProbe, envFrom                        |
| CI/CD tools     | Lab 13           | Concepts demonstrated by the scripted pipeline            |
| DevOps pipeline | Lab 14           | Full pipeline structure this lab is built upon            |
| LocalStack      | Lab 07 / Lab 15  | Local AWS emulator for Terraform provider endpoints       |

---

## Pre-requisites

The following tools must be installed and available on your PATH. Labs 01–13 cover their installation.

| Tool        | Minimum version | Check command              |
|-------------|-----------------|----------------------------|
| Docker      | 20+             | `docker --version`         |
| kind        | 0.17+           | `kind version`             |
| kubectl     | 1.26+           | `kubectl version --client` |
| Terraform   | 1.3+            | `terraform -version`       |
| AWS CLI     | 2+              | `aws --version`            |
| LocalStack  | 3+              | `localstack --version`     |
| curl        | any             | `curl --version`           |
| Python 3    | 3.10+           | `python3 --version`        |

**LocalStack must be running before executing Stage 1.**

```bash
localstack start -d
localstack wait -t 30
```

If you installed the tooling in Lab 11 or Lab 13 using `01-install-tools.sh`, all prerequisites are already present.

---

## Directory Structure

```
lab-15-final-project/
├── README.md
├── app/
│   ├── server.py          # Minimal Python stdlib HTTP server
│   └── Dockerfile         # python:3.12-alpine, exposes port 8080
├── terraform/
│   ├── versions.tf        # AWS provider ~> 5.0, Terraform >= 1.3.0
│   └── main.tf            # LocalStack provider, S3 bucket, SNS topic
├── k8s/
│   ├── namespace.yaml     # Namespace: lab15
│   ├── configmap.yaml     # APP_ENV, APP_VERSION
│   ├── deployment.yaml    # 2 replicas, imagePullPolicy: Never, readinessProbe
│   └── service.yaml       # NodePort, port 80 -> 8080
└── scripts/
    ├── 01-provision-infra.sh   # Stage 1: Terraform + LocalStack
    ├── 02-build-image.sh       # Stage 2: Docker build + kind load
    ├── 03-deploy-kubernetes.sh # Stage 3: kubectl apply manifests
    ├── 04-verify-pipeline.sh   # Stage 4: port-forward + curl tests
    └── cleanup.sh              # Tear down everything
```

---

## Pipeline Stages

### Stage 1 — Provision Infrastructure (`scripts/01-provision-infra.sh`)

Checks that LocalStack is healthy, then runs `terraform init` and `terraform apply` inside `terraform/`. This creates:

- An S3 bucket named `lab15-artifacts` (used to store pipeline run records — in production this would hold build artefacts, Lambda packages, or static assets).
- An SNS topic named `lab15-pipeline-notifications` (used to fan out build events — in production subscribers could be Slack webhooks, Lambda functions, or email endpoints).

After `apply`, the script uploads a timestamped `pipeline-run.txt` file to the bucket using the AWS CLI pointed at LocalStack, then lists the bucket to confirm.

> In a real AWS environment this stage would provision an ECR registry, an RDS database, and an EKS cluster (or equivalent managed Kubernetes service) using the exact same Terraform workflow.

### Stage 2 — Build Docker Image (`scripts/02-build-image.sh`)

Runs `docker build -t lab15-app:latest app/` from the lab root. The image is based on `python:3.12-alpine` and runs the stdlib HTTP server on port 8080.

The script then detects an existing `lab11`, `lab12`, or `lab15` kind cluster. If none is found it creates a new `lab15` cluster. The image is loaded into the cluster with `kind load docker-image`, making it available to the container runtime without a registry. The Kubernetes deployment uses `imagePullPolicy: Never` to enforce local-only image resolution.

### Stage 3 — Deploy to Kubernetes (`scripts/03-deploy-kubernetes.sh`)

Applies the four manifests in order:

1. `namespace.yaml` — creates the `lab15` namespace.
2. `configmap.yaml` — injects `APP_ENV=kubernetes` and `APP_VERSION=1.0.0` into pods.
3. `deployment.yaml` — starts 2 replicas with a readiness probe on `/health`.
4. `service.yaml` — exposes the deployment as a NodePort service on port 80.

The script waits up to 120 seconds for the rollout to complete before applying the Service, then prints all resources in the namespace.

### Stage 4 — End-to-End Verification (`scripts/04-verify-pipeline.sh`)

Opens a `kubectl port-forward` tunnel from `localhost:18080` to the `lab15-app` Service, then:

- `GET /` — verifies the root endpoint returns a plain-text greeting.
- `GET /health` — verifies the JSON health endpoint returns `{"status": "ok", ...}`.

On success it prints the pipeline summary table and exits 0.

---

## Running the Complete Pipeline

Start LocalStack, then run all four stages in sequence:

```bash
localstack start -d && localstack wait -t 30

for s in scripts/01-provision-infra.sh \
         scripts/02-build-image.sh \
         scripts/03-deploy-kubernetes.sh \
         scripts/04-verify-pipeline.sh; do
  bash "$s"
done
```

Or run each stage individually for step-by-step learning:

```bash
bash scripts/01-provision-infra.sh
bash scripts/02-build-image.sh
bash scripts/03-deploy-kubernetes.sh
bash scripts/04-verify-pipeline.sh
```

### Cleanup

```bash
bash scripts/cleanup.sh
```

This destroys the Terraform-managed LocalStack resources, deletes the `lab15` Kubernetes namespace, removes the Docker image, and (if the cluster was created by this lab) deletes the `lab15` kind cluster.

---

## How to Extend This Project

| Extension                    | How                                                                                   |
|------------------------------|---------------------------------------------------------------------------------------|
| GitHub Actions CI/CD         | Add `.github/workflows/pipeline.yml` that runs the four scripts on push to `main`    |
| Real Docker registry (ECR)   | Replace `kind load` with `docker push` to ECR; remove `imagePullPolicy: Never`       |
| Helm chart                   | Replace the raw YAML manifests with a Helm chart for parameterised releases           |
| Monitoring                   | Add a `kube-prometheus-stack` Helm release; scrape `/health` with Prometheus          |
| Secrets management           | Replace ConfigMap values with Kubernetes Secrets or External Secrets Operator         |
| Multi-environment deploys    | Parameterise `APP_ENV` via Terraform workspaces and Helm `--set` flags               |
| Blue/green deployments       | Add a second Deployment + Service and switch the Service selector on verify           |

---

## What You Have Learned Across All 15 Labs

- **Lab 01** — Set up an AWS account, understand regions, IAM basics, and the AWS Management Console.
- **Lab 02** — Create and rotate IAM access keys; configure the AWS CLI with named profiles.
- **Lab 03** — Apply IAM security best practices: MFA, least-privilege policies, roles vs. users.
- **Lab 04** — Install and configure a Linux environment; understand package managers and directory layout.
- **Lab 05** — Write Bash scripts with conditionals, loops, functions, and error handling.
- **Lab 06** — Customise shell configuration (`.bashrc`, `.zshrc`), manage PATH, and set environment variables.
- **Lab 07** — Use Terraform providers to declare and provision cloud resources (EC2, SNS) as code.
- **Lab 08** — Install Ansible, understand inventory files, and run ad-hoc commands against hosts.
- **Lab 09** — Structure Ansible playbooks into reusable roles with handlers, templates, and variables.
- **Lab 10** — Build Docker images, run containers, use volumes and environment variables, push to a registry.
- **Lab 11** — Deploy a workload to a local Kubernetes cluster with kind; use kubectl to manage resources.
- **Lab 12** — Write production-quality Kubernetes manifests: ConfigMaps, probes, resource limits, Services.
- **Lab 13** — Install and configure CI/CD tooling (Jenkins / GitHub Actions); understand pipeline concepts.
- **Lab 14** — Build a full DevOps pipeline that tests, builds, and packages a Dockerised application.
- **Lab 15** — Integrate every tool into a single end-to-end pipeline: Terraform → Docker → Kubernetes → verify.
