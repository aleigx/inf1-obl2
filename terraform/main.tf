provider "aws" {
  region = "us-west-2"
}

module "react_app_bucket" {
  source         = "./modules/s3-static-site"
  bucket_name    = "default-name"
  variables_file = var.variables_file
}