#!/usr/bin/env bash
# Lab 07 — Script 1: Verify Terraform installation
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo " Lab 07 — Verify Terraform Installation"
echo "=========================================="

# --- Check terraform binary exists ---
echo ""
echo "==> Checking that terraform is installed..."
if ! command -v terraform &>/dev/null; then
  echo "    ERROR: terraform not found in PATH."
  echo "    Install it from: https://developer.hashicorp.com/terraform/install"
  exit 1
fi
echo "    terraform found at: $(command -v terraform)"

# --- Show installed version ---
echo ""
echo "==> Terraform version:"
terraform version

# --- Show help summary ---
echo ""
echo "==> Terraform help summary (main commands):"
echo "------------------------------------------"
terraform --help | head -40

# --- Explain what Terraform does ---
echo ""
echo "==> What is Terraform?"
echo ""
echo "    Terraform is an Infrastructure as Code (IaC) tool made by HashiCorp."
echo "    You describe the desired state of your infrastructure in HCL"
echo "    (HashiCorp Configuration Language) files, and Terraform figures out"
echo "    what API calls to make to reach that state."
echo ""
echo "    Key concepts:"
echo "      providers   — plugins that talk to cloud APIs (AWS, GCP, Azure, ...)"
echo "      resources   — the actual infrastructure objects (EC2, S3, SNS, ...)"
echo "      state       — terraform.tfstate records what has been created"
echo "      plan        — a preview of changes before applying them"
echo ""
echo "    Core workflow:"
echo "      terraform init     Download provider plugins"
echo "      terraform plan     Show what will change"
echo "      terraform apply    Create / update resources"
echo "      terraform destroy  Tear everything down"
echo ""
echo "==> Done. Terraform is ready to use."
