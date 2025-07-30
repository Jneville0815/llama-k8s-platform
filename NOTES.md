This is a Kubernetes-based platform for hosting LLaMA models using vLLM and AWS infrastructure. The project is being developed in phases.

# Project Phases

## Phase 1: Infrastructure Foundation

### Terraform AWS Setup:

- VPC, subnets, security groups
- EC2 instances (1 master, 2 workers with GPU on one)
- IAM roles for K8s nodes

### kubeadm Cluster Setup:

- Initialize control plane
- Install CNI (Calico for network policies)
- Join worker nodes
- Configure NVIDIA device plugin for GPU scheduling

## Phase 2: ML Model Infrastructure

### vLLM Container & Model Management:

- Dockerfile with vLLM + Llama 3.2-3B
- Model download strategy (currently using emptyDir volumes)
- GPU resource allocation and scheduling
- Health checks for model readiness

### Model Serving Configuration:

- vLLM OpenAI-compatible API setup
- Resource limits (GPU memory, CPU)
- Horizontal Pod Autoscaler considerations (tricky with GPUs)

## Phase 3: Application Layer

### FastAPI Backend:

- HTTP client to vLLM service
- Request/response formatting
- Basic error handling and timeouts
- Metrics exposure for Prometheus

### React Frontend:

- Simple chat interface
- WebSocket or polling for real-time responses
- Basic error states

## Phase 4: Monitoring & Observability

### GPU Monitoring Setup:

- NVIDIA DCGM exporter for detailed GPU metrics
- Custom metrics from vLLM (tokens/sec, queue depth)
- Integration with Prometheus

### Grafana Dashboards:

- GPU utilization, memory, temperature
- Model inference latency and throughput
- Request queue metrics

# Technical Architecture

## Infrastructure Layer

- AWS: VPC (10.10.0.0/16), 3 EC2 instances across AZs
- Instance Types: t3.medium (master/worker), g4dn.xlarge (GPU worker with Tesla T4)
- Storage: EBS gp2 root volumes, local ephemeral storage for containers

## Kubernetes Layer

- Version: v1.29.15
- CNI: Calico networking
- GPU Support: NVIDIA device plugin
- Cluster: 3 nodes (1 master, 1 worker, 1 GPU worker)

## Application Layer

- Container: Built on vllm/vllm-openai:latest
- Model: LLaMA 3.2-3B-Instruct from HuggingFace
- API: OpenAI-compatible endpoints on port 8000
- Storage: Currently emptyDir (20Gi model + 10Gi HF cache)
