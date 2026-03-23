# cloud-and-devops

Hands-on cloud and DevOps labs using local emulators — no cloud account required.

## Devcontainer Setup

This repo is designed to run inside a **VS Code devcontainer**. The devcontainer includes:

- **Docker-in-Docker** — needed by LocalStack
- **AWS CLI v2** — used by all lab scripts
- **LocalStack CLI** — local AWS emulator
- **Azure CLI** + **Azurite** — local Azure storage emulator

### Getting Started

1. Open this repo in VS Code
2. When prompted, click **"Reopen in Container"** (or run `Dev Containers: Rebuild and Reopen in Container` from the command palette)
3. Wait for the container to build (first time takes a few minutes)
4. Create your local environment file (tracked by `.gitignore`, never committed):

```bash
cp exercises/.env.example exercises/.env
```

The defaults in `.env.example` are pre-configured for LocalStack and work out of the box — no edits needed unless you switch to real AWS credentials.

## AWS Labs (LocalStack)

Fifteen labs covering AWS, Linux, Terraform, Ansible, Docker, Kubernetes, and CI/CD — Labs 01, 02, 03, 06, 07, and 15 use [LocalStack](https://localstack.cloud/) to simulate AWS locally. All other labs run entirely in the devcontainer with no cloud account required.

### Start LocalStack

```bash
localstack start -d
localstack wait -t 30   # wait until ready
```

Verify it's healthy:

```bash
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool
```

### Labs

| Lab | Topic | What you learn |
|-----|-------|----------------|
| [lab-01](exercises/lab-01-aws-environment/) | Creating an AWS Environment | VPC, subnets, S3, EC2 |
| [lab-02](exercises/lab-02-access-keys-cli/) | Access Keys & AWS CLI | IAM users, programmatic access, key rotation |
| [lab-03](exercises/lab-03-iam-security/) | IAM & Security Configuration | Groups, policies, roles, least privilege |
| [lab-04](exercises/lab-04-linux-installation/) | Installation of Linux | Ubuntu install on VMware, post-install config, filesystem layout |
| [lab-05](exercises/lab-05-linux-commands-scripting/) | Linux Commands & Shell Scripting | Navigation, variables, redirection, pipes, Bash scripting |
| [lab-06](exercises/lab-06-ec2-shell-config/) | EC2 Instance Creation & Shell Config | Key pairs, security groups, user data, .bashrc, systemctl |
| [lab-07](exercises/lab-07-terraform-providers/) | Terraform Setup & Provider Versioning | HCL, init/plan/apply/destroy workflow, version constraints |
| [lab-08](exercises/lab-08-ansible-setup/) | Installing Ansible | Inventory, modules, playbooks, ad-hoc commands, Jinja2 templates |
| [lab-09](exercises/lab-09-ansible-roles/) | Ansible Roles | Role directory structure, defaults, handlers, Galaxy, idempotency |
| [lab-10](exercises/lab-10-docker/) | Installing Docker with Configuration | Images, containers, Dockerfile, build, run, inspect, logs |
| [lab-11](exercises/lab-11-kubernetes-deployment/) | Kubernetes Deployment | kind cluster, kubectl, Deployments, Services, port-forward |
| [lab-12](exercises/lab-12-kubernetes-manifests/) | Kubernetes without Helm | YAML manifests, Namespaces, ConfigMaps, rolling updates, scaling |
| [lab-13](exercises/lab-13-cicd-tools/) | Git, Gradle, Maven & Jenkins | Version control, Java builds, unit tests, Jenkins pipeline |
| [lab-14](exercises/lab-14-devops-pipeline/) | Mini Project — DevOps Pipeline | Docker build, unit tests, smoke test, container deploy, health check |
| [lab-15](exercises/lab-15-final-project/) | Final Mini Project | Terraform (LocalStack), Docker, Kubernetes (kind), end-to-end pipeline |

Run labs in order. Each lab has numbered scripts in its `scripts/` folder:

```bash
# Example: run Lab 01 step by step
bash exercises/lab-01-aws-environment/scripts/01-create-vpc.sh
bash exercises/lab-01-aws-environment/scripts/02-create-s3-bucket.sh
bash exercises/lab-01-aws-environment/scripts/03-create-ec2-keypair.sh
bash exercises/lab-01-aws-environment/scripts/04-launch-ec2-instance.sh
bash exercises/lab-01-aws-environment/scripts/05-verify-environment.sh

# Clean up when done
bash exercises/lab-01-aws-environment/scripts/cleanup.sh
```

### Reset LocalStack

```bash
localstack stop    # stops and removes all state
localstack start -d
```

### LocalStack vs Real AWS

Scripts use `--endpoint-url=http://localhost:4566` (via the `awslocal` wrapper in `.env`) to redirect API calls to LocalStack. CLI syntax and responses are identical to real AWS.

Key differences:
- EC2 instances are simulated (no actual compute)
- IAM policies are stored but not always enforced (free tier)
- S3 has no real internet access or ACL enforcement
- ARNs use `000000000000` as the account ID

## Using Real AWS Instead of LocalStack

All lab scripts default to LocalStack (`--endpoint-url=http://localhost:4566`). To run against a real AWS account:

### 1. Configure your credentials

```bash
aws configure
# Enter: AWS Access Key ID, Secret Access Key, default region (e.g. us-east-1), output format (json)
```

Or use a named profile:

```bash
aws configure --profile myprofile
export AWS_PROFILE=myprofile
```

### 2. Remove the LocalStack endpoint flag

Each script passes `--endpoint-url=http://localhost:4566` to every AWS CLI call. Either:

- **Edit the scripts** — remove or comment out the `--endpoint-url` flag, or
- **Run commands manually** — use the same AWS CLI commands without the flag

### 3. Costs and cleanup

Real AWS resources incur charges. Always run the `cleanup.sh` script after finishing a lab:

```bash
bash exercises/lab-01-aws-environment/scripts/cleanup.sh
bash exercises/lab-02-access-keys-cli/scripts/cleanup.sh
bash exercises/lab-03-iam-security/scripts/cleanup.sh
# Lab 04 and 05 create no AWS resources — no cleanup needed
bash exercises/lab-06-ec2-shell-config/scripts/cleanup.sh
bash exercises/lab-07-terraform-providers/scripts/cleanup.sh
# Lab 08 and 09 create no AWS resources — no cleanup needed
# Lab 10, 11, and 12 create no AWS resources — see each lab's cleanup.sh
# Lab 13 and 14 create no AWS resources — see each lab's cleanup.sh
bash exercises/lab-15-final-project/scripts/cleanup.sh
```

### 4. IAM permissions required

Your AWS credentials need permission to create the resources each lab uses:

| Lab | Required permissions |
|-----|----------------------|
| Lab 01 | `ec2:*`, `s3:*` |
| Lab 02 | `iam:CreateUser`, `iam:CreateAccessKey`, `iam:DeleteUser`, `iam:DeleteAccessKey` |
| Lab 03 | `iam:*` |
| Lab 04 | None (no AWS resources) |
| Lab 05 | None (no AWS resources) |
| Lab 06 | `ec2:CreateKeyPair`, `ec2:DeleteKeyPair`, `ec2:CreateSecurityGroup`, `ec2:DeleteSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:RunInstances`, `ec2:TerminateInstances`, `ec2:DescribeInstances` |
| Lab 07 | `ec2:RunInstances`, `ec2:TerminateInstances`, `ec2:DescribeInstances`, `sns:CreateTopic`, `sns:DeleteTopic` |
| Lab 08 | None (no AWS resources) |
| Lab 09 | None (no AWS resources) |
| Lab 10 | None (no AWS resources) |
| Lab 11 | None (no AWS resources) |
| Lab 12 | None (no AWS resources) |
| Lab 13 | None (no AWS resources) |
| Lab 14 | None (no AWS resources) |
| Lab 15 | `s3:CreateBucket`, `s3:PutObject`, `s3:ListBucket`, `sns:CreateTopic`, `sns:DeleteTopic` |

### Real AWS vs LocalStack differences

| Behaviour | LocalStack | Real AWS |
|-----------|-----------|----------|
| EC2 instances | Simulated (no compute) | Real VMs, billed by the hour |
| IAM enforcement | Partial (free tier) | Fully enforced |
| Account ID | `000000000000` | Your 12-digit account ID |
| Internet access | None | Full |
| Cost | Free | Pay-as-you-go |