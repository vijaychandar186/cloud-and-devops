#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

STATE_FILE="$SCRIPT_DIR/../.lab01-state"

echo "==> Creating VPC..."
VPC_ID=$(awslocal ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=lab01-vpc}]' \
  --query 'Vpc.VpcId' --output text)
echo "    VPC created: $VPC_ID"

echo "==> Enabling DNS hostnames on VPC..."
awslocal ec2 modify-vpc-attribute \
  --vpc-id "$VPC_ID" \
  --enable-dns-hostnames '{"Value": true}'

echo "==> Creating public subnet (10.0.1.0/24 in us-east-1a)..."
SUBNET_ID=$(awslocal ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab01-public-subnet}]' \
  --query 'Subnet.SubnetId' --output text)
echo "    Subnet created: $SUBNET_ID"

echo "==> Creating Internet Gateway..."
IGW_ID=$(awslocal ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=lab01-igw}]' \
  --query 'InternetGateway.InternetGatewayId' --output text)
echo "    Internet Gateway created: $IGW_ID"

echo "==> Attaching Internet Gateway to VPC..."
awslocal ec2 attach-internet-gateway \
  --internet-gateway-id "$IGW_ID" \
  --vpc-id "$VPC_ID"

echo "==> Creating route table and adding route to internet..."
RTB_ID=$(awslocal ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --query 'RouteTable.RouteTableId' --output text)

awslocal ec2 create-route \
  --route-table-id "$RTB_ID" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$IGW_ID" > /dev/null

awslocal ec2 associate-route-table \
  --route-table-id "$RTB_ID" \
  --subnet-id "$SUBNET_ID" > /dev/null

# Save state for subsequent scripts
cat > "$STATE_FILE" <<EOF
VPC_ID=$VPC_ID
SUBNET_ID=$SUBNET_ID
IGW_ID=$IGW_ID
RTB_ID=$RTB_ID
EOF

echo ""
echo "==> Done! Network environment ready."
echo "    VPC:     $VPC_ID (10.0.0.0/16)"
echo "    Subnet:  $SUBNET_ID (10.0.1.0/24)"
echo "    IGW:     $IGW_ID"
