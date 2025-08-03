variable "queue_name" {
  description = "Name to be used for SQS Queue"
  type        = string
  default     = "cloudtrail-analyzer"
}

variable "s3_bucket_arn" {
  description = "ARN of S3 bucket to be used for event notifications"
  type        = string
  default     = null
}

variable "sqs_s3_delivery_enable" {
  description = "True or False, True enable SQS queue with Lambda Handler, False do not enable SQS Trigger"
  type        = bool
  default     = false
}