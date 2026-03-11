output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics."
  value       = aws_lb.this.arn_suffix
}

output "alb_sg_id" {
  description = "Security group ID of the ALB."
  value       = aws_security_group.alb.id
}

output "backend_tg_arn" {
  description = "ARN of the backend target group."
  value       = aws_lb_target_group.backend.arn
}

output "frontend_tg_arn" {
  description = "ARN of the frontend target group."
  value       = aws_lb_target_group.frontend.arn
}

output "backend_tg_arn_suffix" {
  description = "Backend target group ARN suffix for CloudWatch metrics."
  value       = aws_lb_target_group.backend.arn_suffix
}

output "frontend_tg_arn_suffix" {
  description = "Frontend target group ARN suffix for CloudWatch metrics."
  value       = aws_lb_target_group.frontend.arn_suffix
}

output "alb_logs_bucket_id" {
  description = "S3 bucket ID for ALB access logs."
  value       = aws_s3_bucket.alb_logs.id
}
