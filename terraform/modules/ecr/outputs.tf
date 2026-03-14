output "backend_repository_url" {
  description = "ECR repository URL for the backend."
  value       = aws_ecr_repository.this["backend"].repository_url
}

output "frontend_repository_url" {
  description = "ECR repository URL for the frontend."
  value       = aws_ecr_repository.this["frontend"].repository_url
}

output "registry_id" {
  description = "ECR registry ID (AWS account ID)."
  value       = aws_ecr_repository.this["backend"].registry_id
}
