# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Kubernetes-based platform for hosting LLaMA models using vLLM and AWS infrastructure. The project is being developed in phases:

### Project Phases

**Phase 1: Infrastructure Foundation** ✅ (Completed)
- **Terraform AWS Setup**: VPC, subnets, security groups, EC2 instances (1 master, 2 workers with GPU on one), IAM roles for K8s nodes
- **kubeadm Cluster Setup**: Initialize control plane, install CNI (Calico for network policies), join worker nodes, configure NVIDIA device plugin for GPU scheduling

**Phase 2: ML Model Infrastructure** 🚧 (Current Focus)
- **vLLM Container & Model Management**: Dockerfile with vLLM + Llama 3.2-3B, model download strategy (init container vs persistent volume), GPU resource allocation and scheduling, health checks for model readiness
- **Model Serving Configuration**: vLLM OpenAI-compatible API setup, resource limits (GPU memory, CPU), Horizontal Pod Autoscaler considerations (tricky with GPUs)

**Phase 3: Application Layer** 📋 (Planned)
- **FastAPI Backend**: HTTP client to vLLM service, request/response formatting, basic error handling and timeouts, metrics exposure for Prometheus
- **React Frontend**: Simple chat interface, WebSocket or polling for real-time responses, basic error states

**Phase 4: Monitoring & Observability** 📋 (Planned)
- **GPU Monitoring Setup**: NVIDIA DCGM exporter for detailed GPU metrics, custom metrics from vLLM (tokens/sec, queue depth), integration with Prometheus
- **Grafana Dashboards**: GPU utilization, memory, temperature, model inference latency and throughput, request queue metrics

### Current Repository Structure
1. **Model Server Application** (`applications/model-server/`) - Containerized vLLM server for serving LLaMA 3.2-3B models
2. **Infrastructure as Code** (`infrastructure/`) - Terraform and Kubernetes manifests for AWS deployment
3. **Cluster Management** (`infrastructure/kubernetes/cluster-setup/`) - Scripts for setting up Kubernetes on EC2 instances

## Key Development Commands

### Model Server Development
```bash
# Build Docker image
cd applications/model-server
./build-image.sh

# Test locally (requires GPU)
docker run --gpus all -p 8000:8000 llama-vllm-server:latest

# Test without GPU
docker run -p 8000:8000 -e CUDA_VISIBLE_DEVICES="" llama-vllm-server:latest
```

### Infrastructure Management
```bash
# Terraform operations (main infrastructure)
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
terraform destroy

# Terraform backend management (S3/DynamoDB)
cd infrastructure/terraform/bootstrap-backend
terraform init
terraform apply/destroy

# Kubernetes deployment
kubectl apply -f infrastructure/kubernetes/manifests/model-server/
```

### Cluster Setup (Manual on EC2 instances)
```bash
# On all nodes
./install-k8s.sh

# On master node only
./init-master.sh

# On GPU worker only
./install-gpu-drivers.sh
./deploy-gpu-plugin.sh  # Run from local with kubectl configured
```

## Architecture Overview

### Infrastructure Layer
- **AWS Provider**: Terraform manages VPC, EC2 instances (master, worker, GPU worker), security groups, and IAM roles
- **Instance Types**: t3.medium for master/worker nodes, g4dn.xlarge for GPU worker with Tesla T4
- **Networking**: Custom VPC with public/private subnets, security groups for K8s traffic and ICMP
- **Storage**: Remote state in S3 with DynamoDB locking

### Kubernetes Layer
- **3-node cluster**: 1 master + 1 worker + 1 GPU worker
- **GPU Support**: NVIDIA device plugin for GPU scheduling
- **Networking**: Uses overlay and br_netfilter kernel modules
- **Node Requirements**: Swap disabled, IP forwarding enabled

