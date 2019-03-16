locals {
  common_tags = {
    Environment = "${var.env}"
    Service     = "${var.service}"
    Terraform   = "true"
  }
}

resource "aws_sqs_queue" "queue" {
  name_prefix                 = "${var.name_prefix}"
  visibility_timeout_seconds  = "${var.visibility_timeout_seconds}"
  message_retention_seconds   = "${var.message_retention_seconds}"
  max_message_size            = "${var.max_message_size}"
  delay_seconds               = "${var.delay_seconds}"
  receive_wait_time_seconds   = "${var.receive_wait_time_seconds}"
  policy                      = "${var.policy}"
  redrive_policy              = "${var.redrive_policy}"
  fifo_queue                  = "${var.fifo_queue}"
  content_based_deduplication = "${var.content_based_deduplication}"

  kms_master_key_id                 = "${aws_kms_key.kms_key.key_id}"
  kms_data_key_reuse_period_seconds = 3600

  tags = "${merge(local.common_tags, var.additional_tags)}"
}

resource "aws_kms_key" "kms_key" {
  description             = "KMS key for ${var.service} SQS queue ${var.name_prefix}"
  tags                    = "${local.common_tags}"
  deletion_window_in_days = 7
}
