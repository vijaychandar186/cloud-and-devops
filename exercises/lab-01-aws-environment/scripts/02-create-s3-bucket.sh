#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab01-state"
[[ -f "$STATE_FILE" ]] && source "$STATE_FILE"

# Bucket names must be globally unique — append a timestamp
BUCKET_NAME="lab01-bucket-$(date +%s)"

echo "==> Creating S3 bucket: $BUCKET_NAME"
awslocal s3 mb "s3://$BUCKET_NAME"

echo "==> Enabling versioning..."
awslocal s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "==> Applying lifecycle policy (transition to IA after 30 days, expire after 365)..."
awslocal s3api put-bucket-lifecycle-configuration \
  --bucket "$BUCKET_NAME" \
  --lifecycle-configuration "file://$SCRIPT_DIR/../configs/lifecycle.json"

echo "==> Uploading a sample object..."
echo "Hello from Lab 01 — $(date)" | \
  awslocal s3 cp - "s3://$BUCKET_NAME/hello.txt"

echo "==> Verifying bucket contents..."
awslocal s3 ls "s3://$BUCKET_NAME"

# Append bucket name to state file
echo "BUCKET_NAME=$BUCKET_NAME" >> "$STATE_FILE"

echo ""
echo "==> S3 bucket ready: $BUCKET_NAME"
echo "    Versioning: Enabled"
echo "    Lifecycle: objects expire after 365 days"
