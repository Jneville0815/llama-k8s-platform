output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "master_public_ip" {
  description = "Master node public IP"
  value       = aws_eip.master_eip.public_ip
}

output "master_private_ip" {
  description = "Master node private IP"
  value       = aws_instance.k8s_master.private_ip
}

output "worker_private_ip" {
  description = "Worker node private IP"
  value       = aws_instance.k8s_worker.private_ip
}

output "gpu_worker_private_ip" {
  description = "GPU worker node private IP"
  value       = aws_instance.k8s_gpu_worker.private_ip
}

output "ssh_command_master" {
  description = "SSH command for master node"
  value       = "ssh -i k8s-private-key.pem ubuntu@${aws_eip.master_eip.public_ip}"
}

output "ssm_commands" {
  description = "AWS SSM Session Manager commands"
  value = {
    master     = "aws ssm start-session --target ${aws_instance.k8s_master.id}"
    worker     = "aws ssm start-session --target ${aws_instance.k8s_worker.id}"
    gpu_worker = "aws ssm start-session --target ${aws_instance.k8s_gpu_worker.id}"
  }
}

output "master_instance_id" {
  description = "Master node instance ID"
  value       = aws_instance.k8s_master.id
}

output "worker_instance_id" {
  description = "Worker node instance ID"
  value       = aws_instance.k8s_worker.id
}

output "gpu_worker_instance_id" {
  description = "GPU worker node instance ID"
  value       = aws_instance.k8s_gpu_worker.id
}