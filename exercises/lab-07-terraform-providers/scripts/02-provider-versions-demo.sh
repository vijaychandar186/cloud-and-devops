#!/usr/bin/env bash
# Lab 07 — Script 2: Provider versioning demo
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EC2_VERSIONS_TF="$SCRIPT_DIR/../terraform/ec2-instance/versions.tf"
SNS_VERSIONS_TF="$SCRIPT_DIR/../terraform/sns-topic/versions.tf"

echo "=========================================="
echo " Lab 07 — Provider Version Constraints"
echo "=========================================="

# --- Show the versions.tf files ---
echo ""
echo "==> ec2-instance/versions.tf:"
echo "------------------------------------------"
cat "$EC2_VERSIONS_TF"

echo ""
echo "==> sns-topic/versions.tf:"
echo "------------------------------------------"
cat "$SNS_VERSIONS_TF"

# --- Explain the version constraint operators ---
echo ""
echo "==> Version constraint operators explained:"
echo ""
echo "    ~> (pessimistic constraint / 'compatible with')"
echo "       ~> 5.0   means >= 5.0.0 and < 6.0.0"
echo "       ~> 5.3   means >= 5.3.0 and < 6.0.0"
echo "       ~> 5.3.2 means >= 5.3.2 and < 5.4.0"
echo "       Use this most of the time — allows patch and minor updates"
echo "       within the same major/minor series."
echo ""
echo "    >= (greater than or equal)"
echo "       >= 5.0   means any version 5.0 or newer"
echo "       Useful as a minimum floor, but allows very large jumps."
echo ""
echo "    = (exact pin)"
echo "       = 5.3.1  means exactly version 5.3.1, nothing else"
echo "       Use when you need reproducible builds and no drift."
echo ""
echo "    != (exclusion)"
echo "       != 5.2.0 means any version except 5.2.0"
echo "       Handy to skip a known-broken release."
echo ""
echo "    You can combine constraints:"
echo "       >= 5.0, < 6.0   equivalent to ~> 5.0"
echo "       >= 5.0, != 5.2.0, < 6.0"
echo ""

# --- Show what version is actually installed ---
echo "==> Terraform version currently installed:"
terraform version

echo ""
echo "==> The required_version constraint in versions.tf ensures everyone on"
echo "    the team uses a compatible Terraform CLI, not just a compatible provider."
echo ""
echo "==> Done."
