# Create CloudTrail
resource "aws_cloudtrail" "analyzer_trail" {
  name                          = var.cloudtrail_name
  s3_bucket_name                = var.cloudtrail_bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  kms_key_id                    = var.kms_key_arn
}