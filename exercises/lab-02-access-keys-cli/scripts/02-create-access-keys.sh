#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab02-state"
[[ -f "$STATE_FILE" ]] || { echo "ERROR: Run 01-create-iam-user.sh first."; exit 1; }
source "$STATE_FILE"

CREDS_CSV="$HOME/.aws/lab02-credentials.csv"
mkdir -p "$HOME/.aws"

echo "==> Creating access keys for user: $USERNAME"
CREDS_JSON=$(awslocal iam create-access-key \
  --user-name "$USERNAME" \
  --output json)

ACCESS_KEY_ID=$(echo "$CREDS_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])")
SECRET_ACCESS_KEY=$(echo "$CREDS_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['SecretAccessKey'])")

# Save to a credentials CSV (mirrors the real AWS console "Download .csv" button)
echo "Access key ID,Secret access key" > "$CREDS_CSV"
echo "$ACCESS_KEY_ID,$SECRET_ACCESS_KEY" >> "$CREDS_CSV"
chmod 600 "$CREDS_CSV"

# Append to state file for use by subsequent scripts
echo "ACCESS_KEY_ID=$ACCESS_KEY_ID" >> "$STATE_FILE"
echo "SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY" >> "$STATE_FILE"

echo ""
echo "  Access Key ID:     $ACCESS_KEY_ID"
echo "  Secret Access Key: [saved to $CREDS_CSV]"
echo ""
echo "  *** REAL AWS WARNING ***"
echo "  In real AWS, the Secret Access Key is shown ONLY ONCE."
echo "  Download the CSV immediately — you cannot retrieve it later."
echo "  If lost, you must delete this key and create a new one."
echo "  NEVER commit credentials to git or share them in Slack/email."
