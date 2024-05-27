resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc"
  }
}

#subnets

resource "aws_subnet" "lb_subnets" {
  count = length(var.lb_subnet_cidr_blocks)
  vpc_id            = aws_vpc.vpc.id
  cidr_block = element(var.lb_subnet_cidr_blocks, count.index)
  availability_zone = var.availability_zones[count.index]
}

resource "aws_subnet" "ec2_subnets" {
  count = length(var.ec2_subnet_cidr_blocks)
  vpc_id            = aws_vpc.vpc.id
  cidr_block = element(var.ec2_subnet_cidr_blocks, count.index)
  availability_zone = var.availability_zones[count.index]
}

#internet gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

#public route table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }

}

#private route table

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "private"
  }
}

#associate public route table with public subnets

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.lb_subnets)
  subnet_id      = aws_subnet.lb_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}


#associate private route table with private subnets

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.ec2_subnets)
  subnet_id      = aws_subnet.ec2_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}

#security group for vpc

resource "aws_security_group" "vpc_endpoint_security_group" {
  name_prefix = "vpc-endpoint-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "security group for VPC Endpoints"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
    description = "Allow HTTPS traffic from VPC"
  }

  tags = {
    Name = "VPC Endpoint security group"
  }
}

#vpc endpoints for ssm

resource "aws_vpc_endpoint" "ssm" {
  vpc_id = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
  subnet_ids = [aws_subnet.ec2_subnets[0].id]
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
  subnet_ids = [aws_subnet.ec2_subnets[0].id]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
  subnet_ids = [aws_subnet.ec2_subnets[0].id]
}

# vpc endpoints for ecr

# VPC Endpoint (ecr.dkr)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
  subnet_ids         = [aws_subnet.ec2_subnets[0].id]

}

# VPC Endpoint (ecr.api)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
  subnet_ids         = [aws_subnet.ec2_subnets[0].id]

}

# VPC Endpoint (s3)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private.id]
}

#VPC Endpoint (sqs)

resource "aws_vpc_endpoint" "sqs" {
  vpc_id = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
  subnet_ids = [aws_subnet.ec2_subnets[0].id]
}

#VPC Endpoint (cloudwatch)

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
  subnet_ids = [aws_subnet.ec2_subnets[0].id]
}

# security group for ec2 instances

resource "aws_security_group" "instance_security_group" {
  name_prefix = "instance-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "security group for the EC2 instance"

  # Allow outbound HTTPS traffic
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound traffic"
  }

  tags = {
    Name = "EC2 Instance security group"
  }
}


# Create IAM role for EC2 instance

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

# ECR Full Access policy 

resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.ec2_role.name
}

# SQS Full Access policy

resource "aws_iam_role_policy_attachment" "sqs_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  role       = aws_iam_role.ec2_role.name
}

# S3 Full Access policy

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ec2_role.name
}

# CloudWatch Logs Full Access policy

resource "aws_iam_role_policy_attachment" "cloudwatch_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = aws_iam_role.ec2_role.name
}

# Create an instance profile for the EC2 instance and associate the IAM role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2_SSM_Instance_Profile"
  role = aws_iam_role.ec2_role.name
}

# security group for load balancer

resource "aws_security_group" "lb_security_group" {
  name        = "load_balancer_security_group"
  description = "Controls access to the ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
}

# security group for ec2 regarding load balancer

resource "aws_security_group" "ec2_lb_security_group" {
  name        = "ec2_lb_security_group"
  description = "Controls access to the EC2 instances from the load balancer"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.lb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create ec2 instances

resource "aws_instance" "app" {
  count = var.instance_count
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = element(aws_subnet.ec2_subnets[*].id, count.index % length(aws_subnet.ec2_subnets))
  vpc_security_group_ids = [aws_security_group.instance_security_group.id, aws_security_group.ec2_lb_security_group.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "app"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.repository_url}

              echo "QUEUE_URL=${var.sqs_queue_url}" > /etc/environment
              echo "FILES_BUCKET=${var.bucket_files}" >> /etc/environment
              echo "ORDERS_BUCKET=${var.bucket_orders}" >> /etc/environment
              echo "REGION=${var.region}" >> /etc/environment

              echo "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.repository_url}" > /etc/deploy.sh
              echo "docker pull ${var.repository_url}:latest" >> /etc/deploy.sh
              echo "docker stop \$(docker ps -a -q)" >> /etc/deploy.sh
              echo "docker rm \$(docker ps -a -q)" >> /etc/deploy.sh
              echo "docker run -d --env-file /etc/environment -p 80:3000 --log-driver=awslogs --log-opt awslogs-region=${var.region} --log-opt awslogs-group=${var.log_group_name} ${var.repository_url}:latest" >> /etc/deploy.sh
          
              chmod +x /etc/deploy.sh
            EOF
}

# create load balancer

resource "aws_lb" "lb" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_security_group.id]
  subnets            = aws_subnet.lb_subnets[*].id
}

# create target group

resource "aws_lb_target_group" "target_group" {
  name     = "target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#  create listener

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# create target group attachment

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}