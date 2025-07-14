1. `install-k8s.sh` on all 3 nodes
2. `init-master.sh` on master node
3. Run join command from `init-master.sh` output on both worker nodes with sudo
4. `install-gpu-drivers.sh` on gpu worker
5. reboot gpu worker and test the drivers install properly with `nvidia-smi` command
6. `deploy-gpu-plugin.sh` from local with kube config set up
