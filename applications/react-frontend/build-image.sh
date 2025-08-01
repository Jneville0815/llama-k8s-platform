#!/bin/bash

set -e

echo "🐳 Building React frontend Docker image..."

# Configuration
IMAGE_NAME="llama-react-frontend"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile not found! Make sure you're in the correct directory."
    exit 1
fi

# Build the image for AMD64 (EC2 architecture)
echo "📦 Building Docker image for linux/amd64: ${FULL_IMAGE_NAME}"
docker build --platform linux/amd64 -t ${FULL_IMAGE_NAME} .

# Verify the build
if docker images | grep -q ${IMAGE_NAME}; then
    echo "✅ Image built successfully!"
    
    # Show image info
    echo ""
    echo "📊 Image information:"
    docker images | grep ${IMAGE_NAME}
    
else
    echo "❌ Image build failed!"
    exit 1
fi

echo ""
echo "🚀 Next steps:"
echo "1. Test locally:"
echo "   docker run -p 3000:80 ${FULL_IMAGE_NAME}"
echo ""
echo "2. Tag and push to ECR:"
echo "   docker tag ${FULL_IMAGE_NAME} 861819669871.dkr.ecr.us-east-1.amazonaws.com/${FULL_IMAGE_NAME}"
echo "   docker push 861819669871.dkr.ecr.us-east-1.amazonaws.com/${FULL_IMAGE_NAME}"