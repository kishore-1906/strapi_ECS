terraform {
  backend "s3" {
    bucket  = "state-bucket-54321"
    key     = "strapi/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    dynamodb_table = "strapi-terraform-lock"
  }
}

