ssm onto all 3 nodes and then `cd` into home directory

1. `install-k8s.sh` on all 3 nodes
2. `init-master.sh` on master node
3. Run join command from `init-master.sh` output on both worker nodes with sudo
4. `install-gpu-drivers.sh` on gpu worker
5. reboot gpu worker and test the drivers install properly with `nvidia-smi` command. Also:

```
# Test container can access GPU
sudo ctr --namespace k8s.io image pull docker.io/nvidia/cuda:12.9.1-cudnn-devel-ubuntu20.04

sudo ctr --namespace k8s.io run --rm \
    --runtime io.containerd.runc.v2 \
    --runc-binary /usr/bin/nvidia-container-runtime \
    docker.io/nvidia/cuda:12.9.1-cudnn-devel-ubuntu20.04 test-gpu nvidia-smi
```

6. `deploy-gpu-plugin.sh` from local with kube config set up. To test:

```
# Schedule a GPU pod
cat << EOF | kubectl apply -f -
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

# Check pod status
kubectl get pod gpu-test

# View GPU output (should show Tesla T4)
kubectl logs gpu-test

# Clean up
kubectl delete pod gpu-test
```
