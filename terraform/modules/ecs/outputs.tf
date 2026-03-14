output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = aws_ecs_cluster.this.arn
}

output "backend_service_name" {
  description = "ECS backend service name."
  value       = aws_ecs_service.backend.name
}

output "frontend_service_name" {
  description = "ECS frontend service name."
  value       = aws_ecs_service.frontend.name
}

output "backend_sg_id" {
  description = "Security group ID for the backend ECS tasks."
  value       = aws_security_group.backend.id
}

output "frontend_sg_id" {
  description = "Security group ID for the frontend ECS tasks."
  value       = aws_security_group.frontend.id
}
