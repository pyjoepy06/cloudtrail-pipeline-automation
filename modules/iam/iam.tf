#############################
# Lambda IAM Roles/Policies
#############################

resource "aws_iam_role" "lambda_cloudtrail_analyzer" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_cloudtrail_custom_policy" {
  name = "lambda-custom-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        #Allow DynamoDB Updates
        Effect   = "Allow",
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem"],
        Resource = var.dynamodb_arn
      },
      {
        #Allow SQS Access
        Effect   = "Allow",
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
        Resource = var.sqs_arn
      },
      {
        #Allow Cloudtrail S3 Bucket Access
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        #Allow SNS access to send emails
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = var.sns_arn
      },
      {
        #Allow Cloudwatch logging to troubleshoot lambda issues as needed
        Effect   = "Allow",
        Action   = ["logs:*"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_lambda_policy_attach" {
  role       = aws_iam_role.lambda_cloudtrail_analyzer.name
  policy_arn = aws_iam_policy.lambda_cloudtrail_custom_policy.arn
}