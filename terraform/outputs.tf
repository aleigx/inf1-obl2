output "bucket_website_endpoint" {
  description = "The website endpoint of the S3 bucket"
  value       = module.react_app_bucket.bucket_website_endpoint
}