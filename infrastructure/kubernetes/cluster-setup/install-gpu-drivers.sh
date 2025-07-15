#!/bin/bash

set -e

echo "🎮 Installing NVIDIA GPU drivers and container toolkit..."

# Verify this is a GPU instance
if ! lspci | grep -i nvidia > /dev/null; then
    echo "❌ No NVIDIA GPU detected! This script should only run on GPU instances."
    exit 1
fi

echo "✅ NVIDIA GPU detected:"
lspci | grep -i nvidia

# Update package list
sudo apt-get update

# Install kernel headers (required for driver compilation)
echo "📦 Installing kernel headers..."
sudo apt-get install -y linux-headers-$(uname -r)

# Install NVIDIA driver
echo "🔧 Installing NVIDIA driver..."
sudo apt-get install -y nvidia-driver-535 libnvidia-ml-dev nvidia-utils-535 libnvidia-compute-535

# Install NVIDIA Container Toolkit using the official method
echo "📦 Installing NVIDIA Container Toolkit..."

# Configure the production repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Update package list with new repository
sudo apt-get update

# Install NVIDIA Container Toolkit
sudo apt-get install -y nvidia-container-toolkit

# Configure containerd to use NVIDIA runtime
echo "⚙️ Configuring containerd for NVIDIA runtime..."
sudo nvidia-ctk runtime configure --runtime=containerd --set-as-default

# Restart containerd to pick up changes
echo "🔄 Restarting containerd..."
sudo systemctl restart containerd

# Restart kubelet to detect new runtime
echo "🔄 Restarting kubelet..."
sudo systemctl restart kubelet

echo "✅ NVIDIA drivers and container toolkit installed!"

echo ""
echo "⚠️  REBOOT REQUIRED ⚠️"
echo "The system needs to be rebooted to load the NVIDIA kernel modules."
echo "After reboot, verify installation with:"
echo "  nvidia-smi"

# Save reboot reminder
echo "System needs reboot for NVIDIA drivers - $(date)" > /tmp/gpu-reboot-needed

echo "🔧 To reboot now, run: sudo reboot"
echo "🔧 Or reboot via AWS console/CLI"