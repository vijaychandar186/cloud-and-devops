#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab03-state"
POLICIES_DIR="$SCRIPT_DIR/../policies"

echo "==> Creating and attaching IAM policies..."

# --- Managed policy: S3 read-only -> read-only-auditors group ---
echo ""
echo "    [Managed Policy] S3ReadOnlyPolicy -> read-only-auditors"
S3_POLICY_ARN=$(awslocal iam create-policy \
  --policy-name S3ReadOnlyPolicy \
  --description "Allows read-only access to all S3 buckets" \
  --policy-document "file://$POLICIES_DIR/s3-read-only-policy.json" \
  --query 'Policy.Arn' --output text)

awslocal iam attach-group-policy \
  --group-name read-only-auditors \
  --policy-arn "$S3_POLICY_ARN"
echo "    Attached: $S3_POLICY_ARN"

# --- Managed policy: Admin -> admin group ---
echo ""
echo "    [Managed Policy] AdminPolicy -> admin"
ADMIN_POLICY_ARN=$(awslocal iam create-policy \
  --policy-name AdminPolicy \
  --description "Full admin access — use only for break-glass accounts" \
  --policy-document "file://$POLICIES_DIR/admin-policy.json" \
  --query 'Policy.Arn' --output text)

awslocal iam attach-group-policy \
  --group-name admin \
  --policy-arn "$ADMIN_POLICY_ARN"
echo "    Attached: $ADMIN_POLICY_ARN"

# --- Inline policy: EC2 describe -> developers group ---
# Inline policies are embedded in the principal — useful for one-off grants
# that should not be reused elsewhere.
echo ""
echo "    [Inline Policy] EC2DescribeInlinePolicy -> developers"
awslocal iam put-group-policy \
  --group-name developers \
  --policy-name EC2DescribeInlinePolicy \
  --policy-document "file://$POLICIES_DIR/ec2-describe-policy.json"
echo "    Inline policy attached to developers group"

# Save ARNs for cleanup
echo "S3_POLICY_ARN=$S3_POLICY_ARN" >> "$STATE_FILE"
echo "ADMIN_POLICY_ARN=$ADMIN_POLICY_ARN" >> "$STATE_FILE"

echo ""
echo "==> Verifying attached policies..."
for GROUP in developers read-only-auditors admin; do
  echo ""
  echo "    Group: $GROUP — managed policies:"
  awslocal iam list-attached-group-policies \
    --group-name "$GROUP" \
    --query 'AttachedPolicies[*].{Name:PolicyName,ARN:PolicyArn}' \
    --output table

  echo "    Group: $GROUP — inline policies:"
  awslocal iam list-group-policies \
    --group-name "$GROUP" \
    --query 'PolicyNames' \
    --output table
done

echo ""
echo "==> Policy summary:"
echo "    alice  (developers)       -> EC2 read-only   [inline]"
echo "    bob    (read-only-auditors) -> S3 read-only  [managed]"
echo "    carol  (admin)            -> Full admin       [managed]"
echo ""
echo "    Managed policies are reusable and versioned."
echo "    Inline policies are embedded and deleted with the principal."
