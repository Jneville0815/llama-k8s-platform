#!/bin/bash

set -e

echo "🚀 Deploying NVIDIA Device Plugin to Kubernetes..."

# Verify kubectl access
if ! kubectl get nodes >/dev/null 2>&1; then
    echo "❌ kubectl not configured or cluster not accessible"
    echo "Make sure you're running this from a machine with kubectl access to the cluster"
    exit 1
fi

echo "✅ kubectl access verified"

# Check if we have a GPU node
echo "🔍 Checking for GPU nodes..."
kubectl get nodes -o wide

# Deploy NVIDIA Device Plugin using the official manifest
echo "📦 Deploying NVIDIA Device Plugin..."
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.5/nvidia-device-plugin.yml

echo "⏳ Waiting for device plugin to be ready..."
sleep 10

# Wait for the device plugin daemonset to be ready
kubectl rollout status daemonset/nvidia-device-plugin-daemonset -n kube-system --timeout=300s

echo "✅ NVIDIA Device Plugin deployed successfully!"

# Verify GPU resources are available
echo "🔍 Checking GPU resource allocation..."
echo ""
echo "📊 Node GPU capacity:"
kubectl describe nodes | grep -A 5 -B 5 "nvidia.com/gpu"

echo ""
echo "📋 GPU device plugin pods:"
kubectl get pods -n kube-system -l name=nvidia-device-plugin-ds

echo ""
echo "🎯 GPU nodes with capacity:"
kubectl get nodes -o custom-columns="NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"

echo ""
echo "✅ GPU support is now enabled in Kubernetes!"
echo ""
echo "📝 To test GPU functionality, create a pod with:"
echo "  resources:"
echo "    limits:"
echo "      nvidia.com/gpu: 1"
echo ""
echo "🧪 Quick test command:"
echo "kubectl run gpu-test --image=nvidia/cuda:11.0-base --rm -it --restart=Never --limits='nvidia.com/gpu=1' -- nvidia-smi"