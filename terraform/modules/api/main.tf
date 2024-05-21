resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  assign_generated_ipv6_cidr_block = true
}

#subnets

resource "aws_subnet" "lb_subnets" {
  count = length(var.lb_subnet_cidr_blocks)
  vpc_id            = aws_vpc.vpc.id
  cidr_block = element(var.lb_subnet_cidr_blocks, count.index)
  availability_zone = var.availability_zones[count.index]
  ipv6_cidr_block      = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, count.index)
}

resource "aws_subnet" "ec2_subnets" {
  count = length(var.ec2_subnet_cidr_blocks)
  vpc_id            = aws_vpc.vpc.id
  cidr_block = element(var.ec2_subnet_cidr_blocks, count.index)
  availability_zone = var.availability_zones[count.index]
  ipv6_cidr_block      = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, count.index + length(var.lb_subnet_cidr_blocks))
}

#routing table

resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.internet.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "internet_route_ipv6" {
  route_table_id         = aws_route_table.internet.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id             = aws_internet_gateway.igw.id
}


resource "aws_route_table_association" "lb_subnets_association" {
  count          = length(aws_subnet.lb_subnets)
  subnet_id      = element(aws_subnet.lb_subnets.*.id, count.index)
  route_table_id = aws_route_table.internet.id
}


resource "aws_route_table_association" "ec2_subnets_association" {
  count          = length(aws_subnet.ec2_subnets)
  subnet_id      = element(aws_subnet.ec2_subnets.*.id, count.index)
  route_table_id = aws_route_table.internet.id
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

#security groups

resource "aws_security_group" "ec2_instance" {
  name        = "App-IN-SG"
  description = "Allow inbound and outbound traffic to EC2 instances from load balancer security group."

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "ssh_ipv6" {
  name        = "SSH-IPv6"
  description = "Allow SSH access from the internet."
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "lb" {
  name        = "App-LB-SG"
  description = "Allow inbound and outbound traffic to load balancer from the internet."
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
  vpc_id = aws_vpc.vpc.id
}


data aws_iam_policy_document "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = "${aws_iam_role.ec2_iam_role.name}"
}


# s3 bucket access

data aws_iam_policy_document "s3_read_access" {
  statement {
    actions = ["s3:PutObject"]
    resources = [var.files_bucket_arn, var.orders_bucket_arn]
  }
}

resource "aws_iam_role_policy" "join_policy" {
  depends_on = [aws_iam_role.ec2_iam_role]
  name       = "join_policy"
  role       = "${aws_iam_role.ec2_iam_role.name}"
  policy = "${data.aws_iam_policy_document.s3_read_access.json}"
}

# sqs access, read, write, delete

data aws_iam_policy_document "sqs_access" {
  statement {
    actions = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"]
    resources = [var.queue_arn]
  }
}

resource "aws_iam_role_policy" "sqs_policy" {
  depends_on = [aws_iam_role.ec2_iam_role]
  name = "sqs_policy"
  role = aws_iam_role.ec2_iam_role.name
  policy = data.aws_iam_policy_document.sqs_access.json
}

# ecr

data aws_iam_policy_document "ecr_access" {
  statement {
    actions = ["*"]
    resources = [var.repository_arn]
  }
}

resource "aws_iam_role_policy" "ecr_policy" {
  depends_on = [aws_iam_role.ec2_iam_role]
  name = "ecr_policy"
  role = aws_iam_role.ec2_iam_role.name
  policy = data.aws_iam_policy_document.ecr_access.json
}


# instances



resource "aws_instance" "app" {
  count           = var.instance_count
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = element(aws_subnet.ec2_subnets.*.id, count.index % length(aws_subnet.ec2_subnets))
  key_name        = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_instance.id, aws_security_group.ssh_ipv6.id]
  ipv6_address_count = 1
  tags = {
    Name = "api-instance-${count.index + 1}"
  }

  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"



  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user

    cat << 'EOT' > /etc/systemd/system/app.service
    [Unit]
    Description=app
    After=docker.service
    Requires=docker.service

    [Service]
    Restart=always
    ExecStart=/usr/bin/docker pull ${var.repository_url}:latest
    ExecStart=/usr/bin/docker run -p 80:80 ${var.repository_url}:latest

    [Install]
    WantedBy=multi-user.target
    EOT

    sudo systemctl daemon-reload
    sudo systemctl enable app
    sudo systemctl start app
  EOF
}

# load balancer

resource "aws_lb_target_group" "lb_target_group" {
  name     = "lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "attach_app" {
  count            = length(aws_instance.app)
  target_group_arn = aws_lb_target_group.lb_target_group.arn
  target_id        = element(aws_instance.app.*.id, count.index)
  port             = 80
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

resource "aws_lb" "lb" {
  name                       = "app-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb.id]
  subnets                    = [for subnet in aws_subnet.lb_subnets : subnet.id]
  enable_deletion_protection = false
}