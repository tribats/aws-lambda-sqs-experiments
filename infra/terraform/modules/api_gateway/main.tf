data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "certificate" {
  domain      = "${var.domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "zone" {
  name = "${var.domain}."
}

resource "aws_api_gateway_domain_name" "domain" {
  certificate_arn = "${data.aws_acm_certificate.certificate.arn}"
  domain_name     = "${var.subdomain}.${var.domain}"
}

resource "aws_route53_record" "dns" {
  name    = "${aws_api_gateway_domain_name.domain.domain_name}"
  type    = "A"
  zone_id = "${data.aws_route53_zone.zone.id}"

  alias {
    evaluate_target_health = true
    name                   = "${aws_api_gateway_domain_name.domain.cloudfront_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.domain.cloudfront_zone_id}"
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name = "lambda-sqs-example-api"
}

### POST just-queue-it

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "just-queue-it"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.api_resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_method_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.api_resource.id}"
  http_method             = "${aws_api_gateway_method.api_method.http_method}"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_arn}/invocations"
  integration_http_method = "POST"
}

### POST show-me-what-you-got

resource "aws_api_gateway_resource" "consumer_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "show-me-what-you-got"
}

resource "aws_api_gateway_method" "consumer_api_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.consumer_api_resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "consumer_api_method_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.consumer_api_resource.id}"
  http_method             = "${aws_api_gateway_method.api_method.http_method}"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.consumer_lambda_arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    "aws_api_gateway_method.api_method",
    "aws_api_gateway_integration.api_method_integration",
    "aws_api_gateway_method.consumer_api_method",
    "aws_api_gateway_integration.consumer_api_method_integration",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "prod"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.lambda_arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}*"
}

resource "aws_lambda_permission" "apigw_consumer_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.consumer_lambda_arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}*"
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id      = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${aws_api_gateway_deployment.deployment.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.domain.domain_name}"
}
