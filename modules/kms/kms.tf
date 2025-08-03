resource "aws_kms_key" "this" {
  description         = var.description
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "kms-cloudtrail-policy",
    Statement = concat(
      [
        {
          Sid    = "EnableRootAccess",
          Effect = "Allow",
          Principal = {
            AWS = format("arn:aws:iam::%s:root", var.account_num)
          },
          Action   = "kms:*",
          Resource = "*"
        }
      ],
      var.allow_cloudtrail ? [
        {
          Sid    = "AllowCloudTrailAccess",
          Effect = "Allow",
          Principal = {
            Service = "cloudtrail.amazonaws.com"
          },
          Action = [
            "kms:GenerateDataKey*",
            "kms:Decrypt"
          ],
          Resource = "*"
        },
        {
          Sid    = "AllowS3UseKey",
          Effect = "Allow",
          Principal = {
            Service = "s3.amazonaws.com"
          },
          Action = [
            "kms:GenerateDataKey*",
            "kms:Decrypt"
          ],
          Resource = "*"
        },
        #Lockdown lambda functions after testing
        {
          Sid    = "AllowLambdaAccess",
          Effect = "Allow",
          Principal = {
            AWS = format("arn:aws:iam::%s:role/%s", var.account_num, var.lambda_role_name)
          },
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey*"
          ],
          Resource = "*"
        }
      ] : []
    )
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}