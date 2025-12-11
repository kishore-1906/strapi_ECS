terraform {
  backend "s3" {
    bucket         = "jobapp-resume-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "jobapp-db"
  }
}

