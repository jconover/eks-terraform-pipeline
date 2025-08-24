terraform {
  backend "s3" {
    bucket         = "eks-terraform-state-bucket-123"
    key            = "eks/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
