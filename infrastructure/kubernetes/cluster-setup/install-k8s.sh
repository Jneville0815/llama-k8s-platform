#!/bin/bash

set -e

echo "🚀 Installing Kubernetes components..."

# Update package list
sudo apt-get update

# Install containerd
echo "📦 Installing containerd..."
sudo apt-get install -y containerd

# Create containerd configuration directory
sudo mkdir -p /etc/containerd

# Generate default containerd config
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Configure containerd to use systemd cgroup driver (required for kubelet)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "✅ containerd installed and configured"

# Install packages needed for Kubernetes repository
echo "📦 Installing prerequisites..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes signing key
echo "🔑 Adding Kubernetes repository key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo "📋 Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list with new repository
sudo apt-get update

# Install kubelet, kubeadm, and kubectl
echo "⚙️ Installing kubelet, kubeadm, and kubectl..."
sudo apt-get install -y kubelet kubeadm kubectl

# Hold these packages to prevent accidental upgrades
echo "🔒 Holding Kubernetes packages to prevent auto-updates..."
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service (it will fail to start until cluster is initialized, that's normal)
sudo systemctl enable kubelet

# Verify installations
echo "🔍 Verifying installations..."
echo "containerd version:"
containerd --version

echo "kubeadm version:"
kubeadm version

echo "kubelet version:"
kubelet --version

echo "kubectl version:"
kubectl version --client

echo ""
echo "✅ Kubernetes components installed successfully!"
echo ""
echo "📝 Next steps:"
echo "  - Run this script on ALL nodes (master + workers)"
echo "  - Then initialize the cluster on the master node"
echo ""
echo "🔧 Node type detection:"
INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")" http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "unknown")

if [[ "$INSTANCE_TYPE" == *"g4dn"* ]]; then
    echo "  This appears to be the GPU worker node"
elif [[ "$INSTANCE_TYPE" == "t3.medium" ]]; then
    echo "  This appears to be a regular node (master or worker)"
else
    echo "  Instance type: $INSTANCE_TYPE"
fi

echo ""
echo "Run 'systemctl status kubelet' to check kubelet status"
echo "(It's normal for kubelet to be in a crash loop until cluster init)"