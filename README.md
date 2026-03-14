# aws-ecs-fullstack

Production-ready AWS infrastructure for a FastAPI + React/Vite + PostgreSQL stack. Supports two deployment targets — **ECS Fargate** (default, simpler) and **EKS** (Kubernetes, production-scale) — both fully managed by Terraform and deployed via GitHub Actions with OIDC.

## Architecture

### ECS (default)
```
Internet → ALB (HTTPS) → ECS Fargate
                            ├── Frontend (Nginx/React) — port 80
                            └── Backend  (FastAPI)     — port 8000  → RDS PostgreSQL
```

### EKS (`enable_eks = true`)
```
Internet → ALB (HTTPS, via LBC) → EKS Managed Node Group
                                      ├── frontend pods  (Nginx/React)
                                      └── backend pods   (FastAPI)  → RDS PostgreSQL
                                                                        ↑
                                              External Secrets Operator syncs
                                              Secrets Manager → K8s secrets
```

| Component | ECS | EKS |
|---|---|---|
| Compute | Fargate (serverless) | Managed node group (EC2) |
| Scaling | App Autoscaling (CPU/mem) | HPA + Cluster Autoscaler |
| Secrets | Secrets Manager `::key::` injection | External Secrets Operator |
| Ingress | ALB (Terraform-managed) | ALB via AWS Load Balancer Controller |
| Packaging | Task definitions | Helm chart (`helm/fullstack/`) |
| Deploy workflow | `deploy.yml` | `deploy-eks.yml` |

**Shared across both:**
- VPC — 3 AZs, public / private / isolated subnets, NAT Gateways, VPC endpoints
- ECR — immutable image tags, lifecycle policies
- RDS PostgreSQL 16 — encrypted gp3, Secrets Manager, Multi-AZ in prod
- ACM certificate — DNS validation, HTTP→HTTPS redirect
- IAM — OIDC for GitHub Actions (no long-lived keys)
- CloudWatch — alarms for CPU, unhealthy hosts, RDS free storage

---

## Using the fastapi/full-stack-fastapi-template

The infrastructure is wired for the [fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template). To replace the stubs with the real app:

```bash
git clone https://github.com/fastapi/full-stack-fastapi-template _template

cp -r _template/backend/*      app/backend/
cp    _template/uv.lock        app/
cp    _template/pyproject.toml app/

cp -r _template/frontend/*     app/frontend/
cp    _template/bun.lock       app/
cp    _template/package.json   app/

rm -rf _template
```

The Dockerfiles, docker-compose, and Terraform are already configured for the template's env var names (`POSTGRES_SERVER`, `SECRET_KEY`, etc.) — no further infra changes needed.

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
- A registered domain (or use `example.com` as a placeholder — ACM cert will pend validation)
- A GitHub repository in your org
- **EKS only:** `kubectl` and `helm` (v3)

---

## First-Time Setup

### 1. Bootstrap state backend (manual, one-time)

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

Edit `terraform/terraform.tfvars`:

