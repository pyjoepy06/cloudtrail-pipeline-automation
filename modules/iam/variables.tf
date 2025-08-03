variable "dynamodb_arn" {
  description = "DynamoDB ARN"
  type        = string
  default     = ""
}

variable "sqs_arn" {
  description = "SQS ARN"
  type        = string
  default     = ""
}

variable "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  type        = string
}

variable "sns_arn" {
  description = "SNS ARN"
  type        = string
}

variable "role_name" {
  description = "Role name"
  type        = string
  default     = "lambda-cloudtrail-role"
}