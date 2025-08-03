output "table_name" {
  value = aws_dynamodb_table.events_monitor.name
}

output "dynamodb_arn" {
  value = aws_dynamodb_table.events_monitor.arn
}