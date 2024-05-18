locals {
  vars = length(var.variables_file) > 0 ? jsondecode(file(var.variables_file)) : {}
}

provider "aws" {
  region = local.vars.region
}

module "s3_static_site" {
  source = "./modules/s3-static-site"
  bucket_name = local.vars.bucket_name
}

module "cloudfront" {
  source = "./modules/cloudfront"
  bucket_name = module.s3_static_site.bucket_name
  bucket_arn = module.s3_static_site.arn
  bucket_regional_domain_name = module.s3_static_site.bucket_regional_domain_name
}