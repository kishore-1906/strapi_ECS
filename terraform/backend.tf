terraform {
  backend "s3" {
    bucket  = "kishore-strapi-bucket"
    key     = "strapi/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