### Application Layer
- **Container Base**: Built on `vllm/vllm-openai:latest`
- **Model**: LLaMA 3.2-3B-Instruct from HuggingFace
- **API**: OpenAI-compatible endpoints on port 8000
- **Resource Requirements**: 1 GPU, 8-12Gi memory, 2-4 CPU cores
- **Storage**: Model files cached in emptyDir volumes (20Gi model cache, 10Gi HF cache)

### Key Components
- **Model Download** (`download_model.py`): Downloads LLaMA model from HuggingFace, handles authentication
- **Server Startup** (`start_server.py`): Manages vLLM server lifecycle, GPU detection, configuration
- **Health Checks**: HTTP health endpoints with 5-minute startup delay for model loading
- **Node Affinity**: Deployment specifically targets GPU worker node

## Development Patterns

### Container Development
- Base images should extend `vllm/vllm-openai:latest`
- Models are downloaded at runtime, not baked into images
- GPU detection and fallback to CPU is handled automatically
- Health checks account for long model loading times (5+ minutes)

### Infrastructure Changes
- Always test in `bootstrap-backend` directory for backend changes
- Use `manual-tests.md` verification procedures after infrastructure changes
- GPU worker requires specific hostname: `{repository-name}-gpu-worker`
- User data scripts handle node preparation automatically

### Kubernetes Deployments
- Single replica deployment due to single GPU constraint
- Node selector ensures GPU workloads only run on GPU worker
- ECR integration requires `ecr-secret` for image pulls
- Resource requests/limits are critical for GPU scheduling

## Testing and Verification

### Infrastructure Testing
Run tests from `infrastructure/terraform/manual-tests.md`:
- User data completion logs
- Swap status verification
- Kernel module loading
- Network connectivity between nodes
- GPU detection on GPU worker

### Application Testing
```bash
# GPU functionality test
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  restartPolicy: Never
  containers:
  - name: gpu-test
    image: nvidia/cuda:12.9.1-cudnn-devel-ubuntu20.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
EOF

kubectl logs gpu-test  # Should show Tesla T4
kubectl delete pod gpu-test
```

### Model Server Testing
```bash
# Check deployment status
kubectl get pods -n llama-platform

# Test API endpoint
kubectl port-forward -n llama-platform svc/llama-model-server 8000:8000
curl http://localhost:8000/health
```

## Important Configuration Details

- **HuggingFace Authentication**: LLaMA models require HF account and token
- **GPU Memory**: vLLM configured to use 80% of GPU memory (0.8 utilization)
- **Context Length**: Limited to 4096 tokens for memory efficiency
- **Concurrent Requests**: Max 64 sequences, 16 block size, 4GB swap space
- **Image Repository**: Uses ECR at `861819669871.dkr.ecr.us-east-1.amazonaws.com`

## ML-Specific Challenges & Considerations

Key challenges you'll encounter when working with this ML infrastructure:

### GPU Resource Management
- **GPU Memory Management**: Watch for OOM errors; vLLM uses 80% GPU memory by default
- **Model Loading Times**: Initial startup can take 5+ minutes for model loading
- **GPU Scheduling**: Kubernetes GPU scheduling is different from CPU - pods are exclusive to GPU nodes

### Model Inference Optimization
- **Batching Strategies**: vLLM handles dynamic batching automatically, but queue depth affects latency
- **Memory vs Speed Tradeoffs**: Context length, batch size, and memory utilization are interconnected
- **Health Check Timing**: Allow sufficient time for model warmup (5+ minutes initial delay)

### Scaling Considerations
- **Single GPU Constraint**: Current setup limited to 1 replica due to single GPU
- **Horizontal Pod Autoscaler**: Challenging with GPUs - consider request queuing instead
- **Model Persistence**: Models are downloaded at runtime - consider persistent volumes for faster restarts

## Security Considerations

- EC2 instances use IMDSv2 tokens for metadata access
- SSM Agent enabled for secure shell access
- No SSH keys required - use `aws ssm start-session`
- Network security groups restrict traffic to necessary ports only
- GPU worker specifically identified by hostname pattern