#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo " Lab 08 - Step 1: Verify Ansible Installation"
echo "=============================================="
echo ""

# ---------------------------------------------------------------------------
# 1. Confirm Ansible is installed and show version details
# ---------------------------------------------------------------------------
echo "--- Ansible Version ---"
if ! command -v ansible &>/dev/null; then
  echo "ERROR: ansible is not found in PATH."
  echo ""
  echo "Install Ansible:"
  echo "  Ubuntu/Debian : sudo apt update && sudo apt install -y ansible"
  echo "  macOS (Homebrew): brew install ansible"
  echo "  pip (any OS)  : pip3 install ansible"
  exit 1
fi

ansible --version
echo ""

# ---------------------------------------------------------------------------
# 2. Show default ansible.cfg search order and key settings
# ---------------------------------------------------------------------------
echo "--- ansible.cfg Defaults / Active Configuration ---"
echo "Ansible reads its configuration from the first file found in this order:"
echo "  1. ANSIBLE_CONFIG environment variable"
echo "  2. ./ansible.cfg          (current directory)"
echo "  3. ~/.ansible.cfg         (home directory)"
echo "  4. /etc/ansible/ansible.cfg (global fallback)"
echo ""
echo "Active config file in use:"
ansible-config dump --only-changed 2>/dev/null || echo "  (no overrides — all defaults are active)"
echo ""

# ---------------------------------------------------------------------------
# 3. Explain inventory concepts
# ---------------------------------------------------------------------------
echo "--- Inventory Concepts ---"
echo "An inventory tells Ansible which hosts to manage."
echo ""
echo "Default inventory file : /etc/ansible/hosts"
echo "You can specify a custom inventory with:  ansible -i inventory.ini ..."
echo ""
echo "Example static inventory (INI format):"
cat <<'INVENTORY'
[webservers]
web1.example.com
web2.example.com ansible_user=ubuntu

[dbservers]
db1.example.com ansible_port=2222

[all:vars]
ansible_python_interpreter=/usr/bin/python3
INVENTORY
echo ""
echo "For this lab we target 'localhost' directly (connection: local),"
echo "so no external inventory file is required."
echo ""

# ---------------------------------------------------------------------------
# 4. Run an ad-hoc ping against localhost to confirm everything works
# ---------------------------------------------------------------------------
echo "--- Ad-hoc Command: ansible localhost -m ping ---"
echo "The 'ping' module checks that Ansible can connect to the target."
echo ""
ansible localhost -m ping --connection=local
echo ""

echo "Verification complete. Ansible is ready to use."
echo ""
echo "Next: run ./02-run-playbook.sh to execute the Apache playbook (dry-run)."
