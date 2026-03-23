#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 13 — Cleanup Script
# Removes Jenkins container, volume, and all build artifacts
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../sample-project"

CONTAINER_NAME="lab13-jenkins"
JENKINS_VOLUME="jenkins_home"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
print_header() {
    echo ""
    echo "============================================================"
    echo "  $1"
    echo "============================================================"
}

print_step() {
    echo ""
    echo "--- $1 ---"
}

print_header "Lab 13 Cleanup"

# ------------------------------------------------------------------------------
# Jenkins container
# ------------------------------------------------------------------------------
print_step "Stopping Jenkins container: $CONTAINER_NAME"
docker stop "$CONTAINER_NAME" 2>/dev/null && echo "  Stopped: $CONTAINER_NAME" || echo "  Container not running (skipped)"

print_step "Removing Jenkins container: $CONTAINER_NAME"
docker rm "$CONTAINER_NAME" 2>/dev/null && echo "  Removed: $CONTAINER_NAME" || echo "  Container does not exist (skipped)"

# ------------------------------------------------------------------------------
# Jenkins Docker volume
# ------------------------------------------------------------------------------
print_step "Removing Jenkins volume: $JENKINS_VOLUME"
docker volume rm "$JENKINS_VOLUME" 2>/dev/null && echo "  Removed volume: $JENKINS_VOLUME" || echo "  Volume does not exist (skipped)"

# ------------------------------------------------------------------------------
# Gradle build directory
# ------------------------------------------------------------------------------
print_step "Cleaning Gradle build artifacts"
if [ -d "$PROJECT_DIR/build" ]; then
    rm -rf "$PROJECT_DIR/build"
    echo "  Removed: $PROJECT_DIR/build"
else
    echo "  No Gradle build directory found (skipped)"
fi

# ------------------------------------------------------------------------------
# Maven target directory
# ------------------------------------------------------------------------------
print_step "Cleaning Maven target artifacts"
if [ -d "$PROJECT_DIR/target" ]; then
    rm -rf "$PROJECT_DIR/target"
    echo "  Removed: $PROJECT_DIR/target"
else
    echo "  No Maven target directory found (skipped)"
fi

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
print_header "Cleanup Summary"

echo ""
echo "  Cleaned resources:"
printf "  %-30s  %s\n" "Docker container"  "$CONTAINER_NAME"
printf "  %-30s  %s\n" "Docker volume"     "$JENKINS_VOLUME"
printf "  %-30s  %s\n" "Gradle artifacts"  "$PROJECT_DIR/build"
printf "  %-30s  %s\n" "Maven artifacts"   "$PROJECT_DIR/target"
echo ""
echo "  Source files and scripts are untouched."
echo ""
echo "To re-run the lab, start from scripts/01-install-tools.sh."
echo ""
