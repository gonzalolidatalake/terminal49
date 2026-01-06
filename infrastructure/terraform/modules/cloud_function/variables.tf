# Cloud Function Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the function"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "function_name" {
  description = "Name of the Cloud Function"
  type        = string
}

variable "function_description" {
  description = "Description of the Cloud Function"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Runtime for the function (e.g., python311)"
  type        = string
  default     = "python311"
}

variable "entry_point" {
  description = "Entry point function name"
  type        = string
}

variable "source_dir" {
  description = "Path to the function source code directory"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the function"
  type        = string
}

variable "trigger_type" {
  description = "Trigger type: 'http' or 'pubsub'"
  type        = string

  validation {
    condition     = contains(["http", "pubsub"], var.trigger_type)
    error_message = "Trigger type must be 'http' or 'pubsub'."
  }
}

variable "pubsub_topic" {
  description = "Pub/Sub topic for event trigger (required if trigger_type is 'pubsub')"
  type        = string
  default     = null
}

variable "retry_on_failure" {
  description = "Whether to retry on failure for Pub/Sub triggers"
  type        = bool
  default     = true
}

variable "https_trigger_security_level" {
  description = "Security level for HTTPS trigger"
  type        = string
  default     = "SECURE_ALWAYS"
}

variable "ingress_settings" {
  description = "Ingress settings for HTTP functions"
  type        = string
  default     = "ALLOW_ALL"
}

variable "allow_unauthenticated_invocations" {
  description = "Allow unauthenticated invocations for HTTP functions"
  type        = bool
  default     = true
}

variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "available_memory_mb" {
  description = "Memory allocation in MB"
  type        = number
  default     = 256
}

variable "timeout_seconds" {
  description = "Function timeout in seconds"
  type        = number
  default     = 60
}

variable "max_instance_count" {
  description = "Maximum number of function instances"
  type        = number
  default     = 100
}

variable "min_instance_count" {
  description = "Minimum number of function instances"
  type        = number
  default     = 0
}

variable "vpc_connector" {
  description = "VPC connector for the function"
  type        = string
  default     = null
}

variable "vpc_connector_egress_settings" {
  description = "VPC connector egress settings"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
}

variable "labels" {
  description = "Labels to apply to the function"
  type        = map(string)
  default     = {}
}
