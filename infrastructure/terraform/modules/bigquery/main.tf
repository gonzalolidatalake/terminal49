# BigQuery Module - Main Configuration
# Creates BigQuery datasets and tables for Terminal49 webhook data

# ============================================================================
# Data Sources
# ============================================================================

# Get project information to construct service account names
data "google_project" "project" {
  project_id = var.project_id
}

# ============================================================================
# BigQuery Dataset
# ============================================================================

resource "google_bigquery_dataset" "terminal49_raw_events" {
  dataset_id  = var.dataset_id
  project     = var.project_id
  location    = var.region
  description = "Terminal49 webhook raw events and historical data"

  # Default table expiration (null = never expire)
  default_table_expiration_ms = null

  # Default partition expiration
  default_partition_expiration_ms = var.partition_expiration_days > 0 ? var.partition_expiration_days * 24 * 60 * 60 * 1000 : null

  # Delete contents on destroy (only for non-production)
  delete_contents_on_destroy = var.delete_contents_on_destroy

  labels = var.labels
}

# ============================================================================
# Raw Events Archive Table
# ============================================================================

resource "google_bigquery_table" "raw_events_archive" {
  dataset_id          = google_bigquery_dataset.terminal49_raw_events.dataset_id
  table_id            = var.raw_events_table_id
  project             = var.project_id
  description         = "Raw webhook event payloads for archival and reprocessing"
  deletion_protection = var.environment == "production"

  # Partition filter requirement (top-level field)
  require_partition_filter = true

  # Time partitioning by received_at
  time_partitioning {
    type          = "DAY"
    field         = "received_at"
    expiration_ms = var.partition_expiration_days > 0 ? var.partition_expiration_days * 24 * 60 * 60 * 1000 : null
  }

  # Clustering for better query performance
  clustering = ["event_type", "processing_status", "event_category"]

  schema = jsonencode([
    {
      name        = "event_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique event identifier from Terminal49"
    },
    {
      name        = "notification_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Webhook notification ID from Terminal49"
    },
    {
      name        = "received_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "When webhook was received by our system"
    },
    {
      name        = "event_timestamp"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "Event timestamp from Terminal49 payload"
    },
    {
      name        = "event_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Type of event (e.g., container.transport.vessel_arrived)"
    },
    {
      name        = "event_category"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "High-level category: tracking_request, container, shipment"
    },
    {
      name        = "payload"
      type        = "JSON"
      mode        = "REQUIRED"
      description = "Complete raw JSON payload from Terminal49"
    },
    {
      name        = "payload_size_bytes"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Size of payload in bytes"
    },
    {
      name        = "signature_valid"
      type        = "BOOLEAN"
      mode        = "REQUIRED"
      description = "Whether HMAC signature was valid"
    },
    {
      name        = "signature_header"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Original X-T49-Webhook-Signature header value"
    },
    {
      name        = "processing_status"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Status: received, processed, failed, reprocessed"
    },
    {
      name        = "processing_duration_ms"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Time taken to process event in milliseconds"
    },
    {
      name        = "processing_error"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Error message if processing failed"
    },
    {
      name        = "processed_at"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "When event processing completed"
    },
    {
      name        = "request_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Request ID for correlation across logs"
    },
    {
      name        = "source_ip"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Source IP address of webhook request"
    },
    {
      name        = "user_agent"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "User-Agent header from request"
    },
    {
      name        = "shipment_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Extracted Terminal49 shipment ID"
    },
    {
      name        = "container_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Extracted Terminal49 container ID"
    },
    {
      name        = "tracking_request_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Extracted Terminal49 tracking request ID"
    },
    {
      name        = "bill_of_lading"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Extracted Bill of Lading number"
    },
    {
      name        = "container_number"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Extracted container number"
    },
    {
      name        = "reprocessing_count"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Number of times event was reprocessed"
    },
    {
      name        = "last_reprocessed_at"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "Last reprocessing timestamp"
    }
  ])

  labels = var.labels

  depends_on = [google_bigquery_dataset.terminal49_raw_events]
}

# ============================================================================
# Historical Events Table
# ============================================================================

