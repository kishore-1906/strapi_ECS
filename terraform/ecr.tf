########################################
# EXISTING ECR REPOSITORY (DATA)
########################################
resource "aws_ecr_repository" "this" {
  name = "strapi-repo"
}

