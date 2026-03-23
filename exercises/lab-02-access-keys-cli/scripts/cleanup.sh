#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab02-state"
[[ -f "$STATE_FILE" ]] && source "$STATE_FILE" || true

echo "==> Cleaning up Lab 02 resources..."

if [[ -n "${USERNAME:-}" ]]; then
  # Delete all access keys for the user
  KEY_IDS=$(awslocal iam list-access-keys \
    --user-name "$USERNAME" \
    --query 'AccessKeyMetadata[*].AccessKeyId' \
    --output text 2>/dev/null || echo "")

  for KEY_ID in $KEY_IDS; do
    echo "    Deleting access key: $KEY_ID"
    awslocal iam delete-access-key \
      --user-name "$USERNAME" \
      --access-key-id "$KEY_ID" 2>/dev/null || true
  done

  echo "    Deleting IAM user: $USERNAME"
  awslocal iam delete-user --user-name "$USERNAME" 2>/dev/null || true
fi

# Remove CLI profile
if [[ -n "${PROFILE_NAME:-}" ]]; then
  echo "    Removing CLI profile: $PROFILE_NAME"
  aws configure set aws_access_key_id "" --profile "$PROFILE_NAME" 2>/dev/null || true
fi

# Remove local credential files
rm -f "$HOME/.aws/lab02-credentials.csv"
rm -f "$STATE_FILE"

echo ""
echo "==> Lab 02 cleanup complete."
