variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
}

variable "instance_count" {
  description = "The number of EC2 instances to create"
  type        = number
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

variable "files_bucket_arn" {
  description = "The ARN of the files bucket"
  type        = string
}

variable "orders_bucket_arn" {
  description = "The ARN of the orders bucket"
  type        = string
}

variable "queue_arn" {
  description = "The ARN of the SQS queue"
  type        = string
}

variable "lb_name" {
  description = "The name of the load balancer"
  type        = string
}

variable "availability_zones" {
  description = "The availability zone to use"
  type        = list(string)
}

variable "key_name" {
  description = "The name of the key pair to use for the EC2 instances"
  type        = string
}

variable "ec2_subnet_cidr_blocks" {
  description = "The CIDR blocks for the EC2 instances"
  type        = list(string)
}

variable "lb_subnet_cidr_blocks" {
  description = "The CIDR blocks for the load balancer"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "repository_arn" {
  description = "The ARN of the ECR repository"
  type        = string
}

variable "repository_url" {
  description = "The URL of the ECR repository"
  type        = string
}

variable "region" {
  description = "The region to deploy the resources"
  type        = string
}