#!/bin/bash
# Lab 04 — Post-Install Configuration & Verification
# Run this after your first boot into Ubuntu.

set -euo pipefail

echo "=========================================="
echo " Lab 04 — Post-Install Configuration"
echo "=========================================="

# -----------------------------------------------------------
echo ""
echo "==> Step 1: Update package index and upgrade packages..."
sudo apt update -q
sudo apt upgrade -y -q
echo "    Done."

# -----------------------------------------------------------
echo ""
echo "==> Step 2: Set hostname to 'ubuntu-lab'..."
sudo hostnamectl set-hostname ubuntu-lab
echo "    Hostname: $(hostname)"

# -----------------------------------------------------------
echo ""
echo "==> Step 3: Current user info..."
echo "    User:   $(whoami)"
echo "    Home:   $HOME"
echo "    Groups: $(groups)"

# -----------------------------------------------------------
echo ""
echo "==> Step 4: OS information..."
echo "    $(lsb_release -d | cut -f2)"
echo "    Kernel: $(uname -r)"
echo "    Arch:   $(uname -m)"

# -----------------------------------------------------------
echo ""
echo "==> Step 5: Disk and memory summary..."
echo "--- Disk usage ---"
df -h /
echo ""
echo "--- Memory ---"
free -h

# -----------------------------------------------------------
echo ""
echo "==> Step 6: Filesystem layout (top-level directories)..."
ls -1 /

# -----------------------------------------------------------
echo ""
echo "==> Step 7: Install common tools (curl, git, net-tools)..."
sudo apt install -y -q curl git net-tools
echo "    Installed: curl $(curl --version | head -1 | awk '{print $2}')"
echo "    Installed: git $(git --version | awk '{print $3}')"

# -----------------------------------------------------------
echo ""
echo "=========================================="
echo " Post-install configuration complete."
echo " Your Ubuntu environment is ready."
echo "=========================================="
