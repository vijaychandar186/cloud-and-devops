#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo " Lab 09 - Cleanup"
echo "=============================================="
echo ""

# ---------------------------------------------------------------------------
# Remove Apache2 if it was installed by the role playbook
# ---------------------------------------------------------------------------
echo "--- Removing apache2 (if installed) ---"
if dpkg -l apache2 &>/dev/null 2>&1; then
  sudo apt remove -y apache2 2>/dev/null || true
  sudo apt autoremove -y 2>/dev/null || true
  echo "apache2 removed."
else
  echo "apache2 is not installed — nothing to remove."
fi
echo ""

# ---------------------------------------------------------------------------
# Remove the deployed index.html if it exists
# ---------------------------------------------------------------------------
INDEX_FILE="/var/www/html/index.html"
echo "--- Removing ${INDEX_FILE} (if it exists) ---"
if [[ -f "${INDEX_FILE}" ]]; then
  sudo rm -f "${INDEX_FILE}"
  echo "${INDEX_FILE} removed."
else
  echo "${INDEX_FILE} does not exist — nothing to remove."
fi
echo ""

echo "Cleanup complete."
