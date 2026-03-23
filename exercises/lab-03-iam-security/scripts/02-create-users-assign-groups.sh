#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab03-state"
[[ -f "$STATE_FILE" ]] || { echo "ERROR: Run 01-create-groups.sh first."; exit 1; }

declare -A USER_GROUPS=(
  ["alice"]="developers"
  ["bob"]="read-only-auditors"
  ["carol"]="admin"
)

echo "==> Creating IAM users and assigning to groups..."

for USER in "${!USER_GROUPS[@]}"; do
  GROUP="${USER_GROUPS[$USER]}"
  echo "    Creating user: $USER -> group: $GROUP"

  awslocal iam create-user \
    --user-name "$USER" \
    --tags Key=Lab,Value=Lab03 > /dev/null

  awslocal iam add-user-to-group \
    --user-name "$USER" \
    --group-name "$GROUP"
done

echo ""
echo "==> Verifying group memberships..."
for GROUP in developers read-only-auditors admin; do
  echo ""
  echo "    Group: $GROUP"
  awslocal iam get-group \
    --group-name "$GROUP" \
    --query 'Users[*].UserName' \
    --output table
done

echo "USERS_CREATED=true" >> "$STATE_FILE"
