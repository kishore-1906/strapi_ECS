resource "aws_ecr_repository" "this" {
  name = "strapi-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

