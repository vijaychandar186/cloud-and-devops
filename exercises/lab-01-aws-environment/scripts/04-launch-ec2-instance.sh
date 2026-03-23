#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab01-state"
[[ -f "$STATE_FILE" ]] || { echo "ERROR: Run 01-create-vpc.sh and 03-create-ec2-keypair.sh first."; exit 1; }
source "$STATE_FILE"

# Amazon Linux 2 AMI ID (us-east-1) — LocalStack accepts any AMI ID
AMI_ID="ami-0c02fb55956c7d316"

echo "==> Creating Security Group..."
SG_ID=$(awslocal ec2 create-security-group \
  --group-name lab01-sg \
  --description "Lab 01 security group" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' --output text)
echo "    Security Group: $SG_ID"

echo "==> Adding inbound rules (SSH port 22, HTTP port 80)..."
awslocal ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

awslocal ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

echo "==> Launching EC2 instance (t2.micro, Amazon Linux 2)..."
INSTANCE_ID=$(awslocal ec2 run-instances \
  --image-id "$AMI_ID" \
  --count 1 \
  --instance-type t2.micro \
  --key-name "${KEY_NAME:-lab01-keypair}" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=lab01-instance}]' \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "    Instance launched: $INSTANCE_ID"

echo "==> Waiting for instance to reach 'running' state..."
awslocal ec2 wait instance-running --instance-ids "$INSTANCE_ID" 2>/dev/null || true

# Append to state file
echo "SG_ID=$SG_ID" >> "$STATE_FILE"
echo "INSTANCE_ID=$INSTANCE_ID" >> "$STATE_FILE"

echo ""
echo "==> EC2 instance ready."
echo "    Instance ID:     $INSTANCE_ID"
echo "    Security Group:  $SG_ID"
echo "    AMI:             $AMI_ID (Amazon Linux 2)"
echo "    Type:            t2.micro"
echo ""
echo "    REAL AWS NOTE: In real AWS, the instance would be reachable via SSH:"
echo "    ssh -i ~/.ssh/lab01-keypair.pem ec2-user@<public-ip>"
echo "    LocalStack simulates the API but does not run actual compute."
