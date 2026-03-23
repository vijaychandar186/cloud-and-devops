# Lab 3 — IAM and Security Configuration

## Objectives

- Understand IAM users, groups, roles, and policies
- Create groups representing different access levels
- Write and attach IAM policies (managed and inline)
- Test what each group can and cannot do
- Create an IAM role with a trust policy for EC2

## IAM Concepts

| Concept | What it is |
|---------|-----------|
| **User** | A person or service with long-term credentials |
| **Group** | A collection of users — attach policies to groups, not individual users |
| **Policy** | A JSON document that allows or denies specific actions on specific resources |
| **Role** | Like a user but assumed temporarily — used by services (EC2, Lambda) or other accounts |
| **Trust policy** | Defines *who* can assume a role (the "who is allowed to wear this hat") |

**Managed policy** — standalone policy reusable across multiple principals, versioned.
**Inline policy** — embedded directly in a user/group/role, deleted when the principal is deleted.

## Team Structure Simulated

| User | Group | Policy | Can do |
|------|-------|--------|--------|
| alice | developers | EC2 Describe (inline) | Read EC2 resources |
| bob | read-only-auditors | S3 Read Only (managed) | Read S3 buckets |
| carol | admin | Admin (managed) | Everything |

## Scripts

```bash
cd lab-03-iam-security/

# 1. Create groups
bash scripts/01-create-groups.sh

# 2. Create users and assign to groups
bash scripts/02-create-users-assign-groups.sh

# 3. Create and attach policies
bash scripts/03-create-attach-policies.sh

# 4. Test permissions for each user
bash scripts/04-test-permissions.sh

# 5. Create an IAM role for EC2 (instance profile)
bash scripts/05-create-role.sh

# Tear down when done
bash scripts/cleanup.sh
```

## Real AWS Notes

> **Admin policy:** The policy in `policies/admin-policy.json` grants `Action: *` on
> `Resource: *` — unrestricted access to everything. In real AWS, reserve this ONLY
> for break-glass emergency accounts. Use the AWS-managed `AdministratorAccess` policy
> rather than a custom one — it is well-tested and audited.

> **Roles vs users for EC2:** In real AWS, never embed access keys inside EC2 instances.
> Instead attach an instance profile (a role). The EC2 metadata service at
> `http://169.254.169.254/latest/meta-data/iam/security-credentials/` vends temporary
> credentials that rotate automatically.

> **LocalStack IAM enforcement:** The free tier of LocalStack stores IAM resources but
> does not fully enforce permission denials. The `04-test-permissions.sh` script shows
> what real AWS behavior would be — use LocalStack Pro for strict enforcement.
