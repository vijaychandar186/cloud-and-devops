# Lab 14 — Mini Project: Implement a DevOps Pipeline

## Objectives

By the end of this lab you will be able to:

1. Describe what a DevOps pipeline is and why each stage exists.
2. Write unit tests for a Python application using the stdlib `unittest` module.
3. Build a Docker image from a `Dockerfile` and verify it runs correctly.
4. Execute a simulated end-to-end pipeline (Test → Build → Smoke Test → Deploy) using shell scripts.
5. Read and interpret a `Jenkinsfile` and explain how to wire it into a real Jenkins server.
6. Identify ways to extend the pipeline with linting, coverage reporting, and image registry pushes.

---

## What is a DevOps Pipeline?

A DevOps pipeline is an automated sequence of steps that takes code from a developer's commit all the way to a running service. Every step has a clear purpose and a clear failure mode; if any step fails the pipeline stops and no broken artefact reaches the next environment.

```
  Developer
     │
     │  git push
     ▼
  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
  │ Checkout │────▶│   Test   │────▶│  Build   │────▶│  Smoke   │────▶│  Deploy  │
  │  (SCM)   │     │ (pytest/ │     │ (Docker  │     │   Test   │     │(container│
  └──────────┘     │unittest) │     │  build)  │     │ (curl)   │     │  run)    │
                   └──────────┘     └──────────┘     └──────────┘     └──────────┘
                        │                │                │                │
                   FAIL = stop      FAIL = stop      FAIL = stop      FAIL = stop
```

---

## Tools Used in This Lab

| Tool             | Role in this lab                                     |
|------------------|------------------------------------------------------|
| Git              | Source control — tracks every change, enables rollback and collaboration |
| Python unittest  | Automated testing — verifies the application behaves correctly before it is built |
| Docker           | Build and deploy — packages the app and its runtime into a portable image |
| Bash scripts     | Pipeline orchestration — ties every stage together with clear pass/fail semantics |
| Jenkinsfile      | Declarative pipeline definition — describes the same stages in a format Jenkins understands |

---

## Repository Layout

```
lab-14-devops-pipeline/
├── README.md
├── app/
│   ├── server.py        # Minimal Python HTTP server (stdlib only)
│   ├── test_server.py   # Unit tests (stdlib unittest)
│   ├── Dockerfile       # Builds the production container image
│   └── Jenkinsfile      # Declarative Jenkins pipeline definition
└── scripts/
    ├── 01-run-tests.sh          # Stage: Test
    ├── 02-build-docker-image.sh # Stage: Build
    ├── 03-run-pipeline.sh       # Full end-to-end pipeline simulation
    ├── 04-verify.sh             # Post-deploy verification
    └── cleanup.sh               # Tear down containers and images
```

---

## Pipeline Stages

| Stage      | Tool              | What it does                                                  | Failure means                              |
|------------|-------------------|---------------------------------------------------------------|--------------------------------------------|
| Checkout   | Git / SCM         | Fetches the exact commit that triggered the pipeline          | Cannot obtain source — pipeline aborts     |
| Test       | Python unittest   | Runs all unit tests; any assertion failure is a hard error    | Broken code — do not build                 |
| Build      | Docker build      | Produces an immutable, versioned container image              | Image cannot be created — do not deploy    |
| Smoke Test | Docker run + curl | Starts the image in an isolated container and probes /health  | Image runs but app is broken — do not deploy |
| Deploy     | Docker run        | Replaces the live container with the newly built image        | Deployment failed — rollback or investigate |

---

## Running the Lab

### Prerequisites

- Docker installed and the daemon running (`docker info`)
- Python 3.x on PATH (`python3 --version`)
- `curl` available

### Option A — Individual stages

```bash
# Stage: Test
bash scripts/01-run-tests.sh

# Stage: Build Docker Image
bash scripts/02-build-docker-image.sh
```

### Option B — Full pipeline (recommended)

```bash
bash scripts/03-run-pipeline.sh
```

The script runs all five stages with coloured banners and prints a summary table at the end:

