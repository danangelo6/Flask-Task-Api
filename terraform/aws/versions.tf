terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Exercise: move state to S3 + DynamoDB/S3 locking, then uncomment and run `terraform init -migrate-state`
  # backend "s3" {
  #   bucket = "YOUR-STATE-BUCKET"
  #   key    = "devops-lab/terraform.tfstate"
  #   region = "ap-southeast-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}
