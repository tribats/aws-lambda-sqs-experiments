output "queue-arn" {
  value = "${module.queue.arn}"
}

output "producer-endpoint" {
  value = "https://${module.api_gateway.domain}/just-queue-it"
}

output "consumer-endpoint" {
  value = "https://${module.api_gateway.domain}/show-me-what-you-got"
}
