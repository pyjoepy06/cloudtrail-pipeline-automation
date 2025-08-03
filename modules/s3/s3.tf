# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = format("%s-%s", var.bucket_name, var.account_num) # Use unique bucket namec
}

# Enforce Internet Bucket Security
resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_access" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_enable" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 Bucket Policy to allow CloudTrail access
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAcl"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = format("${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/%s/*", var.account_num)
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# S3 Sends Events to SQS Queue
resource "aws_s3_bucket_notification" "cloudtrail_sqs_notify" {

  bucket = aws_s3_bucket.cloudtrail_bucket.id

  queue {
    queue_arn = var.sqs_queue_arn
    events    = ["s3:ObjectCreated:*"]
    #filter_prefix = format("/AWSLogs/%s/Cloudtrail/", var.account_num)
    filter_suffix = ".gz"
  }

  depends_on = [var.sqs_s3_delivery_enable]
}