# Monitoring Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "webhook_receiver_function_name" {
  description = "Name of the webhook receiver Cloud Function"
  type        = string
}

variable "event_processor_function_name" {
  description = "Name of the event processor Cloud Function"
  type        = string
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "webhook_error_rate_threshold" {
  description = "Threshold for webhook error rate alerts (percentage)"
  type        = number
  default     = 5.0
}

variable "event_processing_latency_threshold" {
  description = "Threshold for event processing latency alerts (seconds)"
  type        = number
  default     = 30
}

variable "dlq_depth_threshold" {
  description = "Threshold for dead letter queue depth alerts"
  type        = number
  default     = 100
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
