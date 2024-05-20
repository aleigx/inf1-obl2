output "ecr_url" {
  description = "The URL of the ECR repository"
  value = aws_ecr_repository.ecr.repository_url
}

output "ecr_arn" {
  description = "The ARN of the ECR repository"
  value = aws_ecr_repository.ecr.arn
}