module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"
  version = "4.0.0"

  name          = "project-api-gateway"
  description   = "API gateway for project api"
  protocol_type = "HTTP"
  create_api_domain_name = false

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }
  
  integrations = {
    "ANY /" = {
      lambda_arn             = module.api_lambda.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "$default" = {
      lambda_arn = module.api_lambda.lambda_function_arn
    }
  }
}