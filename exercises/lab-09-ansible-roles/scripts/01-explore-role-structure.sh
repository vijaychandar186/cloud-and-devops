#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo " Lab 09 - Step 1: Explore the Role Structure"
echo "=============================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${SCRIPT_DIR}/.."

# ---------------------------------------------------------------------------
# 1. Print the full directory tree of the webserver role
# ---------------------------------------------------------------------------
echo "--- Role Directory Tree ---"
find "${LAB_DIR}/roles/webserver" -not -path '*/\.*' | sort | \
  awk -v base="${LAB_DIR}/" '{
    path = $0
    sub(base, "", path)
    n = split(path, parts, "/")
    indent = ""
    for (i = 1; i < n; i++) indent = indent "    "
    print indent parts[n]
  }'
echo ""

# ---------------------------------------------------------------------------
# 2. Explain each subdirectory's purpose
# ---------------------------------------------------------------------------
echo "--- Role Directory Purposes ---"
cat <<'EXPLANATION'
roles/webserver/
  tasks/        The main list of tasks to execute. Ansible always looks for
                tasks/main.yml as the entry point for a role's task list.

  handlers/     Handlers are special tasks triggered by 'notify' directives.
                They run at the end of a play, only if notified and only once
                regardless of how many tasks notified them.

  templates/    Jinja2 template files (.j2). The 'template' module renders
                these with variable substitution before deploying to the host.

  defaults/     Default variable values for the role. Lowest precedence —
                any other variable source (vars/, inventory, extra-vars) wins.

  vars/         Higher-precedence role variables. Use for values that should
                not normally be overridden by operators.

  files/        Static files deployed with the 'copy' module (no templating).

  meta/         Role metadata: author, supported platforms, dependencies.
                Used by Ansible Galaxy for publishing and dependency resolution.
EXPLANATION
echo ""

# ---------------------------------------------------------------------------
# 3. Print all role file contents with headers
# ---------------------------------------------------------------------------
print_file() {
  local filepath="$1"
  local relpath="${filepath#${LAB_DIR}/}"
  echo "=============================="
  echo " FILE: ${relpath}"
  echo "=============================="
  cat "${filepath}"
  echo ""
}

echo "--- Role File Contents ---"
echo ""

print_file "${LAB_DIR}/roles/webserver/tasks/main.yml"
print_file "${LAB_DIR}/roles/webserver/handlers/main.yml"
print_file "${LAB_DIR}/roles/webserver/templates/index.html.j2"
print_file "${LAB_DIR}/roles/webserver/defaults/main.yml"
print_file "${LAB_DIR}/roles/webserver/meta/main.yml"
print_file "${LAB_DIR}/site.yml"

# ---------------------------------------------------------------------------
# 4. Explain the Jinja2 variable in the template
# ---------------------------------------------------------------------------
echo "--- Jinja2 Variable Substitution ---"
echo "The template uses:  {{ page_title }}"
echo ""
echo "At render time Ansible replaces {{ page_title }} with the value from"
echo "defaults/main.yml:  page_title: \"Hello from Ansible Role!\""
echo ""
echo "To override it without editing any file, pass an extra variable:"
echo "  ansible-playbook site.yml --check -e \"page_title='My Custom Title'\""
echo ""

echo "Exploration complete."
echo ""
echo "Next: run ./02-run-role-playbook.sh to execute the role playbook (dry-run)."
