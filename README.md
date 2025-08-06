# AWS CloudTrail Event Processing Pipeline
This repository defines a modular Terraform-based AWS infrastructure for securely ingesting, processing, and alerting on key CloudTrail events. It demonstrates production-grade practices using:

CloudTrail →  S3 →  SQS →  Lambda →  DynamoDB +  SNS Alerts

Encrypted via KMS and managed with IAM roles/policies

## Best Practices Applied  

- KMS Encrypts/Decrypts data for Cloudtrail, S3, and Lambda
- SQS is durable queuing between log delivery and processing in Lambda. Which provides better control over throttling, error handling, and batching
- IAM Role is using best practice zero trust polcies but limiting specific priviledges to specific ARNs/resources
- DynamoDB, SQS, SNS are secure by AWS with either at-rest or in-transit encryption for data

## Recommended Deployment Order
1. Update backend.tf or change/delete file name if saving state file locally  
2. Update data.tf file as needed, otherwise file is using local lambda code in ./lambda-src folder  
3. Update modules data in main.tf file as needed  
4. Confirm CLI access in correct AWS account
5. Initate Standard Terraform procdures
```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Terraform Modules Overview  
1. KMS [modules/kms](./modules/kms/)
Creates a customer-managed KMS key for encrypting:

CloudTrail logs
S3 bucket (log storage)
Lambda Function Access to Decrypt S3 Bucket files

Inputs:

```bash
#Example
  description      = "KMS key for CloudTrail and S3 log encryption"
  alias            = "cloudtrail"
  allow_cloudtrail = true
  account_num      = data.aws_caller_identity.current.account_id
  lambda_role_name = module.lambda_iam.lambda_role_name
```

alias – KMS key alias (e.g., cloudtrail-logs-key)  
allow_cloudtrail – Whether to grant CloudTrail access  
description – Key description  
account_num - AWS Account Number  
lambda_role_name - Allows Lambda IAM role access to KMS  

Outputs:

key_arn  
key_id  
alias_name  
  
2. s3_bucket [modules/s3](./modules/s3/)  
Provisions the S3 bucket for CloudTrail log storage.  
Inputs:
```bash
#Example
  bucket_name            = "security-cloudtrail-logs"
  account_num            = data.aws_caller_identity.current.account_id
  kms_key_arn            = module.kms_cloudtrail.key_arn
  sqs_queue_arn          = module.cloudtrail-analyzer-sqs.queue_arn # If sqs_s3_delivery_enable = true
  sqs_s3_delivery_enable = true                                   # Set True S3 SQS Delivery for Cloudtrail Logs
```

bucket_name – Unique S3 bucket name  
kms_key_arn – KMS key for server-side encryption  
account_num - Account number, added to S3 Bucket naming  
sqs_queue_arn - ARN needed for SQS to be used, required if sqs_s3_delivery_enable = true
sqs_s3_delivery_enable - Adds SQS ARN to S3 Bucket if true  

Outputs:  
bucket_id   
bucket_arn

4. cloudtrail [modules/cloudtrail](./modules/cloudtrail/)  
Deploys CloudTrail configured to write logs to an encrypted S3 bucket.  

Inputs:
```bash
#Example
  cloudtrail_name   = "cloudtrail-analyzer"
  cloudtrail_bucket = module.s3-cloudtrail.bucket_id
  kms_key_arn       = module.kms_cloudtrail.key_arn
```

cloudtrail_name – CloudTrail name  
cloudtrail_bucket – Destination bucket ID  
kms_key_arn - KMS Key ARN needed for encryption of cloudtrail files in S3  

Outputs:

cloudtrail_arn   
cloudtrail_name  

5. SQS Queue [modules/sqs](./modules/sqs/)  
Creates a standard SQS queue for buffering S3 notifications from CloudTrail logs.

Inputs:  
```bash
#Example
  queue_name             = "cloudtrail-analyzer-sqs"
  s3_bucket_arn          = module.s3-cloudtrail.bucket_arn # Required for sqs_s3_delivery_enable = true
  sqs_s3_delivery_enable = true # Enable S3 SQS Communication
```

queue_name - SQS Queue Name  
s3_bucket_arn - Add S3 bucket ARN access for SQS Queue Policy, required if sqs_s3_delivery_enable = true
sqs_s3_delivery_enable - Creates SQS Policy for S3 Bucket ARN  

Outputs:

queue_name  
queue_arn  
queue_url  

6. Dynamodb Table [modules/dynamodb](./modules/dynamodb/)  
Creates a DynamoDB table to persist CloudTrail ConsoleLogin, CreateUser, DeleteUser, and other monitored events.

Inputs:
```bash
#Example
  table_name = "cloudtrail-monitor"
