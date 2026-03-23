#!/usr/bin/env bash
# Lab 06 — Script 5: Verify instance and print SSH connection instructions
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

echo "=========================================="
echo " Lab 06 — Verify & Connect"
echo "=========================================="

# --- Instance ---
echo ""
echo "==> Lab 06 EC2 instance..."
awslocal ec2 describe-instances \
    --filters "Name=tag:Lab,Values=lab06" "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,PublicIpAddress,PrivateIpAddress]' \
    --output table

INSTANCE_ID=$(awslocal ec2 describe-instances \
    --filters "Name=tag:Lab,Values=lab06" "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

PUBLIC_IP=$(awslocal ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>/dev/null || echo "N/A")

# --- Key pair ---
echo ""
echo "==> Key pair..."
awslocal ec2 describe-key-pairs \
    --key-names lab06-keypair \
    --query 'KeyPairs[0].[KeyName,KeyPairId]' \
    --output table

# --- Security group ---
echo ""
echo "==> Security group rules (lab06-ssh-sg)..."
awslocal ec2 describe-security-groups \
    --filters "Name=group-name,Values=lab06-ssh-sg" \
    --query 'SecurityGroups[0].IpPermissions' \
    --output table

# --- User data (best-effort) ---
echo ""
echo "==> User data attached to instance..."
awslocal ec2 describe-instance-attribute \
    --instance-id "$INSTANCE_ID" \
    --attribute userData \
    --query 'UserData.Value' \
    --output text 2>/dev/null | base64 -d 2>/dev/null || echo "  (user data not returned by LocalStack)"

# --- SSH instructions ---
echo ""
echo "=========================================="
echo " SSH Connection Instructions (real AWS)"
echo "=========================================="
echo ""
echo "  Key file : ~/.ssh/lab06-keypair.pem"
echo "  Public IP: $PUBLIC_IP"
echo ""
echo "  Wait ~60s for user-data to finish, then connect:"
echo ""
echo "  ssh -i ~/.ssh/lab06-keypair.pem ubuntu@$PUBLIC_IP"
echo ""
echo "  Once connected, verify shell config was applied:"
echo "  cat ~/.bashrc | grep 'Lab 06'"
echo "  alias ll"
echo "  cat /etc/motd"
echo "  sudo cat /var/log/cloud-init-output.log"
echo ""
echo "  LocalStack: SSH is not available (no real compute)."
echo "  The API calls above are identical to real AWS."
echo "=========================================="
