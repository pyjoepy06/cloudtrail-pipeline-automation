variable "bucket_name" {
  description = "S3 Bucket Name for cloudtrail logs"
  type        = string
  default     = "s3-analyzer"
}

variable "account_num" {
  description = "Name to be used DynamoDb Table"
  type        = string
  default     = "CloudtrailMonitorPipeline"
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN to encrypt CloudTrail logs"
  type        = string
  default     = null
}

variable "sqs_queue_arn" {
  description = "SQS Queue ARN needed in order for S3 to begin sending logs to S3"
  type        = string
  default     = null

}

variable "sqs_s3_delivery_enable" {
  description = "True or False, True enable SQS queue with Lambda Handler, False do not enable SQS Trigger"
  type        = bool
  default     = false
}