```

table_name – Name of the DynamoDB table  

Outputs:
table_name - DynamoDB Name  
table_arn - DynamoDB Table ARN  

7. SNS [modules/sns](./modules/sns/) 
Creates an SNS topic for sending alert notifications when monitored events are detected via email address.

Inputs:
```bash
#Example
  topic_name   = "cloudtrail-analyzer-alerts"
  alert_emails = ["joelgrayiii@hotmail.com"]
```

topic_name – SNS topic name  
alert_email – Email address to subscribe, list of email users can be provided  

Outputs:

sns_topic_arn - SNS ARN ID needed for lambda function and IAM Policies

8. IAM [modules/iam](./modules/iam/)  
Creates a least-privilege IAM role and policy for Lambda to:

Read KMS-encrypted S3 log files, passed via ROLE ARN in KMS module
Consume SQS messages
Write to DynamoDB
Publish to SNS
Log to CloudWatch

Inputs:
```bash
#Example
  role_name     = "lambda-cloudtrail-analyzer-role"
  sqs_arn       = module.cloudtrail-analyzer-sqs.queue_arn
  s3_bucket_arn = module.s3-cloudtrail.bucket_arn
  dynamodb_arn  = module.cloudtrail-analyzer-db.dynamodb_arn
  sns_arn       = module.cloudtrail-analyzer-sns.sns_topic_arn
```

role_name - Lambda IAM Role Name  
sqs_arn - SQS Trust Policies created  
s3_bucket_arn - S3 Trust Policies created  
dynamodb_arn - DynamoDB Trust Policies created  
sns_arn - SNS Trust Policies Created  

Outputs:
lambda_role_name - IAM Role Name  
lambda_role_arn - IAM Role ARN  

9. Lambda Function [modules/lambda](./modules/lambda/) 
Deploys a Lambda function that:

Triggers from SQS  
Reads and parses S3 CloudTrail log files  
Filters for specific monitoredEvents (from a JSON file), located in [monitored_event.json](./lambda-src/monitored_events.json)  
Saves matched events to DynamoDB  
Publishes alerts to SNS

Inputs:
```bash
#Located in data.tf file, example for uploading lambda python config with terraform
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-src"
  output_path = "${path.module}/lambda.zip"
}
#Module Example
  function_name       = "cloudtrail-analyzer-function"
  iam_role_arn        = module.lambda_iam.lambda_role_arn
  sqs_queue_arn       = module.cloudtrail-analyzer-sqs.queue_arn # Required if sqs_trigger_enable = true
  sqs_trigger_enable  = true #Enable SQS Trigger for Lambda Function
  dynamodb_table_name = module.cloudtrail-analyzer-db.table_name
  sns_topic_arn       = module.cloudtrail-analyzer-sns.sns_topic_arn
  lambda_zip_hash     = data.archive_file.lambda_zip.output_base64sha256
  lambda_zip_path     = data.archive_file.lambda_zip.output_path
```

lambda_zip_path – Zipped deployment package path  
lambda_zip_hash – SHA256 hash of the archive  
sqs_queue_arn - SQS ARN  
sqs_trigger_enable - If true added SQS ARN, enables SQS for lambda function  
dynamodb_table_name - Passed as an environment variable in the lambda function  
sns_topic_arn - Passed as an environment variable in the lambda function

### Lambda Event Filtering Logic
The Lambda function filters for event names listed in a monitored_events.json file such as:

```bash
{
  "monitoredEvents": [
    "ConsoleLogin",
    "CreateUser",
    "StartInstances",
    "DeleteBucket",
    "PutBucketPolicy"
  ]
}
```  

## Supporting Files
lambda/index.py — Main Lambda function logic  
monitored_events.json — Event types to watch  
.gitignore — Exclude .terraform/, *.tfstate, lambda.zip  

## Future Features enhacement
- Add DLQ to SQS in case of failures**
- [FIXED] SQS sends s3:TestEvents which causes an Key error in lambda in Cloudwatch debugging, create python logic to skip if s3:TestEvents are sent from SQS. Refer to file name [sqs-cloudtrail-s3test-example.json](./lambda-src/sqs-cloudtrail-s3test-example.json). Error message:  
[ERROR] KeyError: 'Records'
Traceback (most recent call last):
  File "/var/task/index.py", line 28, in lambda_handler
    for record in s3_event['Records']:   

**Requires:  
 - SQS Queue for DLQ  
 - Redrive Policy in cloudtrail queue  
 - A new lambda function handling notification or process of DLQ messages  



