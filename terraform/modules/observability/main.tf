# ── CloudWatch Log Groups ─────────────────────────────────────────────────────
# (Primary log groups are created by the ECS module; these are supplemental)

# ── ECS CPU Alarms ────────────────────────────────────────────────────────────

locals {
  ecs_services = {
    backend  = var.backend_service_name
    frontend = var.frontend_service_name
  }

  tg_suffixes = {
    backend  = var.backend_tg_arn_suffix
    frontend = var.frontend_tg_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = local.ecs_services

  alarm_name          = "${var.project_name}-${each.key}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS ${each.key} CPU utilization > 80% for 2 minutes."

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = each.value
  }

  tags = {
    Name = "${var.project_name}-${each.key}-cpu-high"
  }
}

# ── ALB Unhealthy Host Alarms ──────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  for_each = local.tg_suffixes

  alarm_name          = "${var.project_name}-${each.key}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "ALB ${each.key} target group has unhealthy hosts."

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = each.value
  }

  tags = {
    Name = "${var.project_name}-${each.key}-unhealthy-hosts"
  }
}

# ── RDS Free Storage Alarm ────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120 # 5 GB in bytes
  alarm_description   = "RDS free storage space is below 5 GB."

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = {
    Name = "${var.project_name}-rds-low-storage"
  }
}
