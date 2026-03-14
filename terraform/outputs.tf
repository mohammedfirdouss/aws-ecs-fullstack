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

output "eks_cluster_name" {
  description = "EKS cluster name (empty if enable_eks = false)."
  value       = var.enable_eks ? module.eks[0].cluster_name : ""
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : ""
}

output "eks_lbc_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller."
  value       = var.enable_eks ? module.eks[0].lbc_role_arn : ""
}

output "eks_eso_role_arn" {
  description = "IAM role ARN for the External Secrets Operator."
  value       = var.enable_eks ? module.eks[0].eso_role_arn : ""
}

output "eks_autoscaler_role_arn" {
  description = "IAM role ARN for the Cluster Autoscaler."
  value       = var.enable_eks ? module.eks[0].autoscaler_role_arn : ""
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA."
  value       = var.enable_eks ? module.eks[0].cluster_oidc_provider_arn : ""
}
