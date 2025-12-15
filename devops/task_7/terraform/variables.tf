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

variable "vpc_id" {
  description = "VPC ID"
}

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

