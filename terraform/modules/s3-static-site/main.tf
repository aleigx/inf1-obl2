locals {
  vars = length(var.variables_file) > 0 ? jsondecode(file(var.variables_file)) : {}
}

resource "aws_s3_bucket" "react_app_bucket" {
  bucket = lookup(local.vars, "bucket_name", var.bucket_name)
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "react_app_bucket_public_access_block" {
  bucket = aws_s3_bucket.react_app_bucket.id
  block_public_acls       = false
  block_public_policy     = false
}

resource "aws_s3_bucket_policy" "react_app_bucket_policy" {
  bucket = aws_s3_bucket.react_app_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.react_app_bucket.arn}/*"
      }
    ]
  })
}