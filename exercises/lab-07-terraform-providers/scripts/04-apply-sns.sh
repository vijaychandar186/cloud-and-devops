#!/usr/bin/env bash
# Lab 07 — Script 4: Init, plan, and apply SNS topic via Terraform (LocalStack)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SNS_DIR="$SCRIPT_DIR/../terraform/sns-topic"

echo "=========================================="
echo " Lab 07 — Apply SNS Topic (LocalStack)"
echo "=========================================="

cd "$SNS_DIR"

# --- terraform init ---
echo ""
echo "==> Running terraform init..."
echo "    Downloads the AWS provider plugin defined in versions.tf."
echo "------------------------------------------"
terraform init

# --- terraform plan ---
echo ""
echo "==> Running terraform plan..."
echo "    Shows what resources Terraform will create — no changes made yet."
echo "------------------------------------------"
terraform plan

# --- terraform apply ---
echo ""
echo "==> Running terraform apply -auto-approve..."
echo "    Creates the SNS topic in LocalStack."
echo "------------------------------------------"
terraform apply -auto-approve

# --- Show state summary ---
echo ""
echo "==> Resources in state after apply:"
terraform show | grep -E "^#|resource |name|arn" || true

echo ""
echo "==> SNS topic created successfully in LocalStack."
echo "    State saved to: $SNS_DIR/terraform.tfstate"
echo ""
echo "    To destroy: bash scripts/cleanup.sh"
echo "             or: cd terraform/sns-topic && terraform destroy -auto-approve"
