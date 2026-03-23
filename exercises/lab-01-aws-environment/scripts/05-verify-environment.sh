#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

echo "=========================================="
echo " Lab 01 — Environment Verification"
echo "=========================================="

echo ""
echo "--- VPCs ---"
awslocal ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=lab01-vpc" \
  --query 'Vpcs[*].{ID:VpcId,CIDR:CidrBlock,State:State}' \
  --output table

echo ""
echo "--- Subnets ---"
awslocal ec2 describe-subnets \
  --filters "Name=tag:Name,Values=lab01-public-subnet" \
  --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone}' \
  --output table

echo ""
echo "--- Internet Gateways ---"
awslocal ec2 describe-internet-gateways \
  --filters "Name=tag:Name,Values=lab01-igw" \
  --query 'InternetGateways[*].{ID:InternetGatewayId,State:Attachments[0].State}' \
  --output table

echo ""
echo "--- S3 Buckets ---"
awslocal s3 ls

echo ""
echo "--- Security Groups ---"
awslocal ec2 describe-security-groups \
  --filters "Name=group-name,Values=lab01-sg" \
  --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName,VPC:VpcId}' \
  --output table

echo ""
echo "--- EC2 Instances ---"
awslocal ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab01-instance" \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,State:State.Name,AZ:Placement.AvailabilityZone}' \
  --output table

echo ""
echo "--- Key Pairs ---"
awslocal ec2 describe-key-pairs \
  --query 'KeyPairs[*].{Name:KeyName,Fingerprint:KeyFingerprint}' \
  --output table

echo ""
echo "=========================================="
echo " Verification complete."
echo "=========================================="
