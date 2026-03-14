output "ecs_cpu_alarm_arns" {
  description = "ARNs of the ECS CPU high alarms."
  value       = { for k, v in aws_cloudwatch_metric_alarm.ecs_cpu_high : k => v.arn }
}

output "unhealthy_hosts_alarm_arns" {
  description = "ARNs of the ALB unhealthy host alarms."
  value       = { for k, v in aws_cloudwatch_metric_alarm.unhealthy_hosts : k => v.arn }
}

output "rds_low_storage_alarm_arn" {
  description = "ARN of the RDS low storage alarm."
  value       = aws_cloudwatch_metric_alarm.rds_low_storage.arn
}
