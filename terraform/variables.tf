variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  default     = "strapi"
}

variable "image_uri" {
  description = "Full ECR image URI with tag"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alerts"
  type        = string
}

