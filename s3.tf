# Create S3 buckets for the api pdf storage
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.1"

  bucket                   = "${var.s3_bucket_name}-${random_id.this.hex}"
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true

  versioning = {
    status     = false
    mfa_delete = false
  }

  lifecycle_rule = [
    {
      id      = "delete-old-versions"
      enabled = true
      noncurrent_version_expiration = {
        days                      = 30
        newer_noncurrent_versions = 5
      }
    }
  ]
}

resource "aws_s3_bucket_policy" "https_only" {

  bucket = module.s3_bucket.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "https-only"
    Statement = [
      {
        Sid       = "HTTPSOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}