All of the stuff to manage the s3 and dynamo resources for locking is in the `bootstrap-backend` directory. `cd` into there and run `terraform` commands if you need to apply or destroy that infrastructure

## VLLM

1. Deploy the instance, ssm in, and then run

- `sudo apt update && sudo apt upgrade -y`
- `sudo apt install python3-pip git htop -y`
- `sudo apt install build-essential dkms`
  - build-essential: Installs GCC, g++, make, and other tools required for building software (often needed for NVIDIA driver builds).
  - dkms: Dynamic Kernel Module Support, automatically rebuilds kernel modules like NVIDIA drivers when the kernel updates.
  - Purpose: Prepares your system to compile and manage kernel modules cleanly
- `sudo apt install linux-headers-$(uname -r)`
  - Installs kernel headers matching your currently running kernel version.
  - Required for building and installing kernel modules (NVIDIA drivers).
  - Purpose: Ensures the NVIDIA driver can correctly hook into your kernel.
- `sudo apt install ubuntu-drivers-common -y`
  - Installs ubuntu-drivers utility for detecting and managing hardware drivers automatically.
  - Purpose: Lets you easily find the best driver for your GPU.
- `sudo apt install alsa-utils -y`
  - Installs ALSA sound utilities (includes aplay).
  - Avoids harmless aplay command not found warnings during driver detection.
  - Purpose: Not strictly necessary, but cleans up warnings.
- see recommended drivers: `ubuntu-drivers devices`
- install recommended driver: `sudo apt install nvidia-driver-535 -y`
  - Installs the recommended NVIDIA driver for your Tesla T4 GPU.
  - Provides nvidia-smi, CUDA kernel modules, and runtime support.
  - Purpose: Enables GPU utilization on your instance.
- reboot: `sudo reboot`

Test with `nvidia-smi`

- `sudo apt install python3-venv python3-dev -y`
- `python3 -m venv ~/vllm-env`
- `source ~/vllm-env/bin/activate`
- `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118`
- `pip install vllm`

`watch -n 1 nvidia-smi`

```
# resource "aws_security_group" "vllm_sg" {
#   name   = "vllm-sg"
#   vpc_id = module.vpc.vpc_id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_instance" "vllm_gpu" {
#   ami                         = "ami-0fc5d935ebf8bc3bc" # Ubuntu 22.04 us-east-1
#   instance_type               = "g4dn.xlarge"           # GPU instance
#   subnet_id                   = module.vpc.private_subnets[0]
#   vpc_security_group_ids      = [aws_security_group.vllm_sg.id]
#   iam_instance_profile        = aws_iam_instance_profile.ssm.name
#   associate_public_ip_address = false

#   root_block_device {
#     volume_size = 50
#   }

#   tags = {
#     Name = "vllm-gpu-node"
#   }
# }
```
