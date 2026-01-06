# Service Accounts Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "webhook_receiver_sa_name" {
  description = "Service account name for webhook receiver"
  type        = string
}

variable "event_processor_sa_name" {
  description = "Service account name for event processor"
  type        = string
}
