#!/bin/bash

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install basic tools (needed for K8s and general management)
apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    unzip \
    htop \
    vim

# Install AWS CLI v2 (useful for S3, SSM, other AWS services)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install SSM Agent (enables 'aws ssm start-session' access)
# Usually pre-installed on Ubuntu 22.04, but ensure it's running
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

echo "Waiting for network..."
attempt=1
while [ $attempt -le 30 ]; do
    if curl -s --max-time 5 http://169.254.169.254/latest/meta-data/ >/dev/null 2>&1; then
        echo "Network ready"
        break
    fi
    sleep 10
    attempt=$((attempt + 1))
done

# Get metadata using IMDSv2 tokens
get_metadata() {
    local path=$1
    local token=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --max-time 5 2>/dev/null)
    if [ -n "$token" ]; then
        curl -H "X-aws-ec2-metadata-token: $token" "http://169.254.169.254/latest/meta-data/$path" --max-time 5 2>/dev/null
    else
        # Fallback to IMDSv1 if token fails
        curl -s "http://169.254.169.254/latest/meta-data/$path" --max-time 5 2>/dev/null
    fi
}

# Set hostname based on instance type (helps identify nodes)
INSTANCE_TYPE=$(get_metadata "instance-type")
INSTANCE_ID=$(get_metadata "instance-id")

if [[ $INSTANCE_TYPE == *"g4dn"* ]]; then
    hostnamectl set-hostname "${hostname_prefix}-gpu-worker"
elif [[ $INSTANCE_TYPE == "t3.medium" ]]; then
    # We'll distinguish master vs worker in Phase 2
    hostnamectl set-hostname "${hostname_prefix}-node-$INSTANCE_ID"
fi

# Add hostname to /etc/hosts (prevents hostname resolution issues)
echo "127.0.0.1 $(hostname)" >> /etc/hosts

# Disable swap (Kubernetes requirement - kubelet won't start with swap on)
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules for Kubernetes networking
cat << EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set sysctl params for Kubernetes networking
cat << EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1    # Let iptables see bridged traffic
net.bridge.bridge-nf-call-ip6tables = 1    # Let ip6tables see bridged traffic  
net.ipv4.ip_forward                 = 1    # Enable IP forwarding
EOF

sysctl --system

# Signal completion (useful for debugging boot issues)
echo "User data script completed at $(date)" > /var/log/user-data-completion.log
echo "Instance type: $INSTANCE_TYPE, Instance ID: $INSTANCE_ID" >> /var/log/user-data-completion.log