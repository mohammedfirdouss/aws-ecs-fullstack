variable "project_name" {
  description = "Project name prefix for resource names."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name."
  type        = string
}

variable "backend_service_name" {
  description = "ECS backend service name."
  type        = string
}

variable "frontend_service_name" {
  description = "ECS frontend service name."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics."
  type        = string
}

variable "backend_tg_arn_suffix" {
  description = "Backend target group ARN suffix for CloudWatch metrics."
  type        = string
}

variable "frontend_tg_arn_suffix" {
  description = "Frontend target group ARN suffix for CloudWatch metrics."
  type        = string
}

variable "db_instance_id" {
  description = "RDS instance identifier for CloudWatch metrics."
  type        = string
}
