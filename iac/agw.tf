resource "aws_apigatewayv2_api" "http_api" {
  name          = "image-processor-api-${var.entorno}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }

  tags = { Name = "apigw-${var.entorno}" }
}

resource "aws_cloudwatch_log_group" "apigw_logs" {
  name              = "/aws/apigateway/image-processor-api-${var.entorno}"
  retention_in_days = 14

  tags = { Name = "cw-apigw-logs-${var.entorno}" }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true # Stage: default, auto-deploy

  # Format: JSON access log
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_logs.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit = 10000
    throttling_rate_limit  = 10000
  }
}

resource "aws_apigatewayv2_integration" "upload_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload_lambda.invoke_arn
  payload_format_version = "2.0"
}


resource "aws_apigatewayv2_route" "post_upload" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_lambda_integration.id}"
}

resource "aws_lambda_permission" "apigw_invoke_upload" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*/upload"
}

output "api_endpoint" {
  description = "La URL pública para subir las imágenes"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/upload"
}