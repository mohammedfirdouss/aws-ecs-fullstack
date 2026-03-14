output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_data" {
  description = "Base64-encoded cluster CA certificate."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_provider_arn" {
  description = "ARN of the cluster OIDC provider (for IRSA)."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "lbc_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller."
  value       = aws_iam_role.lbc.arn
}

output "eso_role_arn" {
  description = "IAM role ARN for the External Secrets Operator."
  value       = aws_iam_role.eso.arn
}

output "autoscaler_role_arn" {
  description = "IAM role ARN for the Cluster Autoscaler."
  value       = aws_iam_role.autoscaler.arn
}

output "node_role_arn" {
  description = "IAM role ARN for the managed node group."
  value       = aws_iam_role.node.arn
}
