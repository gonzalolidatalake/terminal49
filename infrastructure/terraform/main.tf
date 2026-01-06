# Terminal49 Webhook Infrastructure - Main Terraform Configuration
# Version: 1.0.0
# Description: Main entry point for Terraform infrastructure

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state management
  backend "gcs" {
    bucket = "li-customer-datalake-terraform-state"
    prefix = "terminal49-webhook-infrastructure"
  }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Common labels for all resources
  common_labels = {
    project     = "terminal49-webhook-infrastructure"
    environment = var.environment
    managed_by  = "terraform"
    team        = "platform"
  }

  # Service account emails
  webhook_receiver_sa_email = "${var.webhook_receiver_sa_name}@${var.project_id}.iam.gserviceaccount.com"
  event_processor_sa_email  = "${var.event_processor_sa_name}@${var.project_id}.iam.gserviceaccount.com"

  # Function names
  webhook_receiver_name = "${var.function_name_prefix}-webhook-receiver-${var.environment}"
  event_processor_name  = "${var.function_name_prefix}-event-processor-${var.environment}"

  # Pub/Sub topic names
  webhook_events_topic = "${var.pubsub_topic_prefix}-webhook-events-${var.environment}"
  dlq_topic            = "${var.pubsub_topic_prefix}-webhook-events-dlq-${var.environment}"
}

# ============================================================================
# Data Sources
# ============================================================================

# Get current project information
data "google_project" "project" {
  project_id = var.project_id
}

# ============================================================================
# Modules
# ============================================================================

# Service Accounts Module (MUST come first - other modules depend on it)
module "service_accounts" {
  source = "./modules/service_accounts"

  project_id  = var.project_id
  environment = var.environment

  webhook_receiver_sa_name = var.webhook_receiver_sa_name
  event_processor_sa_name  = var.event_processor_sa_name
}

# Pub/Sub Module
module "pubsub" {
  source = "./modules/pubsub"

  project_id  = var.project_id
  environment = var.environment

  webhook_events_topic_name = local.webhook_events_topic
  dlq_topic_name            = local.dlq_topic

  webhook_receiver_sa_email = local.webhook_receiver_sa_email
  event_processor_sa_email  = local.event_processor_sa_email

  message_retention_duration = var.pubsub_message_retention_duration
  ack_deadline_seconds       = var.pubsub_ack_deadline_seconds
  max_delivery_attempts      = var.pubsub_max_delivery_attempts

  labels = local.common_labels

  depends_on = [module.service_accounts]
}

# BigQuery Module
module "bigquery" {
  source = "./modules/bigquery"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  dataset_id          = var.bigquery_dataset_id
  raw_events_table_id = var.bigquery_raw_events_table_id
  historical_table_id = var.bigquery_historical_table_id
  metrics_table_id    = var.bigquery_metrics_table_id

  event_processor_sa_email = local.event_processor_sa_email

  partition_expiration_days = var.bigquery_partition_expiration_days
  delete_contents_on_destroy = var.environment != "production"

  labels = local.common_labels

  depends_on = [module.service_accounts]
}

# Cloud Functions Module - Webhook Receiver
module "webhook_receiver" {
  source = "./modules/cloud_function"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  function_name        = local.webhook_receiver_name
  function_description = "Receives and validates Terminal49 webhook notifications"
  entry_point          = "webhook_receiver"
  runtime              = var.function_runtime
  source_dir           = "${path.root}/../../functions/webhook_receiver"

  service_account_email = local.webhook_receiver_sa_email

  # HTTP trigger configuration
  trigger_type = "http"
  https_trigger_security_level = "SECURE_ALWAYS"
  ingress_settings = "ALLOW_ALL"
  allow_unauthenticated_invocations = false  # Private function - auth handled by IT team

  # Environment variables
  environment_variables = {
    GCP_PROJECT_ID              = var.project_id
    PUBSUB_TOPIC                = local.webhook_events_topic
    TERMINAL49_WEBHOOK_SECRET   = var.terminal49_webhook_secret
    LOG_LEVEL                   = var.log_level
    ENVIRONMENT                 = var.environment
    ENABLE_SIGNATURE_VALIDATION = "true"
  }

