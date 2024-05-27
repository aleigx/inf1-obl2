resource "aws_ecr_repository" "ecr" {
  name = var.ecr_name
  image_tag_mutability = "MUTABLE"
  force_delete = true
}