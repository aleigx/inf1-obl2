output "bucket_website_endpoint" {
  description = "The website endpoint of the S3 bucket"
  value       = aws_s3_bucket.react_app_bucket.website_endpoint
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.react_app_bucket.bucket
}