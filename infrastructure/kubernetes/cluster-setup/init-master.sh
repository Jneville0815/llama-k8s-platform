#!/bin/bash

set -e

echo "🚀 Initializing Kubernetes master node..."

# Get both private and public IPs of this node (master)
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")" http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")" http://169.254.169.254/latest/meta-data/public-ipv4)

echo "📍 Master node private IP: $PRIVATE_IP"
echo "📍 Master node public IP: $PUBLIC_IP"

# Initialize the cluster with both private and public IPs in certificate
echo "⚙️ Running kubeadm init with certificate SANs for both IPs..."
sudo kubeadm init \
    --apiserver-advertise-address=$PRIVATE_IP \
    --apiserver-cert-extra-sans=$PRIVATE_IP,$PUBLIC_IP \
    --pod-network-cidr=192.168.0.0/16 \
    --service-cidr=10.96.0.0/12

echo "✅ Cluster initialized successfully!"

# Set up kubectl
echo "🔧 Setting up kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "✅ kubectl configured"

# Test kubectl
echo "🔍 Testing kubectl..."
kubectl get nodes

# Install Calico CNI
echo "🌐 Installing Calico CNI plugin..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/calico.yaml

echo "⏳ Waiting for Calico pods to start..."
sleep 60  # Give plenty of time for pods to be created

kubectl get pods -n kube-system -l k8s-app=calico-node || echo "Calico pods still starting..."

echo "✅ Calico CNI installed successfully!"

# Display cluster status
echo ""
echo "🎉 Cluster initialization complete!"
echo ""
echo "📋 Current cluster status:"
kubectl get nodes -o wide
echo ""
kubectl get pods -n kube-system

echo ""
echo "📝 Next steps:"
echo "1. Copy the kubeadm join command that was displayed above"
echo "2. Run it on your worker nodes"
echo "3. Copy /etc/kubernetes/admin.conf to your local machine for kubectl access"
echo ""

# Show the join command again
echo "🔗 To get the join command again, run:"
echo "sudo kubeadm token create --print-join-command"
echo ""

# Save cluster info for easy access
echo "💾 Saving cluster information..."
sudo kubeadm token create --print-join-command > /tmp/join-command.sh
chmod +x /tmp/join-command.sh

echo "Join command saved to: /tmp/join-command.sh"
echo "Run this command on worker nodes: cat /tmp/join-command.sh"