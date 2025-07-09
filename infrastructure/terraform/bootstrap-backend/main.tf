data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" // Stick with the 6.x family, but give me the latest patch/minor version
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      "source-repository" = var.repository_name
      "owner-email"       = "jimmyeneville@gmail.com"
    }
  }
}