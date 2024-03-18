data "archive_file" "placeholder_zip" {
  type        = "zip"
  source_file = "placeholder.py"
  output_path = "placeholder.zip"
}
module "api_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.2"

  function_name                     = "${var.lambda_function_name}-${random_id.this.hex}"
  description                       = "Export Monday raw data for the timebooking in the data analytics platform."
  handler                           = "app.lambda_handler"
  runtime                           = "python3.9"
  create_role                       = false
  lambda_role                       = aws_iam_role.api_lambda_role.arn
  timeout                           = 600
  publish                           = true
  ignore_source_code_hash           = true
  cloudwatch_logs_retention_in_days = 365
  allowed_triggers = {
    APIGatewayAny = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }

  environment_variables = {
    DB_URL = module.api_database.db_instance_endpoint,
    DB_CREDENTIALS_SECRETS_NAME = aws_secretsmanager_secret.db_credentials.name,
    S3_BUCKET_NAME      = module.s3_bucket.s3_bucket_id
  }
  create_package         = false
  local_existing_package = "placeholder.zip"
}