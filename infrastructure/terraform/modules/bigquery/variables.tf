# BigQuery Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for BigQuery dataset"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}

variable "raw_events_table_id" {
  description = "Raw events table ID"
  type        = string
}

variable "historical_table_id" {
  description = "Historical events table ID"
  type        = string
}

variable "metrics_table_id" {
  description = "Processing metrics table ID"
  type        = string
}

variable "event_processor_sa_email" {
  description = "Service account email for event processor"
  type        = string
}

variable "partition_expiration_days" {
  description = "Number of days before partition expiration (0 = never)"
  type        = number
  default     = 730
}

variable "delete_contents_on_destroy" {
  description = "Whether to delete dataset contents on destroy"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
