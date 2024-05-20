locals {
  vars = jsondecode(file(var.variables_file))
}

provider "aws" {
  region = local.vars.region
}

module "ecr" {
  source = "./modules/ecr"
  ecr_name = local.vars.ecr_name
}

module "static_site" {
  source = "./modules/bucket"
  bucket_name = local.vars.static_site_bucket_name
}

module "cloudfront" {
  source = "./modules/cloudfront"
  bucket_name = module.static_site.bucket_name
  bucket_arn = module.static_site.arn
  bucket_regional_domain_name = module.static_site.bucket_regional_domain_name
}

module "orders_bucket" {
  source = "./modules/bucket"
  bucket_name = local.vars.orders_bucket_name
}

module "files_bucket" {
  source = "./modules/bucket"
  bucket_name = local.vars.files_bucket_name
}

module "notifications_queue" {
  source = "./modules/sqs"
  queue_name = local.vars.notifications_queue_name
}

module "keypair" {
  source = "./modules/keypair"
  key_name = local.vars.key_name
  public_key_path = var.public_key_path
}

module "api" {
  source = "./modules/api"
  instance_type = local.vars.ec2_instance_type
  instance_count = local.vars.ec2_instance_count
  ami_id = local.vars.ec2_ami_id
  files_bucket_arn = module.files_bucket.arn
  orders_bucket_arn = module.orders_bucket.arn
  queue_arn = module.notifications_queue.arn
  lb_name = local.vars.lb_name
  availability_zones = local.vars.availability_zones
  key_name = module.keypair.key_name
  vpc_cidr_block = local.vars.vpc_cidr_block
  lb_subnet_cidr_blocks = local.vars.lb_subnet_cidr_blocks
  ec2_subnet_cidr_blocks = local.vars.ec2_subnet_cidr_blocks
  repository_arn = module.ecr.ecr_arn
}