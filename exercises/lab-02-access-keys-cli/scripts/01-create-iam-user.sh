#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab02-state"
USERNAME="lab02-developer"

echo "==> Creating IAM user: $USERNAME"
awslocal iam create-user \
  --user-name "$USERNAME" \
  --tags Key=Purpose,Value=Lab02 Key=Environment,Value=LocalStack

echo ""
echo "==> Verifying user was created..."
awslocal iam get-user \
  --user-name "$USERNAME" \
  --query 'User.{Name:UserName,ARN:Arn,Created:CreateDate}' \
  --output table

# Save state
echo "USERNAME=$USERNAME" > "$STATE_FILE"

echo ""
echo "==> IAM user created: $USERNAME"
echo ""
echo "    REAL AWS NOTE: In real AWS this creates a user in your account."
echo "    By default the user has NO permissions — you must attach policies"
echo "    (covered in Lab 3) before they can do anything."
