variable "name_prefix" {
  type        = "string"
  description = "Name prefix"
}

variable "env" {
  type        = "string"
  description = "Environment"
}

variable "service" {
  type = "string"
}

variable visibility_timeout_seconds {
  default = 30 # 30 seconds
}

variable message_retention_seconds {
  default = 345600 # 4 days
}

variable max_message_size {
  default = 262144 # 256 KiB
}

variable delay_seconds {
  default = 0
}

variable receive_wait_time_seconds {
  default = 0
}

variable policy {
  default = ""
}

variable redrive_policy {
  default = ""
}

variable fifo_queue {
  default = false
}

variable content_based_deduplication {
  default = false
}

variable additional_tags {
  default = {}
}
