output "bucket_regional_domain_name" {
  description = "The bucket regional domain name of the S3 bucket"
  value       = aws_s3_bucket.static_site.bucket_regional_domain_name
}

output "arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.static_site.arn
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.static_site.bucket
}