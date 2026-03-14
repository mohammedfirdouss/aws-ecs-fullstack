variable "project_name" {
  description = "Project name prefix for resource names."
  type        = string
}

variable "aws_region" {
  description = "AWS region (used for CloudWatch log group ARN construction)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID of the ALB (used for ingress rules)."
  type        = string
}

variable "backend_tg_arn" {
  description = "Target group ARN for the backend ECS service."
  type        = string
}

variable "frontend_tg_arn" {
  description = "Target group ARN for the frontend ECS service."
  type        = string
}

variable "task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution."
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN for ECS tasks (app permissions)."
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials (POSTGRES_* keys)."
  type        = string
}

variable "app_secret_arn" {
  description = "Secrets Manager ARN for app secrets (SECRET_KEY, FIRST_SUPERUSER, etc.)."
  type        = string
}

variable "domain_name" {
  description = "Domain name injected into DOMAIN and BACKEND_CORS_ORIGINS env vars."
  type        = string
}

variable "backend_image" {
  description = "Docker image URI for the backend."
  type        = string
}

variable "frontend_image" {
  description = "Docker image URI for the frontend."
  type        = string
}

variable "backend_cpu" {
  description = "CPU units for the backend task."
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory (MiB) for the backend task."
  type        = number
  default     = 1024
}

variable "frontend_cpu" {
  description = "CPU units for the frontend task."
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory (MiB) for the frontend task."
  type        = number
  default     = 512
}

variable "backend_min_capacity" {
  description = "Minimum number of backend tasks."
  type        = number
  default     = 1
}

variable "backend_max_capacity" {
  description = "Maximum number of backend tasks."
  type        = number
  default     = 3
}

variable "frontend_min_capacity" {
  description = "Minimum number of frontend tasks."
  type        = number
  default     = 1
}

variable "frontend_max_capacity" {
  description = "Maximum number of frontend tasks."
  type        = number
  default     = 2
}

variable "container_insights" {
  description = "Enable ECS Container Insights."
  type        = bool
  default     = false
}
