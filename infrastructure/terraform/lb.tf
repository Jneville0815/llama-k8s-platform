# ALB for external traffic
resource "aws_lb" "main" {
 name               = "react-fastapi-alb"
 internal           = false
 load_balancer_type = "application"
 security_groups    = [aws_security_group.alb.id]
 subnets           = module.vpc.public_subnets

 tags = {
   Name = "react-fastapi-alb"
 }
}

# Target group for NGINX Ingress Controller
resource "aws_lb_target_group" "ingress_http" {
 name     = "k8s-ingress-http"
 port     = 30080
 protocol = "HTTP"
 vpc_id   = module.vpc.vpc_id
 
 health_check {
   enabled             = true
   healthy_threshold   = 2
   interval           = 30
   matcher            = "200"
   path               = "/healthz"
   port               = "30080"
   protocol           = "HTTP"
   timeout            = 5
   unhealthy_threshold = 2
 }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
 load_balancer_arn = aws_lb.main.arn
 port              = "80"
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.ingress_http.arn
 }
}

# Manual target group attachments (no ASG)
resource "aws_lb_target_group_attachment" "master" {
 target_group_arn = aws_lb_target_group.ingress_http.arn
 target_id        = aws_instance.k8s_master.id
 port             = 30080
}

resource "aws_lb_target_group_attachment" "worker" {
 target_group_arn = aws_lb_target_group.ingress_http.arn
 target_id        = aws_instance.k8s_worker.id
 port             = 30080
}

resource "aws_lb_target_group_attachment" "gpu_worker" {
 target_group_arn = aws_lb_target_group.ingress_http.arn
 target_id        = aws_instance.k8s_gpu_worker.id
 port             = 30080
}

# ALB Security Group - restricted to your IP only
resource "aws_security_group" "alb" {
 name_prefix = "react-fastapi-alb-"
 vpc_id      = module.vpc.vpc_id

 ingress {
   description = "HTTP from my IP only"
   from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = [local.my_ip]
 }

 egress {
   description = "To NodePort"
   from_port   = 30080
   to_port     = 30080
   protocol    = "tcp"
   cidr_blocks = [local.vpc_cidr]
 }

 tags = {
   Name = "react-fastapi-alb-sg"
 }
}

# Allow ALB to reach NodePort on all nodes
resource "aws_security_group_rule" "master_from_alb" {
 type                     = "ingress"
 from_port               = 30080
 to_port                 = 30080
 protocol                = "tcp"
 source_security_group_id = aws_security_group.alb.id
 security_group_id       = aws_security_group.k8s_master.id
}

resource "aws_security_group_rule" "workers_from_alb" {
 type                     = "ingress"
 from_port               = 30080
 to_port                 = 30080
 protocol                = "tcp"
 source_security_group_id = aws_security_group.alb.id
 security_group_id       = aws_security_group.k8s_worker.id
}