# Data module to find lambda code, zip it, and upload it to AWS
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-src"
  output_path = "${path.module}/lambda.zip"
}

#Get AWS Account Inforamation
data "aws_caller_identity" "current" {}

#Get AWS Current Region
data "aws_region" "current" {}

