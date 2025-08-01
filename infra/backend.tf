terraform {
  backend "s3" {
    bucket         = "3tier-terraform-state"     # Same as var.s3_backend_bucket
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "3tier-terraform-lock"      # Same as var.dynamodb_table
    encrypt        = true
  }
}
