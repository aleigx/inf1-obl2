resource "aws_cloudfront_origin_access_control" "oac" {
  name                     = "s3-cloudfront-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior           = "always"
  signing_protocol           = "sigv4"
}

data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = ["${var.bucket_arn}/*"]

    condition {
      test   = "StringEquals"
      variable = "AWS:SourceArn"
      values  = [aws_cloudfront_distribution.cloudfront_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = var.bucket_name
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  default_root_object       = "index.html"
  enabled                   = true
  is_ipv6_enabled            = true
  wait_for_deployment        = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods          = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id        = var.bucket_name
    viewer_protocol_policy = "redirect-to-https"
  }

  origin {
    domain_name               = var.bucket_regional_domain_name
    origin_access_control_id  = aws_cloudfront_origin_access_control.oac.id
    origin_id                 = var.bucket_name
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}