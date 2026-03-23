#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo " Lab 09 - Step 2: Run the Role-based Playbook"
echo "=============================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${SCRIPT_DIR}/.."

# ---------------------------------------------------------------------------
# Confirm site.yml and the role exist
# ---------------------------------------------------------------------------
if [[ ! -f "${LAB_DIR}/site.yml" ]]; then
  echo "ERROR: site.yml not found at ${LAB_DIR}/site.yml"
  exit 1
fi

if [[ ! -d "${LAB_DIR}/roles/webserver" ]]; then
  echo "ERROR: roles/webserver directory not found under ${LAB_DIR}"
  exit 1
fi

echo "Playbook : ${LAB_DIR}/site.yml"
echo "Role     : ${LAB_DIR}/roles/webserver"
echo ""

# ---------------------------------------------------------------------------
# Show site.yml before running
# ---------------------------------------------------------------------------
echo "--- site.yml Contents ---"
cat "${LAB_DIR}/site.yml"
echo ""

# ---------------------------------------------------------------------------
# Run the role playbook in check (dry-run) mode
# --check  : simulate all changes without applying them
# --diff   : show what would change inside templated files
# ---------------------------------------------------------------------------
echo "--- Running: ansible-playbook site.yml --check --diff ---"
echo ""
echo "NOTE: Running in DRY-RUN mode (--check)."
echo "      No changes will be made to this system."
echo "      This is safe to run inside a devcontainer or any environment."
echo ""

cd "${LAB_DIR}"
ansible-playbook site.yml --check --diff --connection=local

echo ""
echo "=============================================="
echo " Dry-run complete."
echo ""
echo " To ACTUALLY install Apache and deploy index.html"
echo " on a real Ubuntu host or EC2 instance, run:"
echo ""
echo "   cd ${LAB_DIR}"
echo "   sudo ansible-playbook site.yml"
echo ""
echo " Override the page title without editing any file:"
echo ""
echo "   sudo ansible-playbook site.yml -e \"page_title='My EC2 Server'\""
echo "=============================================="
