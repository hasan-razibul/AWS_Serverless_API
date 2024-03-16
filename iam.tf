resource "aws_iam_role" "api_lambda_role" {
  name = "${var.lambda_function_name}-role-${random_id.this.hex}"

  assume_role_policy = jsonencode({

    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "api_lambda_s3_and_secrets_cloudwatch_access_policy" {
  name        = "lambda-api-s3-secrets-access-${random_id.this.hex}"
  path        = "/da-tb/"
  description = "Policy for lambda function to access s3 and secrets manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Effect = "Allow"
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*",
        ]
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn
        ]
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = [
          "${module.api_lambda.lambda_cloudwatch_log_group_arn}:*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_lambda_role_policy_attachment" {
  policy_arn = aws_iam_policy.api_lambda_s3_and_secrets_cloudwatch_access_policy.arn
  role       = aws_iam_role.api_lambda_role.name
}