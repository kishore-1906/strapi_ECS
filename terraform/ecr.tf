########################################
# EXISTING ECR REPOSITORY (DATA)
########################################
data "aws_ecr_repository" "this" {
  name = "strapi-repo"
}

