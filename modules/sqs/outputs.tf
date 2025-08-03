output "queue_name" {
  value = aws_sqs_queue.cloudtrail_queue.name
}

output "queue_arn" {
  value = aws_sqs_queue.cloudtrail_queue.arn
}

output "queue_url" {
  value = aws_sqs_queue.cloudtrail_queue.url
}