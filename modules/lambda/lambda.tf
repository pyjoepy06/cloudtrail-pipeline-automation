resource "aws_lambda_function" "cloudtrail_analyzer" {
  function_name    = var.function_name
  role             = var.iam_role_arn
  handler          = "index.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
      dynamodb_name = var.dynamodb_table_name
    }
  }

}

# Lambda Trigger: SQS Event Source
resource "aws_lambda_event_source_mapping" "sqs_trigger" {

  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.cloudtrail_analyzer.arn
  batch_size       = 5
  enabled          = true

  depends_on = [var.sqs_trigger_enable]
}