  # Resource allocation
  available_memory_mb   = var.webhook_receiver_memory_mb
  timeout_seconds       = var.webhook_receiver_timeout_seconds
  max_instance_count    = var.webhook_receiver_max_instances
  min_instance_count    = var.webhook_receiver_min_instances

  labels = local.common_labels

  depends_on = [module.pubsub]
}

# Cloud Functions Module - Event Processor
module "event_processor" {
  source = "./modules/cloud_function"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  function_name        = local.event_processor_name
  function_description = "Processes Terminal49 webhook events and writes to databases"
  entry_point          = "process_webhook_event"
  runtime              = var.function_runtime
  source_dir           = "${path.root}/../../functions/event_processor"

  service_account_email = local.event_processor_sa_email

  # Pub/Sub trigger configuration
  trigger_type = "pubsub"
  pubsub_topic = module.pubsub.webhook_events_topic_id

  # Environment variables
  environment_variables = {
    GCP_PROJECT_ID           = var.project_id
    BIGQUERY_DATASET_ID      = var.bigquery_dataset_id
    SUPABASE_DB_HOST         = var.supabase_db_host
    SUPABASE_DB_PORT         = var.supabase_db_port
    SUPABASE_DB_NAME         = var.supabase_db_name
    SUPABASE_DB_USER         = var.supabase_db_user
    SUPABASE_DB_PASSWORD     = var.supabase_db_password
    LOG_LEVEL                = var.log_level
    ENVIRONMENT              = var.environment
  }

  # Resource allocation (Phase 3 requirements: 512MB, 120s timeout)
  available_memory_mb   = var.event_processor_memory_mb
  timeout_seconds       = var.event_processor_timeout_seconds
  max_instance_count    = var.event_processor_max_instances
  min_instance_count    = var.event_processor_min_instances

  labels = local.common_labels

  depends_on = [module.pubsub, module.bigquery, module.service_accounts]
}

# Monitoring Module
# TODO: Uncomment when event_processor function is implemented
# module "monitoring" {
#   source = "./modules/monitoring"
#
#   project_id  = var.project_id
#   environment = var.environment
#
#   webhook_receiver_function_name = local.webhook_receiver_name
#   event_processor_function_name  = local.event_processor_name
#
#   notification_channels = var.notification_channels
#
#   # Alert thresholds
#   webhook_error_rate_threshold     = var.webhook_error_rate_threshold
#   event_processing_latency_threshold = var.event_processing_latency_threshold
#   dlq_depth_threshold              = var.dlq_depth_threshold
#
#   labels = local.common_labels
#
#   depends_on = [module.webhook_receiver, module.event_processor]
# }

# ============================================================================
# Outputs
# ============================================================================

output "webhook_receiver_url" {
  description = "URL of the webhook receiver Cloud Function"
  value       = module.webhook_receiver.function_url
  sensitive   = false
}

output "webhook_receiver_service_account" {
  description = "Service account email for webhook receiver"
  value       = local.webhook_receiver_sa_email
}

output "event_processor_service_account" {
  description = "Service account email for event processor"
  value       = local.event_processor_sa_email
}

output "pubsub_topic_webhook_events" {
  description = "Pub/Sub topic for webhook events"
  value       = module.pubsub.webhook_events_topic_name
}

output "pubsub_topic_dlq" {
  description = "Pub/Sub dead letter queue topic"
  value       = module.pubsub.dlq_topic_name
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID"
  value       = module.bigquery.dataset_id
}

output "bigquery_raw_events_table" {
  description = "BigQuery raw events table"
  value       = "${module.bigquery.dataset_id}.${var.bigquery_raw_events_table_id}"
}

output "event_processor_function_name" {
  description = "Name of the event processor Cloud Function"
  value       = module.event_processor.function_name
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    project_id               = var.project_id
    region                   = var.region
    environment              = var.environment
    webhook_url              = module.webhook_receiver.function_url
    event_processor_function = module.event_processor.function_name
    pubsub_topic             = local.webhook_events_topic
    bigquery_dataset         = module.bigquery.dataset_id
  }
}
