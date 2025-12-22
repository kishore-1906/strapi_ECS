output "alb_url" {
  description = "Public ALB DNS"
  value       = data.aws_lb.this.dns_name
}

