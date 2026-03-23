#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo " Lab 08 - Step 2: Run the Ansible Playbook"
echo "=============================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_DIR="${SCRIPT_DIR}/../playbook"

# ---------------------------------------------------------------------------
# Confirm playbook exists
# ---------------------------------------------------------------------------
if [[ ! -f "${PLAYBOOK_DIR}/playbook.yml" ]]; then
  echo "ERROR: playbook.yml not found at ${PLAYBOOK_DIR}/playbook.yml"
  exit 1
fi

echo "Playbook  : ${PLAYBOOK_DIR}/playbook.yml"
echo "Template  : ${PLAYBOOK_DIR}/templates/index.html.j2"
echo ""

# ---------------------------------------------------------------------------
# Show playbook contents before running
# ---------------------------------------------------------------------------
echo "--- Playbook Contents ---"
cat "${PLAYBOOK_DIR}/playbook.yml"
echo ""

# ---------------------------------------------------------------------------
# Run the playbook in check (dry-run) mode
# --check  : simulate all changes without applying them
# --diff   : show what would change in files managed by the template module
# ---------------------------------------------------------------------------
echo "--- Running: ansible-playbook playbook.yml --check --diff ---"
echo ""
echo "NOTE: Running in DRY-RUN mode (--check)."
echo "      No changes will be made to this system."
echo "      This is safe to run inside a devcontainer or any environment."
echo ""

cd "${PLAYBOOK_DIR}"
ansible-playbook playbook.yml --check --diff --connection=local

echo ""
echo "=============================================="
echo " Dry-run complete."
echo ""
echo " To ACTUALLY install Apache and deploy index.html"
echo " on a real Ubuntu host or EC2 instance, run:"
echo ""
echo "   cd ${PLAYBOOK_DIR}"
echo "   sudo ansible-playbook playbook.yml"
echo ""
echo " (drop --check, add sudo or ensure become works)"
echo "=============================================="
