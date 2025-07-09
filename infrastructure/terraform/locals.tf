locals {
  my_ip          = "${chomp(data.http.my_ip.response_body)}/32"
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = data.aws_region.current.id
  ubuntu_ami_id  = "ami-020cba7c55df1f615"

  vpc_cidr = "10.10.0.0/16"
  azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets = [
    cidrsubnet(local.vpc_cidr, 4, 0), # 10.10.0.0/20
    cidrsubnet(local.vpc_cidr, 4, 1), # 10.10.16.0/20
    cidrsubnet(local.vpc_cidr, 4, 2), # 10.10.32.0/20
  ]

  private_subnets = [
    cidrsubnet(local.vpc_cidr, 4, 8),  # 10.10.128.0/20
    cidrsubnet(local.vpc_cidr, 4, 9),  # 10.10.144.0/20
    cidrsubnet(local.vpc_cidr, 4, 10), # 10.10.160.0/20
  ]

  user_data = templatefile("${path.module}/scripts/user-data.sh", {
    hostname_prefix = var.repository_name
  })
}