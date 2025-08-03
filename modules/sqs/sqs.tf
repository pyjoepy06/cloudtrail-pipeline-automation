# --- SQS Queue for CloudTrail Notifications ---
resource "aws_sqs_queue" "cloudtrail_queue" {
  name                       = var.queue_name
  message_retention_seconds  = 86400 # 1 day
  visibility_timeout_seconds = 300   # 5 min
}

# Allow S3 to Send Messages to SQS
resource "aws_sqs_queue_policy" "cloudtrail_queue_policy" {

  queue_url = aws_sqs_queue.cloudtrail_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "sqs:SendMessage",
      Resource  = aws_sqs_queue.cloudtrail_queue.arn,
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = var.s3_bucket_arn
        }
      }
    }]
  })

  depends_on = [var.sqs_s3_delivery_enable]
}