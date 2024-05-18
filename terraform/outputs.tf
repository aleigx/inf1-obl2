output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.s3_static_site.bucket_name
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

output "region" {
  value = local.vars.region
}