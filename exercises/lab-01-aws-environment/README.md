# Lab 1 — Creating an AWS Environment

## Objectives

- Create a Virtual Private Cloud (VPC) with a public subnet and internet gateway
- Create an S3 bucket with versioning and a lifecycle policy
- Generate an EC2 key pair
- Launch an EC2 instance into the VPC
- Verify all resources using AWS CLI describe commands

## Background

Every AWS workload lives inside a **VPC** — an isolated virtual network you control.
Within a VPC you define **subnets** (smaller IP ranges tied to an Availability Zone).
An **Internet Gateway** connects a public subnet to the internet.

**S3** is object storage — think of it as an infinitely scalable file system accessible via HTTP.

**EC2** provides virtual machines (called *instances*). Each instance needs a VPC, a subnet,
a security group (firewall rules), and optionally a key pair for SSH access.

## Scripts

Run each script in order:

```bash
cd lab-01-aws-environment/

# 1. Create VPC, subnet, internet gateway, route table
bash scripts/01-create-vpc.sh

# 2. Create S3 bucket with versioning
bash scripts/02-create-s3-bucket.sh

# 3. Create EC2 key pair (saved to ~/.ssh/)
bash scripts/03-create-ec2-keypair.sh

# 4. Launch EC2 instance
bash scripts/04-launch-ec2-instance.sh

# 5. Verify everything
bash scripts/05-verify-environment.sh

# Tear down when done
bash scripts/cleanup.sh
```

## Real AWS Notes

> **VPCs:** In real AWS, you get a default VPC per region. Creating a custom VPC
> gives you full control over CIDR blocks, subnet layout, and routing.

> **S3 bucket names:** Must be globally unique across all AWS customers. The scripts
> append a timestamp to avoid collisions.

> **EC2 key pairs:** The private key is shown only once at creation. If you lose it,
> you cannot SSH into the instance — you must terminate it and launch a new one.

> **LocalStack EC2:** Instances are simulated. The API calls work identically to real
> AWS but no actual virtual machine runs.
