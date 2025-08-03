output "lambda_role_arn" {
  value = aws_iam_role.lambda_cloudtrail_analyzer.arn
}

output "lambda_role_name" {
  value = aws_iam_role.lambda_cloudtrail_analyzer.name
}