```hcl
github_org  = "your-org"
github_repo = "aws-ecs-fullstack"
domain_name = "your-domain.com"

# Set true to also provision an EKS cluster
enable_eks = false
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

After the first apply, set `create_github_oidc_provider = false` to avoid conflicts on re-runs.

### 4. Populate GitHub Actions secrets

In your repo → Settings → Secrets and variables → Actions:

| Secret | Value | Required for |
|---|---|---|
| `AWS_ROLE_ARN` | `terraform output github_actions_role_arn` | ECS + EKS |
| `AWS_REGION` | e.g. `us-east-1` | ECS + EKS |
| `TF_BACKEND_BUCKET` | S3 bucket name from step 1 | ECS + EKS |
| `TF_BACKEND_DYNAMODB_TABLE` | `tf-locks-ecs-fullstack` | ECS + EKS |
| `BACKEND_ECR_REPO` | `terraform output backend_ecr_url` (repo name only) | ECS + EKS |
| `FRONTEND_ECR_REPO` | `terraform output frontend_ecr_url` (repo name only) | ECS + EKS |
| `DOMAIN_NAME` | Your domain — baked into frontend as `VITE_API_URL` | ECS + EKS |
| `ACM_CERT_ARN` | ACM certificate ARN for the ALB Ingress | EKS only |
| `PROJECT_NAME` | Value of `project_name` in tfvars (e.g. `ecs-fullstack`) | EKS only |

---

## Deploying

### ECS (push to main)

```bash
git push origin main
```

The `deploy.yml` pipeline will:
1. Build and push backend + frontend images to ECR (parallel)
2. `terraform plan` + `terraform apply` in the `dev` workspace
3. Wait for ECS services to stabilize (`aws ecs wait services-stable`)

### EKS (manual trigger)

Go to **Actions → Build & Deploy (EKS) → Run workflow**, select `dev` or `prod`.

The `deploy-eks.yml` pipeline will:
1. Build and push images (parallel)
2. `terraform apply` with `TF_VAR_enable_eks=true`
3. Helm install: AWS Load Balancer Controller, External Secrets Operator, metrics-server, Cluster Autoscaler
4. Helm upgrade the `fullstack` chart
5. `kubectl rollout status` for both deployments

---

## Workspace Promotion: dev → prod

```bash
cd terraform
terraform workspace select prod || terraform workspace new prod
terraform plan -var-file=terraform.prod.tfvars
terraform apply -var-file=terraform.prod.tfvars
```

Prod differences (applied automatically via workspace locals):

| | dev | prod |
|---|---|---|
| RDS instance | `db.t3.micro` | `db.t3.medium` + Multi-AZ |
| ECS tasks | 512 CPU / 1024 MB, min 1 | 1024 CPU / 2048 MB, min 2 |
| EKS nodes | 2× `t3.medium` SPOT | 3× `t3.large` ON_DEMAND (max 6) |
| Container Insights | off | on |
| RDS deletion protection | off | on |

---

## Verification

### ECS

```bash
ALB=$(cd terraform && terraform output -raw alb_dns_name)

curl -I "http://${ALB}"                    # expect 301
curl -sk "https://${ALB}/health"           # expect: ok
curl -sk "https://${ALB}/api/v1/utils/health-check/"  # expect: {"status":"ok"}

aws ecs describe-services \
  --cluster $(terraform output -raw cluster_name) \
  --services \
    $(terraform output -raw backend_service_name) \
    $(terraform output -raw frontend_service_name) \
  --query 'services[*].{name:serviceName,desired:desiredCount,running:runningCount}'
```

### EKS

```bash
aws eks update-kubeconfig \
  --name $(cd terraform && terraform output -raw eks_cluster_name) \
  --region us-east-1

kubectl get nodes
kubectl get pods -n fullstack
kubectl get ingress -n fullstack       # shows ALB DNS
kubectl get externalsecret -n fullstack  # should show READY=True
```

---

## Teardown

### ECS

```bash
cd terraform
terraform workspace select dev
terraform destroy -var-file=terraform.tfvars
```

### EKS

```bash
# Uninstall Helm releases first (removes ALB + target groups from AWS)
helm uninstall fullstack              -n fullstack
helm uninstall aws-load-balancer-controller -n kube-system
helm uninstall external-secrets       -n external-secrets
helm uninstall cluster-autoscaler     -n kube-system

# Then destroy infra
cd terraform
terraform workspace select dev
terraform destroy -var-file=terraform.tfvars
```

### Prod

Prod has `deletion_protection = true` on RDS. Disable it in the AWS console first, then run `terraform destroy -var-file=terraform.prod.tfvars`.

> **Note**: ECR repositories are not force-deleted by default. Empty them before destroy, or add `force_delete = true` to the ECR module for non-prod.
