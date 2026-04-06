############################################
# Custom Domain: devilsona.click (Route 53)
############################################

locals {
  api_domain_name = "api.devilsona.click"
  zone_name       = "devilsona.click"
}

# Lookup the hosted zone for devilsona.click
data "aws_route53_zone" "api_zone" {
  name         = local.zone_name
  private_zone = false
}

# Request an ACM certificate in the same region as the HTTP API (us-east-2)
resource "aws_acm_certificate" "api_cert" {
  domain_name       = local.api_domain_name
  validation_method = "DNS"
}

# Create DNS records for ACM validation
resource "aws_route53_record" "api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.api_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "api_cert_validation" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.api_cert_validation : r.fqdn]
}

# API Gateway custom domain
resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name = local.api_domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_cert_validation.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# Map the HTTP API to the custom domain root
resource "aws_apigatewayv2_api_mapping" "api_root_mapping" {
  api_id      = aws_apigatewayv2_api.session_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain.id
  stage       = aws_apigatewayv2_stage.session_stage.name
}

# Route 53 alias record to API Gateway domain
resource "aws_route53_record" "api_alias" {
  zone_id = data.aws_route53_zone.api_zone.zone_id
  name    = local.api_domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

output "session_api_custom_domain" {
  description = "Custom domain for the Session/Login API"
  value       = "https://${local.api_domain_name}"
}
