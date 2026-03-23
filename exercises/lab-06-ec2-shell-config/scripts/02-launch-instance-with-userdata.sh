#!/usr/bin/env bash
# Lab 06 — Script 2: Launch EC2 instance with a user-data shell config script
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env"

echo "=========================================="
echo " Lab 06 — Launch EC2 with User Data"
echo "=========================================="

# Resolve security group
SG_ID=$(awslocal ec2 describe-security-groups \
    --filters "Name=group-name,Values=lab06-ssh-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
echo "==> Using security group: $SG_ID"

# Resolve a subnet
SUBNET_ID=$(awslocal ec2 describe-subnets \
    --query 'Subnets[0].SubnetId' \
    --output text)
echo "==> Using subnet: $SUBNET_ID"

# Write user data script to a temp file
USERDATA_FILE=$(mktemp /tmp/lab06-userdata-XXXX.sh)
cat > "$USERDATA_FILE" <<'USERDATA'
#!/bin/bash
# This script runs once at first boot as root.
# It configures the shell environment for the ubuntu user.

# Update packages
apt-get update -y -q

# Configure .bashrc for the ubuntu user
BASHRC="/home/ubuntu/.bashrc"

cat >> "$BASHRC" <<'EOF'

# --- Lab 06 shell config (added by user data) ---
alias ll='ls -lah'
alias grep='grep --color=auto'
alias ..='cd ..'
alias df='df -h'
alias free='free -h'

export PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
export HISTSIZE=10000
export HISTFILESIZE=20000
export EDITOR=nano
EOF

chown ubuntu:ubuntu "$BASHRC"

# Enable SSH service at boot
systemctl enable ssh

# Write a welcome message
cat > /etc/motd <<'EOF'

  Welcome to Lab 06 — EC2 Shell Configuration
  --------------------------------------------
  Shell config applied via user data at launch.
  Run: source ~/.bashrc   to reload config.

EOF

echo "User data script complete."
USERDATA

echo ""
echo "==> User data script:"
cat "$USERDATA_FILE"
echo ""

# Launch instance
echo "==> Launching EC2 instance (t2.micro, Amazon Linux 2)..."
INSTANCE_ID=$(awslocal ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --instance-type t2.micro \
    --key-name lab06-keypair \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --user-data "file://$USERDATA_FILE" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=lab06-instance},{Key=Lab,Value=lab06}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

rm -f "$USERDATA_FILE"

echo "    Instance ID: $INSTANCE_ID"
echo ""
echo "==> Waiting for instance to reach 'running' state..."
awslocal ec2 wait instance-running --instance-ids "$INSTANCE_ID" 2>/dev/null || true
echo "    State: running"

echo ""
echo "==> Instance ready: $INSTANCE_ID"
echo ""
echo "    REAL AWS NOTE: After ~60s the user-data script will have run."
echo "    Retrieve logs from inside the instance:"
echo "    sudo cat /var/log/cloud-init-output.log"
