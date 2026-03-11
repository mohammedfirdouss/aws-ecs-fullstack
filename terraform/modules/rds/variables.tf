variable "project_name" {
  description = "Project name prefix for resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the RDS instance into."
  type        = string
}

variable "isolated_subnet_ids" {
  description = "List of isolated subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "allowed_sg_ids" {
  description = "Security group IDs allowed to reach port 5432."
  type        = list(string)
  default     = []
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "app"
}

variable "db_username" {
  description = "Master username for the DB."
  type        = string
  default     = "appuser"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB."
  type        = number
  default     = 20
}
