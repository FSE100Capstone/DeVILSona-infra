############################################
# API Gateway HTTP API (+ /session, /login)
############################################

# 1) HTTP API Create
resource "aws_apigatewayv2_api" "session_api" {
  name          = "FSE100-Session-API"
  protocol_type = "HTTP"
}

#2) /session → save_session Lambda integration
resource "aws_apigatewayv2_integration" "session_integration" {
  api_id                 = aws_apigatewayv2_api.session_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.save_session.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

#3) /login → login Lambda integration
resource "aws_apigatewayv2_integration" "login_integration" {
  api_id                 = aws_apigatewayv2_api.session_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.login.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# 5) POST /session route
resource "aws_apigatewayv2_route" "session_route" {
  api_id    = aws_apigatewayv2_api.session_api.id
  route_key = "POST /session"
  target    = "integrations/${aws_apigatewayv2_integration.session_integration.id}"
}

# 5) POST /login route
resource "aws_apigatewayv2_route" "login_route" {
  api_id    = aws_apigatewayv2_api.session_api.id
  route_key = "POST /login"
  target    = "integrations/${aws_apigatewayv2_integration.login_integration.id}"
}

#6) Default Stage settings ($default, auto-deploy)
resource "aws_apigatewayv2_stage" "session_stage" {
  api_id      = aws_apigatewayv2_api.session_api.id
  name        = "$default"
  auto_deploy = true
}
#7) API Gateway permission to call save_session Lambda
resource "aws_lambda_permission" "allow_apigw_invoke_session" {
  statement_id  = "AllowAPIGatewayInvokeSession"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.save_session.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.session_api.execution_arn}/*/*"
}

#8) API Gateway's permission to call login Lambda
resource "aws_lambda_permission" "allow_apigw_invoke_login" {
  statement_id  = "AllowAPIGatewayInvokeLogin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.session_api.execution_arn}/*/*"
}


# 베이스 API Endpoint (예: https://abcd1234.execute-api.us-west-2.amazonaws.com)
output "session_api_base_url" {
  description = "Base invoke URL for the Session/Login API"
  value       = aws_apigatewayv2_api.session_api.api_endpoint
}

