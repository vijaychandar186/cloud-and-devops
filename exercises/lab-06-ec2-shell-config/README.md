# Lab 6 — EC2 Instance Creation and Shell Configuration

## Objectives

- Launch an EC2 instance with a **user data** startup script
- Create a key pair and security group scoped to SSH access
- Understand how to connect via SSH and configure the remote shell
- Customise the shell environment (aliases, PS1, PATH, `.bashrc`)
- Manage networking services with `systemctl`

## Background

**User data** is a shell script you attach to an EC2 instance at launch. AWS runs it as `root`
on first boot — it's the standard way to install packages, write config files, and configure
the shell for all future users without manual SSH steps.

**SSH (Secure Shell)** is the standard protocol for remote access to Linux instances.
You authenticate with a **key pair**: AWS holds the public key, you hold the private `.pem`.

**systemctl** is the service manager on modern Linux (systemd). It starts, stops, enables,
and disables daemons — including networking services.

## Scripts

Run each script in order:

```bash
cd lab-06-ec2-shell-config/

# 1. Create key pair and security group for SSH
bash scripts/01-create-ssh-keypair-sg.sh

# 2. Launch EC2 instance with a user-data shell config script
bash scripts/02-launch-instance-with-userdata.sh

# 3. Show shell configuration best practices (.bashrc, aliases, PS1)
bash scripts/03-shell-config-demo.sh

# 4. Demonstrate systemctl service management
bash scripts/04-systemctl-services.sh

# 5. Verify the instance and print SSH connection instructions
bash scripts/05-verify-and-connect.sh

# Tear down when done
bash scripts/cleanup.sh
```

## Part 1 — Key Pair and Security Group

The security group acts as a firewall. For SSH you only need port 22 inbound.

```
Your machine  ──(TCP 22)──►  Security Group  ──►  EC2 instance
                              (allow 22/tcp)
```

Best practice in real AWS: restrict port 22 to your own IP (`<your-ip>/32`), not `0.0.0.0/0`.

## Part 2 — User Data

User data runs once at first boot as `root`. Example:

```bash
#!/bin/bash
# Runs on first boot
apt update -y
echo 'alias ll="ls -lah"' >> /home/ubuntu/.bashrc
echo 'export PS1="\u@\h:\w\$ "' >> /home/ubuntu/.bashrc
systemctl enable ssh
```

In real AWS you can view user data from inside the instance:

```bash
curl http://169.254.169.254/latest/user-data
```

## Part 3 — Shell Configuration

| File | When it runs | Purpose |
|------|-------------|---------|
| `~/.bashrc` | Every interactive non-login shell | Aliases, functions, prompt |
| `~/.bash_profile` | Login shell only | Environment variables, PATH |
| `~/.bash_logout` | On logout | Cleanup tasks |

Key customisations:

```bash
# Aliases
alias ll='ls -lah'
alias grep='grep --color=auto'
alias ..='cd ..'

# Custom prompt (PS1)
export PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '

# PATH additions
export PATH="$HOME/.local/bin:$PATH"
```

## Part 4 — systemctl (Service Management)

```bash
systemctl status <service>    # current state
systemctl start <service>     # start now
systemctl stop <service>      # stop now
systemctl enable <service>    # start automatically at boot
systemctl disable <service>   # do not start at boot
systemctl restart <service>   # stop then start
systemctl list-units --type=service   # show all services
```

Common services on Ubuntu EC2:

| Service | Purpose |
|---------|---------|
| `ssh` | Remote shell access (OpenSSH) |
| `NetworkManager` | Network interface management |
| `systemd-networkd` | Lightweight network management |
| `ufw` | Uncomplicated Firewall |

## Part 5 — Connecting via SSH (real AWS)

After launch, get the public IP and connect:

```bash
# Get the public IP
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# Connect
ssh -i ~/.ssh/lab06-keypair.pem ubuntu@<public-ip>
```

> **LocalStack note:** LocalStack simulates the EC2 API but does not run real compute.
> SSH connections are not possible against LocalStack instances.
