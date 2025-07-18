#!/bin/bash

set -e

echo "🐳 Building vLLM Llama 3.2-3B Docker image..."

# Configuration
IMAGE_NAME="llama-vllm-server"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile not found! Make sure you're in the correct directory."
    exit 1
fi

# Build the image
echo "📦 Building Docker image: ${FULL_IMAGE_NAME}"
docker build -t ${FULL_IMAGE_NAME} .

# Verify the build
if docker images | grep -q ${IMAGE_NAME}; then
    echo "✅ Image built successfully!"
    
    # Show image info
    echo ""
    echo "📊 Image information:"
    docker images | grep ${IMAGE_NAME}
    
    # Show image size
    IMAGE_SIZE=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep ${FULL_IMAGE_NAME} | awk '{print $2}')
    echo "📏 Image size: ${IMAGE_SIZE}"
    
else
    echo "❌ Image build failed!"
    exit 1
fi

echo ""
echo "🚀 Next steps:"
echo "1. Test the image locally (if you have a GPU):"
echo "   docker run --gpus all -p 8000:8000 ${FULL_IMAGE_NAME}"
echo ""
echo "2. Or tag and push to a registry:"
echo "   docker tag ${FULL_IMAGE_NAME} your-registry/${FULL_IMAGE_NAME}"
echo "   docker push your-registry/${FULL_IMAGE_NAME}"
echo ""
echo "3. Deploy to Kubernetes:"
echo "   Update the image name in your K8s manifests and apply"

echo ""
echo "🔧 For local testing without GPU:"
echo "   docker run -p 8000:8000 -e CUDA_VISIBLE_DEVICES=\"\" ${FULL_IMAGE_NAME}"