resource "aws_sns_topic" "login_alerts" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alert_emails) > 0 ? length(var.alert_emails) : 0
  topic_arn = aws_sns_topic.login_alerts.arn
  protocol  = "email"
  endpoint  = element(var.alert_emails, count.index)
}