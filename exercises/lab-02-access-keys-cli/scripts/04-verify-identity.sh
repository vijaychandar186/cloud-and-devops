#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab02-state"
[[ -f "$STATE_FILE" ]] || { echo "ERROR: Run 03-configure-aws-profile.sh first."; exit 1; }
source "$STATE_FILE"

echo "==> Verifying identity using default credentials (test/root)..."
echo "    Command: aws sts get-caller-identity"
awslocal sts get-caller-identity

echo ""
echo "==> Verifying identity using the lab02 profile..."
echo "    Command: aws --profile lab02 sts get-caller-identity"
aws --endpoint-url="$LOCALSTACK_ENDPOINT" \
    --profile "${PROFILE_NAME:-lab02}" \
    sts get-caller-identity

echo ""
echo "    'sts get-caller-identity' is the canonical way to check:"
echo "    - Which account you are connected to (Account)"
echo "    - Which IAM principal is making the call (Arn)"
echo "    - The unique session identifier (UserId)"
echo ""
echo "    Use this any time you need to confirm which credentials are active."
