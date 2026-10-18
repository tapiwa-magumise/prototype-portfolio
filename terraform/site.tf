data "aws_caller_identity" "current" {}

locals {
  # Account ID in the bucket name keeps it globally unique without a random suffix.
  bucket = "${var.name}-site-${data.aws_caller_identity.current.account_id}"
  managed = {
    caching_optimized = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    security_headers  = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  }
}

# Private bucket: only CloudFront can read it.
resource "aws_s3_bucket" "site" {
  bucket = local.bucket
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CloudFrontRead"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
        Condition = { StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.site.arn } }
      },
      {
        Sid       = "TLSOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.site.arn, "${aws_s3_bucket.site.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.site]
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.name}-site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Served on CloudFront's own domain, so there is no Route 53 zone or certificate to pay for.
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "${var.name} site"
  price_class         = var.price_class
  default_root_object = "index.html"
  http_version        = "http2and3"
  is_ipv6_enabled     = true

  origin {
    origin_id                = "site"
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id           = "site"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = local.managed.caching_optimized
    response_headers_policy_id = local.managed.security_headers
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate { cloudfront_default_certificate = true }
}
