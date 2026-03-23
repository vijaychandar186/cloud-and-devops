#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab03-state"
[[ -f "$STATE_FILE" ]] && source "$STATE_FILE" || true

echo "==> Cleaning up Lab 03 resources..."

# Remove role from instance profile, then delete both
echo "    Removing role from instance profile..."
awslocal iam remove-role-from-instance-profile \
  --instance-profile-name EC2S3ReadProfile \
  --role-name EC2S3ReadRole 2>/dev/null || true

echo "    Deleting instance profile: EC2S3ReadProfile"
awslocal iam delete-instance-profile \
  --instance-profile-name EC2S3ReadProfile 2>/dev/null || true

# Detach policies from role before deleting
echo "    Detaching policies from role: EC2S3ReadRole"
awslocal iam detach-role-policy \
  --role-name EC2S3ReadRole \
  --policy-arn "${S3_POLICY_ARN:-arn:aws:iam::000000000000:policy/S3ReadOnlyPolicy}" 2>/dev/null || true

echo "    Deleting role: EC2S3ReadRole"
awslocal iam delete-role --role-name EC2S3ReadRole 2>/dev/null || true

# Remove users from groups and delete users
for USER in alice bob carol; do
  GROUP=$(awslocal iam list-groups-for-user \
    --user-name "$USER" \
    --query 'Groups[*].GroupName' \
    --output text 2>/dev/null || echo "")

  for G in $GROUP; do
    echo "    Removing $USER from group $G"
    awslocal iam remove-user-from-group \
      --user-name "$USER" --group-name "$G" 2>/dev/null || true
  done

  echo "    Deleting user: $USER"
  awslocal iam delete-user --user-name "$USER" 2>/dev/null || true
done

# Detach managed policies from groups and delete inline policies, then delete groups
for GROUP in developers read-only-auditors admin; do
  echo "    Cleaning group: $GROUP"

  # Detach managed policies
  ATTACHED=$(awslocal iam list-attached-group-policies \
    --group-name "$GROUP" \
    --query 'AttachedPolicies[*].PolicyArn' \
    --output text 2>/dev/null || echo "")
  for ARN in $ATTACHED; do
    awslocal iam detach-group-policy --group-name "$GROUP" --policy-arn "$ARN" 2>/dev/null || true
  done

  # Delete inline policies
  INLINE=$(awslocal iam list-group-policies \
    --group-name "$GROUP" \
    --query 'PolicyNames' \
    --output text 2>/dev/null || echo "")
  for POLICY in $INLINE; do
    awslocal iam delete-group-policy --group-name "$GROUP" --policy-name "$POLICY" 2>/dev/null || true
  done

  awslocal iam delete-group --group-name "$GROUP" 2>/dev/null || true
done

# Delete customer-managed policies
for ARN in "${S3_POLICY_ARN:-}" "${ADMIN_POLICY_ARN:-}"; do
  [[ -z "$ARN" ]] && continue
  echo "    Deleting policy: $ARN"
  awslocal iam delete-policy --policy-arn "$ARN" 2>/dev/null || true
done

rm -f "$STATE_FILE"

echo ""
echo "==> Lab 03 cleanup complete."
