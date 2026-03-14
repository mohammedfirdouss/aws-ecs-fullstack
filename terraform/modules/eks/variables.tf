variable "project_name" {
  description = "Project name prefix for resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for node groups."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs included in the cluster VPC config (required for public ALBs via LBC)."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 6
}

variable "secret_arns" {
  description = "Secrets Manager ARN patterns the ESO IRSA role is allowed to read."
  type        = list(string)
  default     = []
}
