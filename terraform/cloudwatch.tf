########################################
# CLOUDWATCH LOG GROUP (REQUIRED FOR ECS)
########################################
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ecs-logs"
  }
}

########################################
# ECS CPU HIGH ALARM
########################################
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "ecs-${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Triggers when ECS CPU usage exceeds 70%"

  alarm_actions = []

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.this.name
  }
}

########################################
# ECS MEMORY HIGH ALARM
########################################
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "ecs-${var.project_name}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Triggers when ECS memory usage exceeds 75%"

  alarm_actions = []

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.this.name
  }
}

