provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "resume_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_dynamodb_table" "resume_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S"
  }
}

resource "aws_db_instance" "mysql_instance" {
  identifier        = "job-app-db"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password
  skip_final_snapshot = true
  publicly_accessible = true
}

resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name

  user_data = file("user_data.sh")

  tags = {
    Name = "JobAppServer"
  }
}


