# Lab 2 — Creating Access Keys and Setting Up AWS CLI

## Objectives

- Create an IAM user for programmatic access
- Generate access keys (Access Key ID + Secret Access Key)
- Configure a named AWS CLI profile
- Verify identity using `sts get-caller-identity`
- Rotate access keys (security best practice)

## Background

AWS has two types of credentials:

| Type | Used for | Risk if leaked |
|------|----------|----------------|
| Root account | AWS console sign-in | Catastrophic — full account access |
| IAM access keys | Programmatic (CLI/SDK) | High — scoped to IAM user's permissions |

**Never create root access keys.** Always create an IAM user and grant only the
permissions that user needs (least privilege principle).

Access keys consist of two parts:
- **Access Key ID** — like a username, not secret (e.g., `AKIAIOSFODNN7EXAMPLE`)
- **Secret Access Key** — like a password, shown **only once** at creation

## Scripts

```bash
cd lab-02-access-keys-cli/

# 1. Create an IAM user
bash scripts/01-create-iam-user.sh

# 2. Generate access keys for that user
bash scripts/02-create-access-keys.sh

# 3. Configure a named AWS CLI profile
bash scripts/03-configure-aws-profile.sh

# 4. Verify identity (the "am I authenticated?" check)
bash scripts/04-verify-identity.sh

# 5. Rotate the access keys (security best practice)
bash scripts/05-rotate-access-keys.sh

# Tear down when done
bash scripts/cleanup.sh
```

## Real AWS Notes

> **Access Key visibility:** In the real AWS console, the Secret Access Key is shown
> only once after creation. You can download a CSV at that moment — after navigating
> away, the secret is gone and cannot be retrieved. Script 02 simulates this.

> **Key rotation:** AWS recommends rotating access keys every 90 days. Script 05
> walks through the safe rotation process: create new → update consumers → deactivate
> old → verify → delete old.

> **Why not use root keys?** The root account has unrestricted access to everything,
> including billing. A leaked root key can mean financial ruin in addition to data loss.

> **Named profiles:** `~/.aws/credentials` and `~/.aws/config` can hold multiple profiles.
> Switch between them with `--profile <name>` or `AWS_PROFILE=<name>`.
