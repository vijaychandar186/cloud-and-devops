# Lab 10 — Installing Docker with Configuration

**Topic:** Install Docker engine and run containers
**Difficulty:** Beginner
**Estimated time:** 30–45 minutes

---

## Objectives

By the end of this lab you will be able to:

1. Verify that the Docker engine is installed and running.
2. Pull an image from Docker Hub and run it as a container.
3. Build a custom image from a `Dockerfile`.
4. Use core Docker CLI commands: `run`, `ps`, `stop`, `rm`, `logs`, `inspect`, `stats`.
5. Clean up containers and images when finished.

---

## Background

### Docker vs Virtual Machines

| | Virtual Machine | Docker Container |
|---|---|---|
| Isolation | Full OS per VM | Shared host kernel |
| Size | Gigabytes | Megabytes |
| Boot time | Minutes | Milliseconds |
| Portability | Hypervisor-specific | Runs anywhere Docker runs |
| Use case | Full OS isolation | Application packaging |

VMs virtualise the **hardware**; Docker virtualises the **operating system**.
Containers share the host kernel but are isolated via Linux namespaces and cgroups.

### Images vs Containers

- **Image** — a read-only, layered snapshot of a filesystem. Think of it as a _class_ or a _recipe_. Images are built from a `Dockerfile` and stored in a registry.
- **Container** — a running instance of an image. Think of it as an _object_ created from that class. You can start many containers from the same image.

### Dockerfile

A plain-text file that describes how to build an image step by step:

```dockerfile
FROM nginx:alpine          # start from the official nginx base image
COPY html/index.html /usr/share/nginx/html/index.html  # add our file
```

Each instruction creates a new read-only **layer**. Docker caches layers, so unchanged layers are reused on rebuilds — making subsequent builds fast.

### Registry

A server that stores and serves Docker images. The default public registry is **Docker Hub** (`hub.docker.com`). Popular alternatives include:

- AWS Elastic Container Registry (ECR)
- GitHub Container Registry (ghcr.io)
- Google Artifact Registry

### Docker Daemon

`dockerd` is the background service that builds images, manages containers, handles networking, and manages volumes. The `docker` CLI communicates with the daemon over a Unix socket (`/var/run/docker.sock`) or a TCP socket.

---

## Docker Architecture

```
 ┌──────────────────────────────────────────────────────────┐
 │                      Developer Machine                   │
 │                                                          │
 │   docker CLI  ──── REST API ────►  dockerd (daemon)      │
 │                                        │                 │
 │                                        ▼                 │
 │                              ┌─────────────────┐         │
 │                              │  Container Runtm │         │
 │                              │  (containerd)   │         │
 │                              └────────┬────────┘         │
 │                                       │                  │
 │              ┌────────────────────────┼──────────────┐   │
 │              ▼                        ▼              ▼   │
 │       ┌────────────┐          ┌────────────┐  ┌────────┐ │
 │       │ Container A │          │ Container B │  │  ...   │ │
 │       │ (nginx)     │          │ (custom)    │  │        │ │
 │       └────────────┘          └────────────┘  └────────┘ │
 │                                                          │
 └──────────────────────────────────────────────────────────┘
              │
              │  docker pull / docker push
              ▼
 ┌─────────────────────────┐
 │       Registry          │
 │  (Docker Hub / ECR /    │
 │   ghcr.io / ...)        │
 │                         │
 │  nginx:alpine           │
 │  ubuntu:22.04           │
 │  lab10-custom:latest    │
 └─────────────────────────┘
```

---

## Common Docker Commands

| Command | Description |
|---|---|
| `docker pull <image>:<tag>` | Download an image from a registry |
| `docker images` | List locally cached images |
| `docker rmi <image>` | Remove a local image |
| `docker build -t <name>:<tag> .` | Build an image from a Dockerfile |
| `docker push <image>:<tag>` | Push an image to a registry |
| `docker run -d -p <host>:<ctr> <img>` | Run a container detached, map a port |
| `docker ps` | List running containers |
| `docker ps -a` | List all containers (including stopped) |
| `docker stop <name\|id>` | Gracefully stop a container (SIGTERM) |
| `docker rm <name\|id>` | Remove a stopped container |
| `docker logs <name\|id>` | Print container stdout/stderr |
| `docker exec -it <name> sh` | Open an interactive shell in a container |
| `docker inspect <name\|id>` | Show full container/image metadata (JSON) |
| `docker stats --no-stream` | Snapshot of live resource usage |
| `docker system prune` | Remove all unused containers, images, networks |

---

## Lab Scripts

Run the scripts in order. Each script is self-contained and idempotent (safe to re-run).

### `scripts/01-verify-docker.sh`

Confirms Docker is installed and the daemon is running. Prints version information and explains core concepts: images, containers, daemon, registry, Dockerfile.

```bash
bash scripts/01-verify-docker.sh
```

### `scripts/02-pull-run-nginx.sh`

- Pulls `nginx:alpine` from Docker Hub.
- Starts a container named `lab10-nginx` on **port 8080**.
- Verifies it responds with `curl`.

```bash
bash scripts/02-pull-run-nginx.sh
# Then visit: http://localhost:8080
```

### `scripts/03-build-custom-image.sh`

- Builds the `lab10-custom:latest` image from the `Dockerfile` in this directory.
- Runs it on **port 8081** serving the custom `html/index.html`.
- Explains the difference between pulling and building.

```bash
bash scripts/03-build-custom-image.sh
# Then visit: http://localhost:8081
```

### `scripts/04-docker-commands-demo.sh`

Demonstrates `docker ps`, `docker inspect`, `docker logs`, `docker stats`, and `docker images`. Ends with a printed reference table of common commands.

```bash
bash scripts/04-docker-commands-demo.sh
```

### `scripts/cleanup.sh`

Stops and removes all containers and images created by this lab. Missing resources are handled gracefully.

```bash
bash scripts/cleanup.sh
```

---

## File Structure

```
lab-10-docker/
├── README.md                       ← this file
├── Dockerfile                      ← custom nginx image definition
├── html/
│   └── index.html                  ← page served by the custom image
└── scripts/
    ├── 01-verify-docker.sh         ← verify installation + concepts
    ├── 02-pull-run-nginx.sh        ← pull nginx:alpine and run it
    ├── 03-build-custom-image.sh    ← build and run a custom image
    ├── 04-docker-commands-demo.sh  ← ps, inspect, logs, stats reference
    └── cleanup.sh                  ← stop/remove all lab resources
```

---

## Installing Docker

> **Devcontainer users:** Docker is already available inside this devcontainer via Docker-in-Docker. Skip straight to [Lab Scripts](#lab-scripts).

### macOS

Install [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/). It bundles the daemon, CLI, and a GUI.

```bash
# Or with Homebrew:
brew install --cask docker
```

### Ubuntu / Debian

```bash
# Remove old versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key and repository
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group (avoids needing sudo)
sudo usermod -aG docker "$USER"
newgrp docker
```

### Windows

Install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/). Requires WSL 2 backend (recommended) or Hyper-V.

---

## Key Takeaways

- Docker packages applications and their dependencies into portable **images**.
- A running image is a **container** — isolated, ephemeral, and lightweight.
- `docker run -d -p <host>:<container>` starts a container in the background and maps a host port.
- `docker ps`, `docker logs`, and `docker inspect` are your main observability tools.
- Always clean up with `docker stop` + `docker rm` (or `docker system prune`) to avoid resource leaks.
