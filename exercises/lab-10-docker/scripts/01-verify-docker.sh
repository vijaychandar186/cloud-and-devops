#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 10 — Script 01: Verify Docker Installation
# =============================================================================
# Confirms Docker is installed and running, then explains core concepts.
# =============================================================================

echo "============================================================"
echo " Lab 10 — Docker: Verify Installation"
echo "============================================================"
echo ""

# ------------------------------------------------------------
# 1. Check that the docker binary exists
# ------------------------------------------------------------
echo "[1/4] Checking for Docker binary..."
if ! command -v docker &>/dev/null; then
    echo "ERROR: 'docker' command not found. Please install Docker and retry."
    exit 1
fi
echo "      docker found at: $(command -v docker)"
echo ""

# ------------------------------------------------------------
# 2. Print Docker client/server versions
# ------------------------------------------------------------
echo "[2/4] Docker version information:"
echo "------------------------------------------------------------"
docker version
echo ""

# ------------------------------------------------------------
# 3. Print selected docker info fields
# ------------------------------------------------------------
echo "[3/4] Docker daemon info (key fields):"
echo "------------------------------------------------------------"
docker info 2>/dev/null | grep -E "Server Version|Storage Driver|Operating System|Total Memory|Docker Root Dir" || true
echo ""

# ------------------------------------------------------------
# 4. Core Docker concepts
# ------------------------------------------------------------
echo "[4/4] Core Docker concepts:"
echo "------------------------------------------------------------"
echo ""
echo "  IMAGE"
echo "    A read-only, layered filesystem snapshot that contains everything"
echo "    needed to run an application (OS libs, runtime, code, config)."
echo "    Images are built from a Dockerfile and stored in a registry."
echo "    Think of an image as a class definition or a recipe."
echo ""
echo "  CONTAINER"
echo "    A running instance of an image — isolated via Linux namespaces"
echo "    and cgroups. Many containers can be started from the same image."
echo "    Think of a container as an object created from a class."
echo ""
echo "  DOCKER DAEMON (dockerd)"
echo "    The background service that builds images, runs containers, and"
echo "    manages networking and storage. The 'docker' CLI talks to the"
echo "    daemon via a Unix socket (/var/run/docker.sock)."
echo ""
echo "  REGISTRY"
echo "    A server that stores and distributes images. Docker Hub"
echo "    (hub.docker.com) is the default public registry. You can also"
echo "    run private registries (e.g. AWS ECR, GitHub Container Registry)."
echo ""
echo "  DOCKERFILE"
echo "    A plain-text recipe that describes how to build an image:"
echo "    base image, files to copy, commands to run, ports to expose, etc."
echo ""
echo "============================================================"
echo " Docker is installed and ready. Proceed to script 02."
echo "============================================================"
