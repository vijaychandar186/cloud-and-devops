#!/usr/bin/env bash
# Lab 07 — Cleanup: Destroy all Terraform-managed resources in LocalStack
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EC2_DIR="$SCRIPT_DIR/../terraform/ec2-instance"
SNS_DIR="$SCRIPT_DIR/../terraform/sns-topic"

echo "=========================================="
echo " Lab 07 — Cleanup (terraform destroy)"
echo "=========================================="

# Helper: destroy a terraform directory only if state exists and has resources
destroy_if_needed() {
  local dir="$1"
  local label="$2"

  echo ""
  echo "==> $label: checking state..."

  if [[ ! -f "$dir/terraform.tfstate" ]]; then
    echo "    No state file found — skipping ($dir)"
    return
  fi

  # Check whether the state file has any managed resources
  local resource_count
  resource_count=$(python3 -c "
import json, sys
try:
    data = json.load(open('$dir/terraform.tfstate'))
    resources = data.get('resources', [])
    print(len(resources))
except Exception:
    print(0)
" 2>/dev/null || echo "0")

  if [[ "$resource_count" -eq 0 ]]; then
    echo "    State file exists but no resources tracked — skipping"
    return
  fi

  echo "    Found $resource_count resource(s) — running terraform destroy..."
  cd "$dir"
  terraform destroy -auto-approve
  echo "    $label destroyed."
  cd - > /dev/null
}

destroy_if_needed "$EC2_DIR" "ec2-instance"
destroy_if_needed "$SNS_DIR" "sns-topic"

echo ""
echo "==> Cleanup complete. All lab-07 resources have been removed from LocalStack."
