variable "project_name" {
  description = "Project name prefix for resource names."
  type        = string
}

variable "secret_arns" {
  description = "List of Secrets Manager ARNs that ECS tasks are allowed to read."
  type        = list(string)
  default     = []
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false after the first apply."
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub organisation name."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
}
