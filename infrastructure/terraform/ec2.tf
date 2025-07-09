# Create a new key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "${var.repository_name}-k8s-key"
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = {
    Name = "${var.repository_name}-k8s-key"
  }
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/k8s-private-key.pem"
  file_permission = "0600"
}

# K8s Master Node (Public Subnet)
resource "aws_instance" "k8s_master" {
  ami                    = local.ubuntu_ami_id
  instance_type          = "t3.medium"
  key_name              = aws_key_pair.k8s_key.key_name
  subnet_id             = module.vpc.public_subnets[0]
  iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name

  vpc_security_group_ids = [
    aws_security_group.k8s_master.id,
    aws_security_group.k8s_cni.id
  ]

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "${var.repository_name}-k8s-master"
    Type = "kubernetes-master"
    "kubernetes.io/cluster/${var.repository_name}" = "owned"
  }
}

# K8s Worker Node (Private Subnet)
resource "aws_instance" "k8s_worker" {
  ami                   = local.ubuntu_ami_id
  instance_type         = "t3.medium"
  key_name             = aws_key_pair.k8s_key.key_name
  subnet_id            = module.vpc.private_subnets[0]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  vpc_security_group_ids = [
    aws_security_group.k8s_worker.id,
    aws_security_group.k8s_cni.id
  ]

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "${var.repository_name}-k8s-worker"
    Type = "kubernetes-worker"
    "kubernetes.io/cluster/${var.repository_name}" = "owned"
  }
}

# K8s GPU Worker Node (Private Subnet)
resource "aws_instance" "k8s_gpu_worker" {
  ami                   = local.ubuntu_ami_id
  instance_type         = "g4dn.xlarge"
  key_name             = aws_key_pair.k8s_key.key_name
  subnet_id            = module.vpc.private_subnets[1]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  vpc_security_group_ids = [
    aws_security_group.k8s_worker.id,
    aws_security_group.k8s_cni.id
  ]

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 40  # Larger for GPU workloads
    encrypted   = true
  }

  tags = {
    Name = "${var.repository_name}-k8s-gpu-worker"
    Type = "kubernetes-gpu-worker"
    "kubernetes.io/cluster/${var.repository_name}" = "owned"
  }
}

# Elastic IP for master (optional but recommended)
resource "aws_eip" "master_eip" {
  instance = aws_instance.k8s_master.id
  domain   = "vpc"

  tags = {
    Name = "${var.repository_name}-master-eip"
  }

  depends_on = [aws_instance.k8s_master]
}