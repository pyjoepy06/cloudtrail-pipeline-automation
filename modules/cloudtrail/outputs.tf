output "cloudtrail_arn" {
  value = aws_cloudtrail.analyzer_trail.arn
}

output "cloudtrail_name" {
  value = aws_cloudtrail.analyzer_trail.name
}