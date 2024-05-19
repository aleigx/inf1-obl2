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

variable "public_subnet_cidr_blocks" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
}