#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=../../.env
source "${SCRIPT_DIR}/../../.env"

echo ""
echo "============================================================"
echo "  Stage 1: Provision Cloud Infrastructure (Terraform + LocalStack)"
echo "============================================================"
echo ""

# --- Check LocalStack is running ---
echo ">>> Checking LocalStack health..."
if ! curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; then
  echo ""
  echo "ERROR: LocalStack is not running or not reachable at http://localhost:4566"
  echo ""
  echo "  Start it with:"
  echo "    localstack start -d && localstack wait -t 30"
  echo ""
  exit 1
fi
echo "    LocalStack is healthy."
echo ""

# --- Terraform init + apply ---
TERRAFORM_DIR="${LAB_DIR}/terraform"
echo ">>> Initialising Terraform in ${TERRAFORM_DIR} ..."
cd "${TERRAFORM_DIR}"
terraform init -input=false

echo ""
echo ">>> Applying Terraform configuration..."
terraform apply -auto-approve -input=false

# --- Print outputs ---
echo ""
echo ">>> Terraform outputs:"
BUCKET_NAME=$(terraform output -raw artifacts_bucket)
TOPIC_ARN=$(terraform output -raw notifications_topic_arn)
echo "    Artifacts bucket : ${BUCKET_NAME}"
echo "    SNS topic ARN    : ${TOPIC_ARN}"

# --- Upload placeholder artifact ---
echo ""
echo ">>> Uploading placeholder pipeline artifact to S3..."
ARTIFACT_TMP=$(mktemp)
echo "Lab 15 pipeline run: $(date)" > "${ARTIFACT_TMP}"
awslocal s3 cp "${ARTIFACT_TMP}" "s3://${BUCKET_NAME}/pipeline-run.txt"
rm -f "${ARTIFACT_TMP}"
echo "    Artifact uploaded."

# --- Verify ---
echo ""
echo ">>> Verifying bucket contents:"
awslocal s3 ls "s3://${BUCKET_NAME}/"

echo ""
echo "------------------------------------------------------------"
echo "  NOTE: In a real AWS environment this stage would provision:"
echo "    - An ECR registry to store your Docker image"
echo "    - An RDS database for application state"
echo "    - An EKS cluster (or other managed Kubernetes service)"
echo "  LocalStack lets us practice the same Terraform workflow"
echo "  locally at zero cost."
echo "------------------------------------------------------------"
echo ""
echo "  Stage 1 complete."
echo ""
