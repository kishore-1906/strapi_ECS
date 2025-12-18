resource "aws_sns_topic" "ecs_alerts" {
  name = "ecs-strapi-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.ecs_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

