#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab03-state"

echo "==> Creating IAM groups..."

for GROUP in developers read-only-auditors admin; do
  echo "    Creating group: $GROUP"
  awslocal iam create-group --group-name "$GROUP" > /dev/null
done

echo ""
echo "==> Verifying groups..."
awslocal iam list-groups \
  --query 'Groups[*].{Name:GroupName,ARN:Arn}' \
  --output table

echo "GROUPS_CREATED=true" > "$STATE_FILE"

echo ""
echo "==> Groups created: developers, read-only-auditors, admin"
echo "    Groups have NO permissions yet — policies are attached in script 03."
