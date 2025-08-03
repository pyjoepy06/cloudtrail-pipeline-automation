variable "function_name" {
  description = "Name to be used for Lambda Function"
  type        = string
  default     = ""
}

variable "iam_role_arn" {
  description = "Name of Lambda Role deployed from IAM Policies"
  type        = string
  default     = ""
}

variable "lambda_zip_path" {
  description = "Source Path of lambda code, used with data command, outpath"
  type        = string
}

variable "lambda_zip_hash" {
  description = "Source Path of lambda code, with .output_base64sha256 at end"
  type        = string
}

variable "sqs_queue_arn" {
  description = "SQS ARN for SQS Triggers"
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "SNS ARN for SNS Notification"
  type        = string
  default     = null
}

variable "dynamodb_table_name" {
  description = "DynamoDB name"
  type        = string
}

variable "sqs_trigger_enable" {
  description = "True or False, True enable SQS queue with Lambda Handler, False do not enable SQS Trigger"
  type        = bool
  default     = false
}