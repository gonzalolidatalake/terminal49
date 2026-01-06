# Pub/Sub Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "webhook_events_topic_name" {
  description = "Name of the main webhook events topic"
  type        = string
}

variable "dlq_topic_name" {
  description = "Name of the dead letter queue topic"
  type        = string
}

variable "webhook_receiver_sa_email" {
  description = "Service account email for webhook receiver"
  type        = string
}

variable "event_processor_sa_email" {
  description = "Service account email for event processor"
  type        = string
}

variable "message_retention_duration" {
  description = "Message retention duration (e.g., '604800s' for 7 days)"
  type        = string
  default     = "604800s"
}

variable "ack_deadline_seconds" {
  description = "Acknowledgement deadline in seconds"
  type        = number
  default     = 120
}

variable "max_delivery_attempts" {
  description = "Maximum delivery attempts before sending to DLQ"
  type        = number
  default     = 5
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
