# AWS CloudTrail Event Processing Pipeline
This repository defines a modular Terraform-based AWS infrastructure for securely ingesting, processing, and alerting on key CloudTrail events. It demonstrates production-grade practices using:

📜 CloudTrail → 🪣 S3 → 📩 SQS → 🧠 Lambda → 🗄️ DynamoDB + 🔔 SNS Alerts

🔐 Encrypted via KMS and managed with IAM roles/policies


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

7. sns_alerts
Creates an SNS topic for sending alert notifications when monitored events are detected.

Inputs:

topic_name – SNS topic name

alert_email – Email address to subscribe

Outputs:

sns_topic_arn

8. iam_lambda_execution
Creates a least-privilege IAM role and policy for Lambda to:

Read KMS-encrypted S3 log files

Consume SQS messages

Write to DynamoDB

Publish to SNS

Log to CloudWatch

Inputs:

role_name

sqs_arn

s3_bucket_arn

dynamodb_arn

sns_arn

Outputs:

role_name

role_arn

9. lambda_cloudtrail_processor
Deploys a Lambda function that:

Triggers from SQS

Reads and parses S3 CloudTrail log files

Filters for specific monitoredEvents (from a JSON file)

Saves matched events to DynamoDB

Publishes alerts to SNS

Inputs:

lambda_zip_path – Zipped deployment package path

lambda_zip_hash – SHA256 hash of the archive

lambda_src_path – Source folder (optional)

sqs_arn, dynamodb_arn, s3_bucket_arn, sns_arn

🧪 Event Filtering Logic
The Lambda function filters for event names listed in a monitored_events.json file such as:

json
Copy
Edit
{
  "monitoredEvents": [
    "ConsoleLogin",
    "CreateUser",
    "StartInstances",
    "DeleteBucket",
    "PutBucketPolicy"
  ]
}
📌 Recommended Deployment Order
tf_backend → initialize backend

kms

s3_cloudtrail

cloudtrail_to_s3

sqs

dynamodb_log_table

sns_alerts

iam_lambda_execution

lambda_cloudtrail_processor

📁 Supporting Files
lambda/index.py — Main Lambda function logic

monitored_events.json — Event types to watch

.gitignore — Exclude .terraform/, *.tfstate, lambda.zip



# Terraform

To run Terraform the code you will need to configure the following:

- IAM API access to root Terraform account or a CI/CD pipeline with everything configured
- Confirm AWS acccount to use: Update backend.tf and provider.tf with S3 bucket where terrraform code will be stored and what IAM role to use, IAM role should simply just be updating the account number  in the role
- Move to directory where source code is located (i.e. main dir, cd environment/dev, or cd environment/workload)
- Initialize, Plan, and Apply Terraform Code:
```bash
$ terraform init
$ terraform plan
$ terraform apply
```
- Leverage Modules located in modules folder for repeatable deployments (VPCs, VPC endpoints, Security Groups, etc)

