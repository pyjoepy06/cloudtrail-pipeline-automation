variable "description" {
  type        = string
  default     = "KMS key for CloudTrail + S3 encryption"
  description = "Description for the KMS key"
}

variable "alias" {
  type        = string
  description = "Alias for the KMS key (e.g., cloudtrail-logs)"
}

variable "allow_cloudtrail" {
  type        = bool
  default     = true
  description = "Whether to allow CloudTrail service access to the key"
}

variable "account_num" {
  description = "AWS account number"
  type        = string
}

variable "lambda_role_name" {
  description = "Lambda Role Name"
  type        = string
  default     = "lambda-role"
}