#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

KEY_NAME="lab01-keypair"
KEY_FILE="$HOME/.ssh/${KEY_NAME}.pem"

mkdir -p "$HOME/.ssh"

echo "==> Creating EC2 key pair: $KEY_NAME"

# Check if the key pair already exists in LocalStack
EXISTING=$(awslocal ec2 describe-key-pairs \
  --key-names "$KEY_NAME" \
  --query 'KeyPairs[0].KeyName' \
  --output text 2>/dev/null || echo "None")

if [[ "$EXISTING" == "$KEY_NAME" ]]; then
  echo "    Key pair '$KEY_NAME' already exists. Deleting and recreating..."
  awslocal ec2 delete-key-pair --key-name "$KEY_NAME"
fi

awslocal ec2 create-key-pair \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "$KEY_FILE"

chmod 400 "$KEY_FILE"

# Append to state
echo "KEY_NAME=$KEY_NAME" >> "$SCRIPT_DIR/../.lab01-state"
echo "KEY_FILE=$KEY_FILE" >> "$SCRIPT_DIR/../.lab01-state"

echo ""
echo "==> Key pair created and saved."
echo "    Private key: $KEY_FILE (permissions: 400)"
echo ""
echo "    REAL AWS NOTE: In real AWS, the private key is shown only ONCE."
echo "    If you lose it, you must terminate the instance and launch a new one."
echo "    Never commit .pem files to git."
