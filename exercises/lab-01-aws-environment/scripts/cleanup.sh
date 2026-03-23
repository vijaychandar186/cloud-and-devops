#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab01-state"
[[ -f "$STATE_FILE" ]] && source "$STATE_FILE" || true

echo "==> Cleaning up Lab 01 resources..."

# Terminate EC2 instance first (depends on subnet/sg)
if [[ -n "${INSTANCE_ID:-}" ]]; then
  echo "    Terminating instance: $INSTANCE_ID"
  awslocal ec2 terminate-instances --instance-ids "$INSTANCE_ID" > /dev/null
fi

# Delete S3 bucket (must empty it first)
if [[ -n "${BUCKET_NAME:-}" ]]; then
  echo "    Emptying and deleting bucket: $BUCKET_NAME"
  awslocal s3 rm "s3://$BUCKET_NAME" --recursive 2>/dev/null || true
  awslocal s3 rb "s3://$BUCKET_NAME" 2>/dev/null || true
fi

# Delete key pair
if [[ -n "${KEY_NAME:-}" ]]; then
  echo "    Deleting key pair: $KEY_NAME"
  awslocal ec2 delete-key-pair --key-name "$KEY_NAME" 2>/dev/null || true
  rm -f "${KEY_FILE:-$HOME/.ssh/lab01-keypair.pem}"
fi

# Delete security group (after instance is gone)
if [[ -n "${SG_ID:-}" ]]; then
  echo "    Deleting security group: $SG_ID"
  awslocal ec2 delete-security-group --group-id "$SG_ID" 2>/dev/null || true
fi

# Detach and delete internet gateway
if [[ -n "${IGW_ID:-}" && -n "${VPC_ID:-}" ]]; then
  echo "    Detaching and deleting internet gateway: $IGW_ID"
  awslocal ec2 detach-internet-gateway \
    --internet-gateway-id "$IGW_ID" \
    --vpc-id "$VPC_ID" 2>/dev/null || true
  awslocal ec2 delete-internet-gateway \
    --internet-gateway-id "$IGW_ID" 2>/dev/null || true
fi

# Delete subnet
if [[ -n "${SUBNET_ID:-}" ]]; then
  echo "    Deleting subnet: $SUBNET_ID"
  awslocal ec2 delete-subnet --subnet-id "$SUBNET_ID" 2>/dev/null || true
fi

# Delete VPC (last — everything else must be removed first)
if [[ -n "${VPC_ID:-}" ]]; then
  echo "    Deleting VPC: $VPC_ID"
  awslocal ec2 delete-vpc --vpc-id "$VPC_ID" 2>/dev/null || true
fi

# Remove state file
rm -f "$STATE_FILE"

echo ""
echo "==> Lab 01 cleanup complete."
