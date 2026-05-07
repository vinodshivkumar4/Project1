terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "vinod-devops-terraform-state" # Change to your created bucket
    key            = "assessment/nodejs-app.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock-table"        # Change to your created table
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}