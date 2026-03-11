variable "project_name" {
  description = "Project name prefix for resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the ALB into."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB."
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for the ACM certificate (e.g. example.com)."
  type        = string
}
