variable "domain" {}

variable "subdomain" {
  type        = "string"
  description = "Custom domain name to use for the API gateway"
}

variable "certificate_arn" {}

variable "lambda_arn" {}
variable "consumer_lambda_arn" {}
