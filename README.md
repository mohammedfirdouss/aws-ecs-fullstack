# aws-ecs-fullstack

Production-ready AWS ECS deployment for a FastAPI + React/Vite + PostgreSQL stack, fully managed by Terraform and deployed via GitHub Actions.

## Architecture

```
Internet → ALB (HTTPS) → ECS Fargate
                            ├── Frontend (Nginx/React) — port 80
                            └── Backend  (FastAPI)     — port 8000  → RDS PostgreSQL (isolated subnets)
```

- **Networking**: VPC with public / private / isolated subnets across 3 AZs, NAT Gateways, VPC endpoints for ECR, S3, Secrets Manager, and CloudWatch Logs
- **Compute**: ECS Fargate with CPU + memory auto-scaling
- **Database**: RDS PostgreSQL 16 (encrypted, gp3, credentials in Secrets Manager)
- **TLS**: ACM certificate with DNS validation; HTTP→HTTPS 301 redirect
- **CI/CD**: GitHub Actions with OIDC (no long-lived AWS keys)
- **Observability**: CloudWatch alarms for CPU, unhealthy hosts, and RDS free storage

---

## Local Development

Run the full stack locally with Docker Compose — no AWS account needed:

```bash
docker compose up --build
```

| Service  | URL                        |
|----------|----------------------------|
| Frontend | http://localhost:5173       |
| Backend  | http://localhost:8000       |
| API docs | http://localhost:8000/docs  |
| Postgres | localhost:5432              |

Both backend and frontend support **hot reload** — edit files in `app/backend/app/` or `app/frontend/src/` and changes take effect immediately.

To reset the database volume:

```bash
docker compose down -v
```

---

## Prerequisites

- AWS CLI v2 + credentials with admin access (bootstrap only)
- Terraform `~> 1.9`
- Docker
- A registered domain (or use `example.com` as a placeholder — ACM cert validation will pend)
- A GitHub repository in your org

---

## First-Time Setup

### 1. Bootstrap state backend (manual, one-time)

Create the S3 bucket and DynamoDB table for Terraform state:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="tf-state-ecs-fullstack-${ACCOUNT_ID}"
REGION="us-east-1"

aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name tf-locks-ecs-fullstack \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}"
```

### 2. Update tfvars

Edit `terraform/terraform.tfvars` (and `terraform.prod.tfvars` for prod):

```hcl
github_org  = "your-org"
github_repo = "aws-ecs-fullstack"
domain_name = "your-domain.com"   # or leave as example.com
```

### 3. First apply (creates OIDC provider + roles)

```bash
cd terraform

terraform init \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="dynamodb_table=tf-locks-ecs-fullstack" \
  -backend-config="region=${REGION}"

terraform workspace select dev || terraform workspace new dev

terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

After the first apply, set `create_github_oidc_provider = false` to avoid conflicts on subsequent runs.

### 4. Populate GitHub Actions secrets

In your repo → Settings → Secrets and variables → Actions, add:

| Secret | Value |
|---|---|
| `AWS_ROLE_ARN` | Output of `terraform output github_actions_role_arn` |
| `AWS_REGION` | e.g. `us-east-1` |
| `TF_BACKEND_BUCKET` | The S3 bucket name from step 1 |
| `TF_BACKEND_DYNAMODB_TABLE` | `tf-locks-ecs-fullstack` |
| `BACKEND_ECR_REPO` | Output of `terraform output backend_ecr_url` (repo name only, without registry prefix) |
| `FRONTEND_ECR_REPO` | Output of `terraform output frontend_ecr_url` (repo name only) |

---

## Triggering the Pipeline

Push to `main`:

```bash
git push origin main
```

The pipeline will:
1. Build and push backend + frontend Docker images to ECR (parallel)
2. Run `terraform plan` then `terraform apply` in the `dev` workspace
3. Wait for ECS services to stabilize

To deploy to prod, trigger the workflow manually (Actions → "Build & Deploy" → Run workflow) and select workspace `prod`.

---

## Workspace Promotion: dev → prod

```bash
cd terraform
terraform workspace select prod || terraform workspace new prod
terraform plan -var-file=terraform.prod.tfvars
terraform apply -var-file=terraform.prod.tfvars
```

Prod differences (auto-applied via workspace locals):
- RDS: `db.t3.medium`, Multi-AZ enabled, deletion protection on
- ECS: larger CPU/memory, min 2 tasks per service
- Container Insights: enabled

---

## Verification

```bash
ALB=$(terraform output -raw alb_dns_name)

# HTTP → HTTPS redirect
curl -I "http://${ALB}"            # expect 301

# Frontend
curl -sk "https://${ALB}/"         # expect HTML

# Frontend health
curl -sk "https://${ALB}/health"   # expect: ok

# Backend API health (via ALB path rule)
curl -sk "https://${ALB}/api/health"  # expect: {"status":"ok"}

# ECS service status
aws ecs describe-services \
  --cluster $(terraform output -raw cluster_name) \
  --services \
    $(terraform output -raw backend_service_name) \
    $(terraform output -raw frontend_service_name) \
  --query 'services[*].{name:serviceName,desired:desiredCount,running:runningCount}'
```

---

## Teardown

```bash
cd terraform

# Dev (deletion_protection = false, no final snapshot)
terraform workspace select dev
terraform destroy -var-file=terraform.tfvars

# Prod (requires disabling deletion protection first)
terraform workspace select prod
# Manually set deletion_protection=false in RDS console, then:
terraform destroy -var-file=terraform.prod.tfvars
```

> **Note**: ECR repositories have `force_delete` disabled by default. Empty them before destroy, or add `force_delete = true` to the ECR module for non-prod.
