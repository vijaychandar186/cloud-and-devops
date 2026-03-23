# Lab 16 — Terraform Hybrid Multi-Vendor (LocalStack + Azurite)

## Objectives

- Use Terraform to provision AWS-style resources against LocalStack
- Use Terraform to orchestrate Azure Storage operations against Azurite
- Simulate a small hybrid setup that spans two local cloud emulators
- Understand the difference between native Terraform providers and emulator-driven workflows

## Background

This lab creates a simple "multi-vendor" local environment:

- **AWS / LocalStack**
  - S3 bucket
  - S3 object containing a shared manifest
  - SNS topic
- **Azure / Azurite**
  - Blob container
  - Blob upload of the same shared manifest

The idea is to model a common hybrid pattern:

- AWS-style services handle app artifacts and messaging
- Azure-style blob storage holds a copy of the same deployment metadata

## Important Azure Limitation

Azurite is an **Azure Storage emulator**, not a full Azure Resource Manager emulator.
Because of that, the `azurerm` provider cannot create Azure resources in Azurite the way
the `aws` provider can create resources in LocalStack.

This lab handles that limitation intentionally:

- Terraform uses the **AWS provider** directly for LocalStack resources
- Terraform uses **`local_file` + `null_resource` + Azure CLI** to create the Azurite
  container and upload a blob through the storage data plane

That still gives you one Terraform workflow for both sides, while staying honest about
what the emulators can and cannot do.

## Repository Structure

```text
lab-16-hybrid-multi-vendor/
├── README.md
├── scripts/
│   ├── 01-verify-emulators.sh
│   ├── 02-apply.sh
│   └── 03-destroy.sh
└── terraform/
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    └── versions.tf
```

## Prerequisites

- Open the repo in the devcontainer
- Start LocalStack
- Make sure the Azurite service from `.devcontainer/docker-compose.yaml` is running

## Scripts

```bash
cd lab-16-hybrid-multi-vendor/

# 1. Verify LocalStack and Azurite are reachable
bash scripts/01-verify-emulators.sh

# 2. Init, plan, and apply the hybrid example
bash scripts/02-apply.sh

# 3. Tear everything down
bash scripts/03-destroy.sh
```

## What Terraform Creates

### LocalStack

- `aws_s3_bucket.artifacts`
- `aws_s3_object.hybrid_manifest`
- `aws_sns_topic.notifications`

### Azurite

- Blob container named `lab16-hybrid-artifacts`
- Blob named `hybrid-manifest.json`

## Notes

- The shared manifest is written locally by Terraform first, then uploaded to both S3
  (LocalStack) and Blob Storage (Azurite).
- The Azurite connection string defaults to the devcontainer's built-in emulator value.
- The Azure CLI config directory is redirected into the lab folder so the commands do not
  try to write under a read-only home directory.
- The lab pins `AZURE_STORAGE_API_VERSION` to `2023-11-03` so newer Azure CLI releases remain
  compatible with Azurite.
- The Azurite connection string is stored in local Terraform state because it is passed
  through a `null_resource` trigger. That is acceptable for this local-only lab, but you
  would avoid that pattern in production.
