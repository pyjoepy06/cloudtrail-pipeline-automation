variable "topic_name" {
  description = "Name to be used DynamoDb Table"
  type        = string
  default     = "cloudtrail-monitor-sns"
}

variable "alert_emails" {
  description = "List of emails for the alerts"
  type        = list(string)
  default     = [""]
}