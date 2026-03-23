#!/usr/bin/env bash
# Lab 06 — Cleanup: remove all resources created in this lab
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

echo "==> Cleaning up Lab 06 resources..."

# Terminate instances
INSTANCE_IDS=$(awslocal ec2 describe-instances \
    --filters "Name=tag:Lab,Values=lab06" "Name=instance-state-name,Values=running,pending,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text 2>/dev/null || true)

if [ -n "$INSTANCE_IDS" ] && [ "$INSTANCE_IDS" != "None" ]; then
    for ID in $INSTANCE_IDS; do
        echo "    Terminating instance: $ID"
        awslocal ec2 terminate-instances --instance-ids "$ID" --output text > /dev/null
    done
fi

# Delete key pair
if awslocal ec2 describe-key-pairs --key-names lab06-keypair --output text > /dev/null 2>&1; then
    echo "    Deleting key pair: lab06-keypair"
    awslocal ec2 delete-key-pair --key-name lab06-keypair
    rm -f ~/.ssh/lab06-keypair.pem
fi

# Delete security group
SG_ID=$(awslocal ec2 describe-security-groups \
    --filters "Name=group-name,Values=lab06-ssh-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null || true)

if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    echo "    Deleting security group: $SG_ID"
    awslocal ec2 delete-security-group --group-id "$SG_ID" 2>/dev/null || true
fi

echo ""
echo "==> Lab 06 cleanup complete."
