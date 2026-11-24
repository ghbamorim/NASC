terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "NASC"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}