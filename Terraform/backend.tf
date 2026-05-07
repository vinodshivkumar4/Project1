terraform {
  backend "s3" {
    bucket         = "vinod-devops-terraform-state" 
    key            = "state/terraform.tfstate"
    region         = "us-east-1" # <--- MAKE SURE THIS MATCHES YOUR ACTUAL BUCKET REGION
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}