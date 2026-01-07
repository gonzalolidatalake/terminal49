# Terminal49 Webhook Infrastructure - Terraform Variables
# Version: 1.0.0

# ============================================================================
# Project Configuration
# ============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "li-customer-datalake"
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# ============================================================================
# Service Account Configuration
# ============================================================================

variable "webhook_receiver_sa_name" {
  description = "Service account name for webhook receiver"
  type        = string
  default     = "terminal49-webhook-receiver"
}

variable "event_processor_sa_name" {
  description = "Service account name for event processor"
  type        = string
  default     = "terminal49-event-processor"
}

# ============================================================================
# Cloud Functions Configuration
# ============================================================================

variable "function_name_prefix" {
  description = "Prefix for Cloud Function names"
  type        = string
  default     = "terminal49"
}

variable "function_runtime" {
  description = "Runtime for Cloud Functions"
  type        = string
  default     = "python311"
}

# Webhook Receiver Configuration
variable "webhook_receiver_memory_mb" {
  description = "Memory allocation for webhook receiver function (MB)"
  type        = number
  default     = 256
}

variable "webhook_receiver_timeout_seconds" {
  description = "Timeout for webhook receiver function (seconds)"
  type        = number
  default     = 60
}

variable "webhook_receiver_max_instances" {
  description = "Maximum number of webhook receiver instances"
  type        = number
  default     = 100
}

variable "webhook_receiver_min_instances" {
  description = "Minimum number of webhook receiver instances"
  type        = number
  default     = 0
}

# Event Processor Configuration
variable "event_processor_memory_mb" {
  description = "Memory allocation for event processor function (MB)"
  type        = number
  default     = 512
}

variable "event_processor_timeout_seconds" {
  description = "Timeout for event processor function (seconds)"
  type        = number
  default     = 120
}

variable "event_processor_max_instances" {
  description = "Maximum number of event processor instances"
  type        = number
  default     = 50
}

variable "event_processor_min_instances" {
  description = "Minimum number of event processor instances"
  type        = number
  default     = 0
}

# ============================================================================
# Pub/Sub Configuration
# ============================================================================

variable "pubsub_topic_prefix" {
  description = "Prefix for Pub/Sub topic names"
  type        = string
  default     = "terminal49"
}

variable "pubsub_message_retention_duration" {
  description = "Message retention duration for Pub/Sub (seconds)"
  type        = string
  default     = "604800s" # 7 days
}

variable "pubsub_ack_deadline_seconds" {
  description = "Acknowledgement deadline for Pub/Sub messages (seconds)"
  type        = number
  default     = 120
}

variable "pubsub_max_delivery_attempts" {
  description = "Maximum delivery attempts before sending to DLQ"
  type        = number
  default     = 5
}

# ============================================================================
# BigQuery Configuration
# ============================================================================

variable "bigquery_dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
  default     = "terminal49_raw_events"
}

variable "bigquery_raw_events_table_id" {
  description = "BigQuery raw events table ID"
  type        = string
  default     = "raw_events_archive"
}

variable "bigquery_historical_table_id" {
  description = "BigQuery historical events table ID"
  type        = string
  default     = "events_historical"
}

variable "bigquery_metrics_table_id" {
  description = "BigQuery metrics table ID"
  type        = string
  default     = "processing_metrics"
}

variable "bigquery_partition_expiration_days" {
  description = "Number of days before partition expiration (0 = never)"
  type        = number
  default     = 730 # 2 years
}

# ============================================================================
# Supabase Configuration
# ============================================================================

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  default     = "https://srordjhkcvyfyvepzrzp.supabase.co"
}

variable "supabase_service_key" {
  description = "Supabase service role key"
  type        = string
  sensitive   = true
}

variable "supabase_db_host" {
  description = "Supabase database host"
  type        = string
  default     = "db.srordjhkcvyfyvepzrzp.supabase.co"
}

variable "supabase_db_port" {
  description = "Supabase database port"
  type        = string
  default     = "5432"
}

variable "supabase_db_name" {
  description = "Supabase database name"
  type        = string
  default     = "postgres"
}

variable "supabase_db_user" {
  description = "Supabase database user"
  type        = string
  default     = "postgres"
}

variable "supabase_db_password" {
  description = "Supabase database password"
  type        = string
  sensitive   = true
}

# ============================================================================
# Terminal49 Configuration
# ============================================================================

variable "terminal49_webhook_secret" {
  description = "Terminal49 webhook secret for signature validation"
  type        = string
  sensitive   = true
}

# ============================================================================
# Logging Configuration
# ============================================================================

variable "log_level" {
  description = "Logging level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "Log level must be DEBUG, INFO, WARNING, or ERROR."
  }
}

# ============================================================================
# Monitoring Configuration
# ============================================================================

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

# ============================================================================
# Tags and Labels
# ============================================================================

variable "additional_labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
