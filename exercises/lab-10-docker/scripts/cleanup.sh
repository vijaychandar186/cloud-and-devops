#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 10 — Cleanup Script
# =============================================================================
# Stops and removes all containers and images created during this lab.
# Errors from missing resources are handled gracefully.
# =============================================================================

echo "============================================================"
echo " Lab 10 — Docker: Cleanup"
echo "============================================================"
echo ""

CONTAINERS=("lab10-nginx" "lab10-custom")
IMAGES=("lab10-custom:latest")

stopped=0
removed_containers=0
removed_images=0

# ------------------------------------------------------------
# Stop and remove containers
# ------------------------------------------------------------
echo "[1/3] Stopping lab10 containers..."
for name in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${name}$" 2>/dev/null; then
        echo "      Stopping '${name}'..."
        docker stop "${name}" &>/dev/null
        ((stopped++)) || true
    else
        echo "      '${name}' is not running — skipping stop."
    fi
done
echo ""

echo "[2/3] Removing lab10 containers..."
for name in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${name}$" 2>/dev/null; then
        echo "      Removing container '${name}'..."
        docker rm "${name}" &>/dev/null
        ((removed_containers++)) || true
    else
        echo "      Container '${name}' does not exist — skipping remove."
    fi
done
echo ""

# ------------------------------------------------------------
# Remove custom images
# ------------------------------------------------------------
echo "[3/3] Removing lab10 custom images..."
for img in "${IMAGES[@]}"; do
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${img}$" 2>/dev/null; then
        echo "      Removing image '${img}'..."
        docker rmi "${img}" &>/dev/null
        ((removed_images++)) || true
    else
        echo "      Image '${img}' not found — skipping."
    fi
done
echo ""

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo " Cleanup summary:"
echo "   Containers stopped : ${stopped}"
echo "   Containers removed : ${removed_containers}"
echo "   Images removed     : ${removed_images}"
echo ""
echo " The nginx:alpine base image was intentionally kept in the"
echo " local cache (it is reusable for other labs/projects)."
echo " To remove it as well, run:"
echo "   docker rmi nginx:alpine"
echo ""
echo " To remove ALL unused Docker resources in one shot, run:"
echo "   docker system prune -f"
echo "------------------------------------------------------------"
echo " Cleanup complete."
echo "============================================================"
