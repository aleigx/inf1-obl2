output "bucket_website_endpoint" {
  description = "The website endpoint of the S3 bucket"
  value       = module.react_app_bucket.bucket_website_endpoint
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.react_app_bucket.bucket_name
}