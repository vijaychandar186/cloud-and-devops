#!/usr/bin/env bash
# Lab 06 — Script 1: Create SSH key pair and security group
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

echo "=========================================="
echo " Lab 06 — SSH Key Pair & Security Group"
echo "=========================================="

# --- Key pair ---
echo ""
echo "==> Creating key pair: lab06-keypair..."
mkdir -p ~/.ssh
awslocal ec2 create-key-pair \
    --key-name lab06-keypair \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/lab06-keypair.pem
chmod 400 ~/.ssh/lab06-keypair.pem
echo "    Private key saved: ~/.ssh/lab06-keypair.pem (permissions: 400)"

# --- VPC ---
echo ""
echo "==> Resolving VPC..."
VPC_ID=$(awslocal ec2 describe-vpcs \
    --query 'Vpcs[0].VpcId' \
    --output text)
echo "    VPC: $VPC_ID"

# --- Security group ---
echo ""
echo "==> Creating security group: lab06-ssh-sg..."
SG_ID=$(awslocal ec2 create-security-group \
    --group-name lab06-ssh-sg \
    --description "Lab 06 - SSH access only" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)
echo "    Security Group: $SG_ID"

echo "==> Adding inbound rule: TCP 22 (SSH)..."
awslocal ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --query 'SecurityGroupRules[0].SecurityGroupRuleId' \
    --output text

echo ""
echo "==> Resources created:"
echo "    Key pair : lab06-keypair (~/.ssh/lab06-keypair.pem)"
echo "    Sec group: $SG_ID (SSH port 22 open)"
echo ""
echo "    REAL AWS NOTE: Restrict port 22 to your own IP:"
echo "    --cidr \$(curl -s https://checkip.amazonaws.com)/32"
