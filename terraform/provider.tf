terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"

  # S3 Backend for remote state storage
  # All values are provided via -backend-config flags during terraform init
  # Example: terraform init -backend-config="bucket=your-bucket" -backend-config="key=path/to/state" -backend-config="region=ap-south-1"
  backend "s3" {
    # Configured via -backend-config in CI/CD or local init
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
