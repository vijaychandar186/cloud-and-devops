# Lab 7 — Terraform Setup and Provider Versioning

## Objectives

- Install Terraform and verify the installation
- Understand what providers are and how Terraform uses them
- Read and write version constraint expressions (`~>`, `>=`, `=`, `!=`)
- Apply the core Terraform workflow: init → plan → apply → destroy
- Provision an EC2 instance and an SNS topic against LocalStack

## Background

### What is Terraform?

Terraform is an open-source Infrastructure as Code (IaC) tool made by HashiCorp. You describe
the desired state of your infrastructure in **HCL** (HashiCorp Configuration Language) files,
and Terraform calculates the difference between the current state and the desired state, then
makes the necessary API calls to close that gap.

```
main.tf  ──► terraform plan  ──► terraform apply  ──► real infrastructure
  (HCL)        (diff preview)      (API calls)         EC2, SNS, S3, ...
```

### HCL Basics

HCL is a declarative configuration language. You express *what* you want, not *how* to create it:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  tags = {
    Name = "my-server"
  }
}
```

### State Files

Terraform keeps a record of everything it has created in `terraform.tfstate`. This JSON file is
the source of truth that Terraform uses when deciding what to change or destroy. Never edit it
by hand. In team settings, store it in S3 (or Terraform Cloud) so everyone shares the same view.

### Providers

A **provider** is a plugin that teaches Terraform how to talk to a specific API. The AWS provider
translates HCL resources into AWS API calls. Providers are downloaded during `terraform init`
from the [Terraform Registry](https://registry.terraform.io/).

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Provider Version Constraints

Version constraints appear in `versions.tf` and control which provider versions Terraform will
accept. Pinning providers prevents unexpected breaking changes when a new provider version ships.

| Operator | Meaning | Example | Resolves to |
|----------|---------|---------|-------------|
| `~>` | Compatible with (pessimistic) | `~> 5.0` | `>= 5.0.0, < 6.0.0` |
| `~>` | Compatible with (patch only) | `~> 5.3.2` | `>= 5.3.2, < 5.4.0` |
| `>=` | Greater than or equal | `>= 5.0` | 5.0 or newer, any major |
| `=` | Exact pin | `= 5.3.1` | Only 5.3.1 |
| `!=` | Exclusion | `!= 5.2.0` | Anything except 5.2.0 |

**Recommended practice:** use `~> <major>.<minor>` (e.g. `~> 5.0`) to allow patch updates
automatically while protecting against major-version breaking changes.

You can combine constraints:

```hcl
version = ">= 5.0, != 5.2.0, < 6.0"
```

## Terraform Workflow

```
terraform init
  └─ Downloads provider plugins into .terraform/
  └─ Creates .terraform.lock.hcl (locks exact provider versions)

terraform plan
  └─ Compares desired state (HCL) with current state (tfstate)
  └─ Prints a human-readable diff — no changes are made

terraform apply
  └─ Executes the plan: creates, updates, or deletes resources
  └─ Updates terraform.tfstate

terraform destroy
  └─ Deletes all resources tracked in tfstate
  └─ Empties terraform.tfstate
```

## Repository Structure

```
lab-07-terraform-providers/
├── README.md
├── terraform/
│   ├── ec2-instance/
│   │   ├── versions.tf    # required_version + required_providers
│   │   ├── main.tf        # provider config + aws_instance resource
│   │   └── variables.tf   # ami, instance_type variables
│   └── sns-topic/
│       ├── versions.tf    # required_version + required_providers
│       └── main.tf        # provider config + aws_sns_topic resource
└── scripts/
    ├── 01-verify-terraform.sh
    ├── 02-provider-versions-demo.sh
    ├── 03-apply-ec2.sh
    ├── 04-apply-sns.sh
    └── cleanup.sh
```

## Scripts

Run each script in order:

```bash
cd lab-07-terraform-providers/

# 1. Verify Terraform is installed and explain what it does
bash scripts/01-verify-terraform.sh

# 2. Inspect versions.tf and learn the constraint operators
bash scripts/02-provider-versions-demo.sh

# 3. Init, plan, and apply the EC2 instance in LocalStack
bash scripts/03-apply-ec2.sh

# 4. Init, plan, and apply the SNS topic in LocalStack
bash scripts/04-apply-sns.sh

# Tear down all resources when done
bash scripts/cleanup.sh
```

### Script Details

| Script | What it does |
|--------|-------------|
| `01-verify-terraform.sh` | Checks `terraform` is in PATH, prints version, shows `--help`, explains core concepts |
| `02-provider-versions-demo.sh` | Cats `versions.tf`, explains `~>`, `>=`, `=`, `!=` with examples |
| `03-apply-ec2.sh` | `terraform init` → `plan` → `apply` in `terraform/ec2-instance/` |
| `04-apply-sns.sh` | `terraform init` → `plan` → `apply` in `terraform/sns-topic/` |
| `cleanup.sh` | `terraform destroy -auto-approve` in both directories; skips gracefully if no state |

## LocalStack vs Real AWS

All Terraform configs in this lab point to **LocalStack** (`http://localhost:4566`) instead of
real AWS. LocalStack is a local AWS emulator used for development and testing — no real resources
are created and no AWS charges are incurred.

The provider block uses dummy credentials and disables the checks that would normally require
real AWS credentials:

```hcl
provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    ec2 = "http://localhost:4566"
    sns = "http://localhost:4566"
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}
```

To switch to real AWS, remove the `endpoints` block and the `skip_*` flags, and supply your
credentials via environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or an
AWS credentials profile.

> **Note:** LocalStack must be running before executing scripts 03 or 04.
> Start it with: `docker run --rm -p 4566:4566 localstack/localstack`
