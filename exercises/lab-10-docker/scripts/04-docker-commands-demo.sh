#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 10 — Script 04: Docker Commands Demo
# =============================================================================
# Demonstrates docker ps, inspect, logs, stats, and images, then prints a
# reference table of the most common Docker commands.
# =============================================================================

echo "============================================================"
echo " Lab 10 — Docker: Commands Demo"
echo "============================================================"
echo ""
echo "NOTE: This script expects lab10-nginx and lab10-custom to be"
echo "      running. Run scripts 02 and 03 first if needed."
echo ""

# ------------------------------------------------------------
# 1. docker ps — running containers
# ------------------------------------------------------------
echo "[1/6] docker ps — all running lab10 containers:"
echo "------------------------------------------------------------"
docker ps --filter "name=lab10"
echo ""

# ------------------------------------------------------------
# 2. docker inspect — network settings
# ------------------------------------------------------------
echo "[2/6] docker inspect lab10-nginx — port mappings:"
echo "------------------------------------------------------------"
if docker ps --format '{{.Names}}' | grep -q "^lab10-nginx$"; then
    docker inspect lab10-nginx --format '{{.NetworkSettings.Ports}}'
else
    echo "      (container lab10-nginx is not running — skipping inspect)"
fi
echo ""

# ------------------------------------------------------------
# 3. docker logs — last 5 lines
# ------------------------------------------------------------
echo "[3/6] docker logs lab10-nginx --tail 5:"
echo "------------------------------------------------------------"
if docker ps --format '{{.Names}}' | grep -q "^lab10-nginx$"; then
    docker logs lab10-nginx --tail 5 2>&1 || echo "      (no log output yet — try curling the container first)"
else
    echo "      (container lab10-nginx is not running — skipping logs)"
fi
echo ""

# ------------------------------------------------------------
# 4. docker stats — resource usage (non-streaming snapshot)
# ------------------------------------------------------------
echo "[4/6] docker stats --no-stream — resource usage:"
echo "------------------------------------------------------------"
docker stats --no-stream \
    --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

# ------------------------------------------------------------
# 5. docker images — all local images
# ------------------------------------------------------------
echo "[5/6] docker images — all locally cached images:"
echo "------------------------------------------------------------"
docker images
echo ""

# ------------------------------------------------------------
# 6. Reference table
# ------------------------------------------------------------
echo "[6/6] Common Docker command reference:"
echo "============================================================"
printf "  %-40s %s\n" "COMMAND" "DESCRIPTION"
echo "  --------------------------------------------------------"
printf "  %-40s %s\n" "docker pull <image>:<tag>"       "Download an image from a registry"
printf "  %-40s %s\n" "docker images"                   "List locally cached images"
printf "  %-40s %s\n" "docker rmi <image>"              "Remove a local image"
printf "  %-40s %s\n" "docker build -t <name>:<tag> ."  "Build an image from a Dockerfile"
printf "  %-40s %s\n" "docker push <image>:<tag>"       "Push an image to a registry"
printf "  %-40s %s\n" "docker run -d -p <h>:<c> <img>"  "Run container detached, map port"
printf "  %-40s %s\n" "docker ps"                       "List running containers"
printf "  %-40s %s\n" "docker ps -a"                    "List all containers (incl. stopped)"
printf "  %-40s %s\n" "docker stop <name|id>"           "Gracefully stop a container"
printf "  %-40s %s\n" "docker rm <name|id>"             "Remove a stopped container"
printf "  %-40s %s\n" "docker logs <name|id>"           "Print container stdout/stderr"
printf "  %-40s %s\n" "docker exec -it <name> sh"       "Open an interactive shell"
printf "  %-40s %s\n" "docker inspect <name|id>"        "Show full container/image metadata"
printf "  %-40s %s\n" "docker stats --no-stream"        "Show live resource usage snapshot"
printf "  %-40s %s\n" "docker system prune"             "Remove unused containers/images/nets"
echo "============================================================"
echo ""
echo " Demo complete. Run cleanup.sh to remove all lab10 resources."
echo "============================================================"
