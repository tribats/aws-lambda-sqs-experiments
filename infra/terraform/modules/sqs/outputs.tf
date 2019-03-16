output "arn" {
  value       = "${aws_sqs_queue.queue.arn}"
  description = "Queue ARN"
}

output "key_id" {
  value = "${aws_kms_key.kms_key.key_id}"
}
