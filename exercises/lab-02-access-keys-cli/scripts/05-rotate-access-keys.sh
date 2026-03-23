#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab02-state"
[[ -f "$STATE_FILE" ]] || { echo "ERROR: Run 02-create-access-keys.sh first."; exit 1; }
source "$STATE_FILE"

OLD_KEY_ID="$ACCESS_KEY_ID"

echo "======================================================"
echo " Access Key Rotation — Security Best Practice"
echo " AWS recommends rotating keys every 90 days"
echo "======================================================"
echo ""
echo "==> Step 1: Create a NEW access key (now you have two active keys)"
NEW_CREDS_JSON=$(awslocal iam create-access-key \
  --user-name "$USERNAME" \
  --output json)

NEW_KEY_ID=$(echo "$NEW_CREDS_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])")
NEW_SECRET=$(echo "$NEW_CREDS_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['SecretAccessKey'])")
echo "    New key created: $NEW_KEY_ID"

echo ""
echo "==> Step 2: Update the CLI profile with the new key"
echo "    (In a real environment you would update ALL services/apps using the old key)"
aws configure set aws_access_key_id "$NEW_KEY_ID" --profile "${PROFILE_NAME:-lab02}"
aws configure set aws_secret_access_key "$NEW_SECRET" --profile "${PROFILE_NAME:-lab02}"

echo ""
echo "==> Step 3: Verify the NEW key works before deleting the old one"
aws --endpoint-url="$LOCALSTACK_ENDPOINT" \
    --profile "${PROFILE_NAME:-lab02}" \
    sts get-caller-identity

echo ""
echo "==> Step 4: Deactivate the OLD key (safe — does not delete yet)"
awslocal iam update-access-key \
  --user-name "$USERNAME" \
  --access-key-id "$OLD_KEY_ID" \
  --status Inactive
echo "    Old key $OLD_KEY_ID set to Inactive"

echo ""
echo "==> Step 5: (After confirming nothing broke) Delete the old key"
awslocal iam delete-access-key \
  --user-name "$USERNAME" \
  --access-key-id "$OLD_KEY_ID"
echo "    Old key $OLD_KEY_ID deleted"

# Update state file with new key
sed -i "s/ACCESS_KEY_ID=.*/ACCESS_KEY_ID=$NEW_KEY_ID/" "$STATE_FILE"
sed -i "s/SECRET_ACCESS_KEY=.*/SECRET_ACCESS_KEY=$NEW_SECRET/" "$STATE_FILE"

echo ""
echo "==> Listing current access keys for $USERNAME..."
awslocal iam list-access-keys \
  --user-name "$USERNAME" \
  --query 'AccessKeyMetadata[*].{ID:AccessKeyId,Status:Status,Created:CreateDate}' \
  --output table

echo ""
echo "==> Rotation complete. Active key: $NEW_KEY_ID"
echo ""
echo "    KEY ROTATION CHECKLIST (real AWS):"
echo "    [ ] Create new key"
echo "    [ ] Update all consumers (EC2 user data, Lambda env vars, CI/CD secrets, apps)"
echo "    [ ] Verify everything works with the new key"
echo "    [ ] Deactivate old key and monitor for errors"
echo "    [ ] Wait 24-48 hours, then delete old key"
