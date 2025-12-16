terraform {
  backend "s3" {
    bucket  = "strapi-terraform-state-301782007642"
    key     = "strapi/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

