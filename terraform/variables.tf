variable "aws_region" {
  description = "AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used to prefix resource names."
  type        = string
  default     = "ecs-fullstack"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "backend_image" {
  description = "Fully-qualified ECR image URI for the backend (injected by CI)."
  type        = string
  default     = ""
}

variable "frontend_image" {
  description = "Fully-qualified ECR image URI for the frontend (injected by CI)."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Root domain name used for the ACM certificate and ALB listener."
  type        = string
  default     = "example.com"
}

variable "github_org" {
  description = "GitHub organisation name for the OIDC trust policy."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name for the OIDC trust policy."
  type        = string
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false after the first apply to avoid conflicts."
  type        = bool
  default     = true
}

variable "container_insights_enabled" {
  description = "Enable ECS Container Insights (additional CloudWatch cost)."
  type        = bool
  default     = false
}

variable "first_superuser" {
  description = "Email address for the initial admin superuser."
  type        = string
  default     = "admin@example.com"
}

variable "first_superuser_password" {
  description = "Password for the initial admin superuser."
  type        = string
  sensitive   = true
}

variable "enable_eks" {
  description = "Provision an EKS cluster alongside (or instead of) ECS."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}
