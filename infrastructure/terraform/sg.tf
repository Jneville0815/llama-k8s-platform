data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

# Security group for K8s master node
resource "aws_security_group" "k8s_master" {
  name_prefix = "${var.repository_name}-k8s-master-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Kubernetes master node"

  # SSH access from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  ingress {
    description = "ICMP from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [local.vpc_cidr]
  }

  # Kubernetes API server
  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]  # Allow from VPC
  }

  # etcd server client API
  ingress {
    description = "etcd client API"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  # Kubelet API
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  # kube-scheduler
  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  # kube-controller-manager
  ingress {
    description = "kube-controller-manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.repository_name}-k8s-master"
    Type = "kubernetes-master"
  }
}

# Security group for K8s worker nodes
resource "aws_security_group" "k8s_worker" {
  name_prefix = "${var.repository_name}-k8s-worker-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Kubernetes worker nodes"

  ingress {
    description = "ICMP from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [local.vpc_cidr]
  }

  # Kubelet API
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  # NodePort Services
  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.repository_name}-k8s-worker"
    Type = "kubernetes-worker"
  }
}

# Security group for CNI plugin (Calico) - applied to all nodes
resource "aws_security_group" "k8s_cni" {
  name_prefix = "${var.repository_name}-k8s-cni-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Kubernetes CNI networking"

  # BGP (for Calico)
  ingress {
    description = "BGP for Calico"
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  # VXLAN (for Calico overlay)
  ingress {
    description = "VXLAN for Calico"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = [local.vpc_cidr]
  }

  # Typha (Calico)
  ingress {
    description = "Calico Typha"
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  tags = {
    Name = "${var.repository_name}-k8s-cni"
    Type = "kubernetes-cni"
  }
}