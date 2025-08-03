variable "cloudtrail_name" {
  description = "Cloudtrail Name"
  type        = string
  default     = "cloudtrail-analyzer"
}

variable "cloudtrail_bucket" {
  description = "S3 Bucket for CloudTrail Logging"
  type        = string
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN to encrypt CloudTrail logs"
  type        = string
  default     = null
}