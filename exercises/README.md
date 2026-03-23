# AWS Simulation Labs (LocalStack)

Hands-on labs that simulate real AWS workflows locally using [LocalStack](https://localstack.cloud/).
No AWS account required — everything runs in Docker.

## Prerequisites

All tools are pre-installed in the devcontainer (see root [README](../README.md)):
- Docker (via Docker-in-Docker feature)
- AWS CLI v2
- LocalStack CLI

## Start LocalStack

```bash
localstack start -d
localstack wait -t 30

# Verify it is healthy
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool
```

You should see `"s3": "running"`, `"ec2": "running"`, `"iam": "running"`, `"sts": "running"`.

## Labs

| Lab | Topic | What you learn |
|-----|-------|----------------|
| [lab-01-aws-environment](lab-01-aws-environment/README.md) | Creating an AWS Environment | VPC, subnets, S3, EC2 |
| [lab-02-access-keys-cli](lab-02-access-keys-cli/README.md) | Access Keys & AWS CLI | IAM users, programmatic access, key rotation |
| [lab-03-iam-security](lab-03-iam-security/README.md) | IAM & Security Configuration | Groups, policies, roles, least privilege |

Run the labs in order — later labs reference resources created earlier.

## Reset Everything

```bash
localstack stop   # stops the LocalStack container and removes all state
```

## LocalStack vs Real AWS

Scripts use `--endpoint-url=http://localhost:4566` to redirect all API calls to LocalStack
instead of real AWS. The CLI syntax, parameters, and responses are identical to real AWS.

Key differences to be aware of:
- EC2 instances are simulated (no actual compute runs)
- LocalStack free tier has partial IAM enforcement (policies are stored but not always enforced)
- S3 has no real internet access or ACL enforcement
- ARNs use `000000000000` as the account ID
