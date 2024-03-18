output "api_endpoint" {
  value = module.api_gateway.apigatewayv2_api_api_endpoint
}

output "lambda_functiohn_name" {
  value = module.lambda.lambda_function_name
}