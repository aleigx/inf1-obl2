output "static_site_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.static_site.bucket_name
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

output "region" {
  value = local.vars.region
}

output "orders_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.orders_bucket.bucket_name
}

output "files_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.files_bucket.bucket_name
}

output "notifications_queue_url" {
  description = "The URL of the SQS queue"
  value       = module.notifications_queue.url
}

output "ec2_instance_ids" {
  description = "The IDs of the EC2 instances"
  value       = module.api.instance_ids
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.api.lb_dns_name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.ecr_url
}

output "func_name" {
  value = module.lambda.func_name
}