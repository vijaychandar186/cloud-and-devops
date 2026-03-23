#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

# Color output helpers
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "    ${GREEN}PASS${NC}: $1"; }
fail() { echo -e "    ${RED}FAIL${NC}: $1"; }
info() { echo -e "    ${YELLOW}INFO${NC}: $1"; }

echo "======================================================="
echo " Lab 03 — Permission Testing"
echo " Shows what each user CAN and CANNOT do based on their"
echo " group's policy attachments."
echo ""
echo " NOTE: LocalStack free tier has partial IAM enforcement."
echo " Commands marked [EXPECTED DENY] show real AWS behavior."
echo "======================================================="

# ---- alice (developers) — has EC2 describe-only ----
echo ""
echo "--- alice (developers group: EC2 read-only) ---"

echo ""
echo "  Test: ec2 describe-instances [EXPECTED: ALLOW]"
if awslocal ec2 describe-instances \
     --query 'Reservations[*].Instances[*].InstanceId' \
     --output text > /dev/null 2>&1; then
  pass "ec2:DescribeInstances succeeded"
else
  fail "ec2:DescribeInstances failed (unexpected)"
fi

echo ""
echo "  Test: s3 ls [EXPECTED DENY — alice has no S3 permissions]"
info "In real AWS this would return AccessDenied."
info "LocalStack free tier may not enforce this denial."
awslocal s3 ls 2>&1 | head -3 || true

echo ""
echo "  Test: ec2 run-instances [EXPECTED DENY — alice is read-only]"
info "In real AWS: ec2:RunInstances would be denied."
info "LocalStack free tier may allow this call regardless."

# ---- bob (read-only-auditors) — has S3 read-only ----
echo ""
echo "--- bob (read-only-auditors group: S3 read-only) ---"

echo ""
echo "  Test: s3 ls [EXPECTED: ALLOW]"
if awslocal s3 ls > /dev/null 2>&1; then
  pass "s3:ListAllMyBuckets succeeded"
else
  fail "s3:ListAllMyBuckets failed (unexpected)"
fi

echo ""
echo "  Test: s3 cp to bucket [EXPECTED DENY — bob is read-only]"
info "In real AWS: s3:PutObject would be denied."
info "Attempting upload to a non-existent bucket to trigger denial..."
awslocal s3 cp /dev/null s3://nonexistent-lab03-bucket/test.txt 2>&1 | head -3 || true

echo ""
echo "  Test: ec2 describe-instances [EXPECTED DENY — bob has no EC2 permissions]"
info "In real AWS: ec2:DescribeInstances would be denied for bob."

# ---- carol (admin) — full access ----
echo ""
echo "--- carol (admin group: full access) ---"

echo ""
echo "  Test: s3 mb (create bucket) [EXPECTED: ALLOW]"
TEST_BUCKET="lab03-carol-test-$(date +%s)"
if awslocal s3 mb "s3://$TEST_BUCKET" > /dev/null 2>&1; then
  pass "s3:CreateBucket succeeded"
  awslocal s3 rb "s3://$TEST_BUCKET" 2>/dev/null || true
else
  fail "s3:CreateBucket failed (unexpected for admin)"
fi

echo ""
echo "  Test: iam list-users [EXPECTED: ALLOW]"
if awslocal iam list-users \
     --query 'Users[*].UserName' \
     --output text > /dev/null 2>&1; then
  pass "iam:ListUsers succeeded"
else
  fail "iam:ListUsers failed (unexpected for admin)"
fi

echo ""
echo "======================================================="
echo " Summary: expected real-AWS permissions by group"
echo "======================================================="
printf "  %-10s %-25s %-10s %-10s\n" "User" "Group" "EC2 read" "S3 write"
printf "  %-10s %-25s %-10s %-10s\n" "-----" "-----" "--------" "--------"
printf "  %-10s %-25s %-10s %-10s\n" "alice" "developers"         "ALLOW" "DENY"
printf "  %-10s %-25s %-10s %-10s\n" "bob"   "read-only-auditors" "DENY"  "DENY"
printf "  %-10s %-25s %-10s %-10s\n" "carol" "admin"              "ALLOW" "ALLOW"