```
╔══════════════════════════════════════════════════════════╗
║                  Pipeline Summary                        ║
╠══════════════════════════╦══════════╦════════════════════╣
║ STAGE                    ║ STATUS   ║ TIME               ║
╠══════════════════════════╬══════════╬════════════════════╣
║ Checkout                 ║ PASSED   ║ 0s                 ║
║ Test                     ║ PASSED   ║ 1s                 ║
║ Build                    ║ PASSED   ║ 12s                ║
║ Smoke Test               ║ PASSED   ║ 4s                 ║
║ Deploy                   ║ PASSED   ║ 1s                 ║
╚══════════════════════════╩══════════╩════════════════════╝
```

### Verify the deployment

```bash
bash scripts/04-verify.sh
```

Expected output:

```
--- GET http://localhost:8888/ ---
Hello from DevOps Pipeline!

--- GET http://localhost:8888/health ---
{"status": "ok", "lab": "14"}
```

### Clean up

```bash
bash scripts/cleanup.sh
```

---

## The Jenkinsfile

`app/Jenkinsfile` contains a declarative pipeline that mirrors the shell scripts exactly. Jenkins reads this file from the repository itself — the pipeline definition is versioned alongside the code it builds.

### How to run this in Jenkins

1. Install Jenkins (local, Docker, or cloud). The Docker quick-start:

   ```bash
   docker run -d -p 8080:8080 -p 50000:50000 \
     -v jenkins_home:/var/jenkins_home \
     --name jenkins \
     jenkins/jenkins:lts-jdk17
   ```

2. Open `http://localhost:8080` and complete the initial setup wizard.

3. Install the recommended plugins. Ensure the **Pipeline** and **Docker Pipeline** plugins are active.

4. Create a new **Pipeline** job:
   - Source Code Management: point at the Git repository containing this lab.
   - Build Configuration: select **Pipeline script from SCM**.
   - Script Path: `exercises/lab-14-devops-pipeline/app/Jenkinsfile`

5. Click **Build Now**. Jenkins will:
   - Clone the repository (Checkout stage).
   - Run `python3 -m unittest discover` inside the workspace (Test stage).
   - Execute `docker build` (Build stage).
   - Spin up a short-lived smoke-test container and probe `/health` (Smoke Test stage).
   - Replace the live container (Deploy stage).

6. The `post` block at the bottom of the Jenkinsfile ensures the smoke-test container is always removed, even if an earlier stage fails.

> **Tip:** Set up a webhook in your Git host so Jenkins triggers automatically on every push to the `main` branch. This closes the loop and gives you true Continuous Integration.

---

## How to Extend This Pipeline

| Extension           | Tool / Approach                                         | Where to add it                        |
|---------------------|---------------------------------------------------------|----------------------------------------|
| Linting             | `flake8 app/` or `ruff check app/`                     | New stage between Checkout and Test    |
| Test coverage       | `coverage run -m unittest` + `coverage report`         | Replace the plain `unittest` command   |
| Coverage gate       | `coverage report --fail-under=80`                      | Fail the Test stage if coverage drops  |
| Image registry push | `docker push registry.example.com/lab14-server:TAG`    | New stage after Build                  |
| Multi-arch images   | `docker buildx build --platform linux/amd64,linux/arm64` | Replace the `docker build` command   |
| Vulnerability scan  | `trivy image lab14-server:latest`                       | New stage after Build, before Smoke   |
| Notification        | `curl` to a Slack webhook in the `post { failure {} }` block | Jenkinsfile `post` section        |

---

## Key Concepts Recap

- **Immutable artefact** — the Docker image is built once and the exact same binary is promoted through every environment.
- **Fail fast** — tests run before the build so developers get feedback in seconds, not minutes.
- **Pipeline as code** — the `Jenkinsfile` lives in the same repository as the application; every change to the pipeline is reviewed and audited.
- **Smoke test** — a lightweight end-to-end check that proves the container actually starts and responds before it replaces the live deployment.
- **Idempotent deploy** — `docker stop … || true` and `docker rm … || true` mean the Deploy stage succeeds whether or not a previous version is running.

---

## Next Steps

Lab 15 introduces **Kubernetes** (container orchestration) and **Terraform** (infrastructure as code). The Docker image you built here will be deployed to a Kubernetes cluster instead of a single `docker run` command.
