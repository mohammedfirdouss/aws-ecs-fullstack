output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "backend_ecr_url" {
  description = "ECR repository URL for the backend image."
  value       = module.ecr.backend_repository_url
}

output "frontend_ecr_url" {
  description = "ECR repository URL for the frontend image."
  value       = module.ecr.frontend_repository_url
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "backend_service_name" {
  description = "ECS backend service name."
  value       = module.ecs.backend_service_name
}

output "frontend_service_name" {
  description = "ECS frontend service name."
  value       = module.ecs.frontend_service_name
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials."
  value       = module.rds.db_secret_arn
  sensitive   = true
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC."
  value       = module.iam.github_actions_role_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.networking.vpc_id
}
