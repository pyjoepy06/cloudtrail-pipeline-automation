# cloudtrail-pipeline-automation
Cloudtrail Monitoring and Alerting based off Key Events

## ConvergeOne Code Repository for Terraform and CloudFormation

This repository will be used to shared source code, code examples, and templates for FAHW and automating their infrastructure using Terraform and Control Tower management of AWS Accounts

# Terraform

To run Terraform code as a FAHW user you will need to configure the following:

- IAM API access to root Terraform account or a CI/CD pipeline with everything configured
- Confirm AWS acccount to use: Update backend.tf and provider.tf with S3 bucket where terrraform code will be stored and what IAM role to use, IAM role should simply just be updating the account number  in the role
- Move to directory where source code is located (i.e. cd environment/dev or cd environment/workload)
- Initialize, Plan, and Apply Terraform Code:
```bash
$ terraform init
$ terraform plan
$ terraform apply
```
- Leverage Modules located in modules folder for repeatable deployments (VPCs, VPC endpoints, Security Groups, etc)

# CloudFormation

- Leverage Cloudformation StackSets in Master account to deploy IAM assume roles, policies, and S3 Buckets in all accounts or a specific account
- Code examples used for deploying terraform are located [here](IAM_CloudFormation_StackSets)

🔧 AWS CloudTrail Event Processing Pipeline (Terraform Modules)
This repository defines a modular Terraform-based AWS infrastructure for securely ingesting, processing, and alerting on key CloudTrail events. It demonstrates production-grade practices using:

📜 CloudTrail → 🪣 S3 → 📩 SQS → 🧠 Lambda → 🗄️ DynamoDB + 🔔 SNS Alerts

🔐 Encrypted via KMS and managed with IAM roles/policies

☁️ Remote state backed by S3 and DynamoDB for collaboration and safety

📦 Modules Overview
1. tf_backend
Sets up the Terraform backend using:

✅ S3 Bucket for remote state (versioned, encrypted)

✅ DynamoDB Table for state locking

Inputs:

bucket_name – Name of S3 bucket for Terraform state

dynamodb_table_name – Name of DynamoDB table for locking

environment – Environment label (e.g., dev, prod)

Outputs:

s3_bucket_name

dynamodb_table_name

2. kms
Creates a customer-managed KMS key for encrypting:

CloudTrail logs

S3 bucket (log storage)

Optional use with Lambda or DynamoDB

Inputs:

alias – KMS key alias (e.g., cloudtrail-logs-key)

allow_cloudtrail – Whether to grant CloudTrail access

description – Key description

Outputs:

key_arn

key_id

alias_name

3. s3_cloudtrail
Provisions the S3 bucket for CloudTrail log storage.

Inputs:

bucket_name – Unique S3 bucket name

kms_key_arn – KMS key for server-side encryption

Outputs:

bucket_name

bucket_arn

4. cloudtrail_to_s3
Deploys CloudTrail configured to write logs to an encrypted S3 bucket.

Inputs:

trail_name – CloudTrail name

s3_bucket_name – Destination bucket

kms_key_arn – Encryption key (optional)

enable_data_events – Enable object-level tracking

data_event_resources – ARNs of monitored S3 or Lambda resources

Outputs:

cloudtrail_arn

cloudtrail_id

5. sqs (create this if needed)
Creates a standard SQS queue for buffering S3 notifications from CloudTrail logs.

Outputs:

queue_name

queue_arn

queue_url

6. dynamodb_log_table
Creates a DynamoDB table to persist CloudTrail ConsoleLogin and other monitored events.

Inputs:

table_name – Name of the DynamoDB table

Outputs:

table_name

table_arn

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

