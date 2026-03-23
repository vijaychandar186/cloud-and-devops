#!/usr/bin/env bash
# Lab 07 — Script 3: Init, plan, and apply EC2 instance via Terraform (LocalStack)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EC2_DIR="$SCRIPT_DIR/../terraform/ec2-instance"

echo "=========================================="
echo " Lab 07 — Apply EC2 Instance (LocalStack)"
echo "=========================================="

cd "$EC2_DIR"

# --- terraform init ---
echo ""
echo "==> Running terraform init..."
echo "    This downloads the AWS provider plugin defined in versions.tf."
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
echo "    Creates the EC2 instance in LocalStack."
echo "------------------------------------------"
terraform apply -auto-approve

# --- Show outputs / state summary ---
echo ""
echo "==> Resources in state after apply:"
terraform show | grep -E "^#|resource |instance_type|ami|tags" || true

echo ""
echo "==> EC2 instance created successfully in LocalStack."
echo "    State saved to: $EC2_DIR/terraform.tfstate"
echo ""
echo "    To destroy: bash scripts/cleanup.sh"
echo "             or: cd terraform/ec2-instance && terraform destroy -auto-approve"
