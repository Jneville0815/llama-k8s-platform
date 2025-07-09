terraform {
  backend "s3" {
    bucket         = "tfstate-llama-k8s-platform"
    key            = "tfstate-llama-k8s-platform/tfstate/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock-llama-k8s-platform"
  }
}