resource "google_bigquery_table" "events_historical" {
  dataset_id          = google_bigquery_dataset.terminal49_raw_events.dataset_id
  table_id            = var.historical_table_id
  project             = var.project_id
  description         = "Historical events archived from Supabase for long-term storage"
  deletion_protection = var.environment == "production"

  # Partition filter requirement (top-level field)
  require_partition_filter = true

  # Time partitioning by event_timestamp
  time_partitioning {
    type          = "DAY"
    field         = "event_timestamp"
    expiration_ms = var.partition_expiration_days > 0 ? var.partition_expiration_days * 24 * 60 * 60 * 1000 : null
  }

  # Clustering for better query performance
  clustering = ["event_type", "container_id", "location_locode"]

  schema = jsonencode([
    {
      name        = "event_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Terminal49 event ID"
    },
    {
      name        = "container_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Terminal49 container ID"
    },
    {
      name        = "shipment_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Terminal49 shipment ID"
    },
    {
      name        = "event_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Type of transport/status event"
    },
    {
      name        = "event_timestamp"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "When event occurred"
    },
    {
      name        = "location_locode"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "UN/LOCODE of event location"
    },
    {
      name        = "location_name"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Human-readable location name"
    },
    {
      name        = "vessel_name"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Vessel name if applicable"
    },
    {
      name        = "vessel_imo"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Vessel IMO number if applicable"
    },
    {
      name        = "voyage_number"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Voyage number if applicable"
    },
    {
      name        = "data_source"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Source: shipping_line, terminal, ais"
    },
    {
      name        = "raw_data"
      type        = "JSON"
      mode        = "REQUIRED"
      description = "Complete event data"
    },
    {
      name        = "created_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "When record was created in Supabase"
    },
    {
      name        = "archived_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "When record was archived to BigQuery"
    }
  ])

  labels = var.labels

  depends_on = [google_bigquery_dataset.terminal49_raw_events]
}

# ============================================================================
# Processing Metrics Table
# ============================================================================

resource "google_bigquery_table" "processing_metrics" {
  dataset_id          = google_bigquery_dataset.terminal49_raw_events.dataset_id
  table_id            = var.metrics_table_id
  project             = var.project_id
  description         = "Aggregated metrics for webhook processing performance"
  deletion_protection = var.environment == "production"

  # Partition filter requirement (top-level field)
  require_partition_filter = false

  # Time partitioning by metric_date
  time_partitioning {
    type          = "DAY"
    field         = "metric_date"
    expiration_ms = null
  }

  # Clustering for better query performance
  clustering = ["event_type", "event_category"]

  schema = jsonencode([
    {
      name        = "metric_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp of metric (hourly aggregation)"
    },
    {
      name        = "metric_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Date of metric"
    },
    {
      name        = "metric_hour"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Hour of day (0-23)"
    },
    {
      name        = "event_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Type of event"
    },
    {
      name        = "event_category"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "High-level category"
    },
    {
      name        = "total_events"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Total events received"
    },
    {
      name        = "successful_events"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Successfully processed events"
    },
    {
      name        = "failed_events"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Failed processing events"
    },
    {
      name        = "avg_processing_duration_ms"
      type        = "FLOAT"
      mode        = "NULLABLE"
      description = "Average processing duration"
    },
    {
      name        = "p50_processing_duration_ms"
      type        = "FLOAT"
      mode        = "NULLABLE"
      description = "Median processing duration"
    },
    {
      name        = "p95_processing_duration_ms"
      type        = "FLOAT"
      mode        = "NULLABLE"
      description = "95th percentile processing duration"
    },
    {
      name        = "p99_processing_duration_ms"
      type        = "FLOAT"
      mode        = "NULLABLE"
      description = "99th percentile processing duration"
    },
    {
      name        = "max_processing_duration_ms"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Maximum processing duration"
    },
    {
      name        = "avg_payload_size_bytes"
      type        = "FLOAT"
      mode        = "NULLABLE"
      description = "Average payload size"
    },
    {
      name        = "total_payload_bytes"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Total bytes processed"
    },
    {
      name        = "signature_validation_failures"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Number of signature validation failures"
    },
    {
      name        = "calculated_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "When metrics were calculated"
    }
  ])

  labels = var.labels

  depends_on = [google_bigquery_dataset.terminal49_raw_events]
}

