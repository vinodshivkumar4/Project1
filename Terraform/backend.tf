terraform {
  backend "s3" {
    bucket         = "vinod-devops-terraform-state" # Ensure this bucket exists in AWS
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"        # Ensure this table exists in AWS
    encrypt        = true
  }
}