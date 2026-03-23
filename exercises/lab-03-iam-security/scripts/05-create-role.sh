#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab03-state"
[[ -f "$STATE_FILE" ]] && source "$STATE_FILE" || true

echo "==> Creating IAM Role for EC2 (instance profile pattern)"
echo ""
echo "    Roles are like users but assumed TEMPORARILY by services."
echo "    An EC2 instance profile lets an instance call AWS APIs without"
echo "    embedding access keys in the instance."

# Trust policy — allows EC2 service to assume this role
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

echo ""
echo "==> Creating role: EC2S3ReadRole"
ROLE_ARN=$(awslocal iam create-role \
  --role-name EC2S3ReadRole \
  --assume-role-policy-document "$TRUST_POLICY" \
  --description "Allows EC2 instances to read from S3" \
  --query 'Role.Arn' --output text)
echo "    Role ARN: $ROLE_ARN"

echo ""
echo "==> Attaching S3 read-only policy to the role..."
awslocal iam attach-role-policy \
  --role-name EC2S3ReadRole \
  --policy-arn "${S3_POLICY_ARN:-arn:aws:iam::000000000000:policy/S3ReadOnlyPolicy}"

echo ""
echo "==> Creating an instance profile and linking the role..."
awslocal iam create-instance-profile \
  --instance-profile-name EC2S3ReadProfile

awslocal iam add-role-to-instance-profile \
  --instance-profile-name EC2S3ReadProfile \
  --role-name EC2S3ReadRole

echo ""
echo "==> Verifying role configuration..."
awslocal iam get-role \
  --role-name EC2S3ReadRole \
  --query 'Role.{Name:RoleName,ARN:Arn,MaxSessionDuration:MaxSessionDuration}' \
  --output table

echo ""
echo "==> Attached policies on role:"
awslocal iam list-attached-role-policies \
  --role-name EC2S3ReadRole \
  --query 'AttachedPolicies[*].{Name:PolicyName,ARN:PolicyArn}' \
  --output table

echo "ROLE_ARN=$ROLE_ARN" >> "$STATE_FILE"

echo ""
echo "==> Role setup complete."
echo ""
echo "    To attach this instance profile to an EC2 instance (real AWS):"
echo "    aws ec2 associate-iam-instance-profile \\"
echo "      --instance-id <instance-id> \\"
echo "      --iam-instance-profile Name=EC2S3ReadProfile"
echo ""
echo "    The instance can then use the AWS SDK/CLI without any access keys."
echo "    Credentials are served via the metadata service and rotate automatically."
