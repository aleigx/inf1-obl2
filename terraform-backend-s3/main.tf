resource "aws_s3_bucket" "bucket" {
  bucket = "terraform-state-inf1"
  force_destroy = true
}