#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab02-state"
[[ -f "$STATE_FILE" ]] || { echo "ERROR: Run 02-create-access-keys.sh first."; exit 1; }
source "$STATE_FILE"

PROFILE_NAME="lab02"

echo "==> Configuring AWS CLI profile: $PROFILE_NAME"

# Using 'aws configure set' so the script is non-interactive
aws configure set aws_access_key_id "$ACCESS_KEY_ID" --profile "$PROFILE_NAME"
aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY" --profile "$PROFILE_NAME"
aws configure set region us-east-1 --profile "$PROFILE_NAME"
aws configure set output json --profile "$PROFILE_NAME"

# Append profile name to state
echo "PROFILE_NAME=$PROFILE_NAME" >> "$STATE_FILE"

echo ""
echo "==> Profile '$PROFILE_NAME' configured."
echo ""
echo "--- ~/.aws/config (profile entry) ---"
grep -A4 "\[profile $PROFILE_NAME\]" "$HOME/.aws/config" 2>/dev/null || \
  grep -A4 "\[$PROFILE_NAME\]" "$HOME/.aws/config" 2>/dev/null || \
  echo "(config file not found — LocalStack test credentials may be in env vars)"

echo ""
echo "--- ~/.aws/credentials (redacted) ---"
if [[ -f "$HOME/.aws/credentials" ]]; then
  awk -v profile="$PROFILE_NAME" '
    /^\[/ { in_profile = ($0 == "[" profile "]") }
    in_profile && /aws_secret_access_key/ { print "aws_secret_access_key = [REDACTED]"; next }
    in_profile { print }
  ' "$HOME/.aws/credentials"
fi

echo ""
echo "==> Usage: aws --profile $PROFILE_NAME --endpoint-url=$LOCALSTACK_ENDPOINT <command>"