# ============================================================================
# BigQuery Scheduled Query for Processing Metrics
# ============================================================================
#
# NOTE: BigQuery scheduled queries are currently DISABLED due to permission requirements.
# The scheduled query feature requires the deploying user to have iam.serviceAccounts.actAs
# permission on the BigQuery Data Transfer service account, which may not be available
# in all deployment environments.
#
# ERROR ENCOUNTERED: googleapi: Error 403: Requesting user does not have
# iam.serviceAccounts.actAs permission to act as service account
# service-{PROJECT_NUMBER}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com
#
# ALTERNATIVE APPROACHES:
# 1. Run the aggregation query manually or via Cloud Scheduler + Cloud Function
# 2. Have an admin grant actAs permission and uncomment the resources below
# 3. Use a custom service account with appropriate permissions
#
# To manually populate metrics, run this query in BigQuery:
# INSERT INTO `{project}.{dataset}.processing_metrics`
# SELECT
#   TIMESTAMP_TRUNC(received_at, HOUR) as metric_timestamp,
#   DATE(received_at) as metric_date,
#   EXTRACT(HOUR FROM received_at) as metric_hour,
#   event_type,
#   event_category,
#   COUNT(*) as total_events,
#   SUM(CASE WHEN processing_status = 'processed' THEN 1 ELSE 0 END) as successful_events,
#   SUM(CASE WHEN processing_status = 'failed' THEN 1 ELSE 0 END) as failed_events,
#   AVG(processing_duration_ms) as avg_processing_duration_ms,
#   APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(50)] as p50_processing_duration_ms,
#   APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(95)] as p95_processing_duration_ms,
#   APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(99)] as p99_processing_duration_ms,
#   MAX(processing_duration_ms) as max_processing_duration_ms,
#   AVG(payload_size_bytes) as avg_payload_size_bytes,
#   SUM(payload_size_bytes) as total_payload_bytes,
#   SUM(CASE WHEN signature_valid = false THEN 1 ELSE 0 END) as signature_validation_failures,
#   CURRENT_TIMESTAMP() as calculated_at
# FROM `{project}.{dataset}.raw_events_archive`
# WHERE TIMESTAMP_TRUNC(received_at, HOUR) = TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR), HOUR)
# GROUP BY metric_timestamp, metric_date, metric_hour, event_type, event_category;

# COMMENTED OUT - Requires actAs permission
# resource "google_bigquery_data_transfer_config" "processing_metrics_hourly" {
#   display_name           = "Hourly Processing Metrics Aggregation"
#   location               = var.region
#   data_source_id         = "scheduled_query"
#   schedule               = "every hour"
#   destination_dataset_id = google_bigquery_dataset.terminal49_raw_events.dataset_id
#   service_account_name   = "service-${data.google_project.project.number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
#
#   params = {
#     query = <<-SQL
#       INSERT INTO `${var.project_id}.${var.dataset_id}.${var.metrics_table_id}`
#       SELECT
#         TIMESTAMP_TRUNC(received_at, HOUR) as metric_timestamp,
#         DATE(received_at) as metric_date,
#         EXTRACT(HOUR FROM received_at) as metric_hour,
#         event_type,
#         event_category,
#         COUNT(*) as total_events,
#         SUM(CASE WHEN processing_status = 'processed' THEN 1 ELSE 0 END) as successful_events,
#         SUM(CASE WHEN processing_status = 'failed' THEN 1 ELSE 0 END) as failed_events,
#         AVG(processing_duration_ms) as avg_processing_duration_ms,
#         APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(50)] as p50_processing_duration_ms,
#         APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(95)] as p95_processing_duration_ms,
#         APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(99)] as p99_processing_duration_ms,
#         MAX(processing_duration_ms) as max_processing_duration_ms,
#         AVG(payload_size_bytes) as avg_payload_size_bytes,
#         SUM(payload_size_bytes) as total_payload_bytes,
#         SUM(CASE WHEN signature_valid = false THEN 1 ELSE 0 END) as signature_validation_failures,
#         CURRENT_TIMESTAMP() as calculated_at
#       FROM `${var.project_id}.${var.dataset_id}.raw_events_archive`
#       WHERE TIMESTAMP_TRUNC(received_at, HOUR) = TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR), HOUR)
#       GROUP BY metric_timestamp, metric_date, metric_hour, event_type, event_category
#     SQL
#   }
#
#   depends_on = [
#     google_bigquery_table.processing_metrics,
#     google_bigquery_table.raw_events_archive,
#     google_bigquery_dataset_iam_member.scheduled_query_editor,
#     google_project_iam_member.bigquery_transfer_service_agent
#   ]
# }

# ============================================================================
# IAM Bindings
# ============================================================================

# COMMENTED OUT - Only needed if scheduled query is enabled
# resource "google_bigquery_dataset_iam_member" "scheduled_query_editor" {
#   dataset_id = google_bigquery_dataset.terminal49_raw_events.dataset_id
#   role       = "roles/bigquery.dataEditor"
#   member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
#
#   depends_on = [google_bigquery_dataset.terminal49_raw_events]
# }

# COMMENTED OUT - Only needed if scheduled query is enabled
# resource "google_project_iam_member" "bigquery_transfer_service_agent" {
#   project = var.project_id
#   role    = "roles/bigquerydatatransfer.serviceAgent"
#   member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
# }

# NOTE: Additional IAM bindings are managed in the service_accounts module
# to avoid circular dependencies and duplicate bindings
