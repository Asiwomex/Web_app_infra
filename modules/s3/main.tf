data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

# ─── Application / Backup / ALB-Logs S3 Bucket ───────────────────────────────

resource "aws_s3_bucket" "app" {
  bucket        = "${var.project_name}-${var.environment}-app-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-app-bucket"
  })
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    id     = "backup-lifecycle"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "alb-logs-lifecycle"
    status = "Enabled"

    filter {
      prefix = "alb-${var.environment}/"
    }

    expiration {
      days = 90
    }
  }
}

# ─── Bucket Policy: TLS-only + ALB log delivery ──────────────────────────────

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.app.arn,
          "${aws_s3_bucket.app.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        # ELB account writes ALB access logs (region-agnostic via data source)
        Sid       = "AllowALBAccessLogs"
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.app.arn}/alb-${var.environment}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid       = "AllowDeliveryLogsPut"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.app.arn}/alb-${var.environment}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AllowDeliveryLogsAcl"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.app.arn
      }
    ]
  })
}
