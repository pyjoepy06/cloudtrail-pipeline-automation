#Network Diagram Cloudtrail -> S3 -> SQS -> Lambda Function -> SNS

#Create KMS Key for Cloudtrail & S3
module "kms_cloudtrail" {
  source           = "./modules/kms"
  description      = "KMS key for CloudTrail and S3 log encryption"
  alias            = "cloudtrail"
  allow_cloudtrail = true
  account_num      = data.aws_caller_identity.current.account_id
  lambda_role_name = module.lambda_iam.lambda_role_name
}

# Create S3 Bucket for Cloudtrail Logging
module "s3-cloudtrail-bucket" {
  source                 = "./modules/s3"
  bucket_name            = "joel-cloudtrail-logs"
  account_num            = data.aws_caller_identity.current.account_id
  kms_key_arn            = module.kms_cloudtrail.key_arn
  sqs_queue_arn          = module.cloudtrail-analyzer-sqs.queue_arn # Required for S3 to begin sending logs to SQS for Lamabda Functions notifications
  sqs_s3_delivery_enable = true                                     # Set Trueß S3 SQS Delivery for Cloudtrail Logs
}

# Enable Cloudtrail Logging
module "cloudtrail_enable" {
  source            = "./modules/cloudtrail"
  cloudtrail_name   = "cloudtrail-analyzer"
  cloudtrail_bucket = module.s3-cloudtrail-bucket.bucket_id
  kms_key_arn       = module.kms_cloudtrail.key_arn
}

# Create Dynamodb for Cloudtrail/Lambda Analysis
module "cloudtrail-analyzer-db" {
  source     = "./modules/dynamodb"
  table_name = "cloudtrail-monitor"
}

#Create SNS Topic to get emails for alerts
module "cloudtrail-analyzer-sns" {
  source       = "./modules/sns"
  topic_name   = "cloudtrail-analyzer-alerts"
  alert_emails = ["joelgrayiii@hotmail.com"]
}

# Create SQS Queue for Cloudtrail/Lambda Analysis
module "cloudtrail-analyzer-sqs" {
  source                 = "./modules/sqs"
  queue_name             = "cloudtrail-analyzer-sqs"
  s3_bucket_arn          = module.s3-cloudtrail-bucket.bucket_arn
  sqs_s3_delivery_enable = true #Enable S3 SQS Communication
}

module "lambda_iam" {
  source        = "./modules/iam"
  role_name     = "lambda-cloudtrail-analyzer-role"
  sqs_arn       = module.cloudtrail-analyzer-sqs.queue_arn
  s3_bucket_arn = module.s3-cloudtrail-bucket.bucket_arn
  dynamodb_arn  = module.cloudtrail-analyzer-db.dynamodb_arn
  sns_arn       = module.cloudtrail-analyzer-sns.sns_topic_arn
}

module "lambda_anaylzer_function" {
  source              = "./modules/lambda"
  function_name       = "cloudtrail-analyzer-function"
  iam_role_arn        = module.lambda_iam.lambda_role_arn
  sqs_queue_arn       = module.cloudtrail-analyzer-sqs.queue_arn
  sqs_trigger_enable  = true #Enable SQS Trigger for Lambda Function
  dynamodb_table_name = module.cloudtrail-analyzer-db.table_name
  sns_topic_arn       = module.cloudtrail-analyzer-sns.sns_topic_arn
  lambda_zip_hash     = data.archive_file.lambda_zip.output_base64sha256
  lambda_zip_path     = data.archive_file.lambda_zip.output_path
}