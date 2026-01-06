# Cloud Function Module - Main Configuration
# Reusable module for deploying Cloud Functions (2nd gen)

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Determine if this is an HTTP or Pub/Sub triggered function
  is_http_trigger   = var.trigger_type == "http"
  is_pubsub_trigger = var.trigger_type == "pubsub"

  # Source archive name
  source_archive_name = "${var.function_name}-source.zip"
}

# ============================================================================
# Cloud Storage Bucket for Function Source
# ============================================================================

resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-${var.function_name}-source"
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  force_destroy               = var.environment != "production"

  labels = var.labels
}

# ============================================================================
# Archive Function Source Code
# ============================================================================

data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/tmp/${local.source_archive_name}"
}

# ============================================================================
# Upload Source to Cloud Storage
# ============================================================================

resource "google_storage_bucket_object" "function_source" {
  name   = "${var.function_name}/${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_source.output_path

  depends_on = [data.archive_file.function_source]
}

# ============================================================================
# Cloud Function (2nd Gen)
# ============================================================================

resource "google_cloudfunctions2_function" "function" {
  name        = var.function_name
  project     = var.project_id
  location    = var.region
  description = var.function_description

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count    = var.max_instance_count
    min_instance_count    = var.min_instance_count
    available_memory      = "${var.available_memory_mb}M"
    timeout_seconds       = var.timeout_seconds
    service_account_email = var.service_account_email

    environment_variables = var.environment_variables

    # Ingress settings (only for HTTP functions)
    ingress_settings = local.is_http_trigger ? var.ingress_settings : null

    # VPC connector (if specified)
    vpc_connector                 = var.vpc_connector
    vpc_connector_egress_settings = var.vpc_connector != null ? var.vpc_connector_egress_settings : null
  }

  # HTTP trigger configuration
  dynamic "event_trigger" {
    for_each = local.is_pubsub_trigger ? [1] : []
    content {
      trigger_region        = var.region
      event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
      pubsub_topic          = var.pubsub_topic
      retry_policy          = var.retry_on_failure ? "RETRY_POLICY_RETRY" : "RETRY_POLICY_DO_NOT_RETRY"
      service_account_email = var.service_account_email
    }
  }

  labels = var.labels

  depends_on = [google_storage_bucket_object.function_source]
}

# ============================================================================
# IAM Policy for HTTP Functions (Allow Unauthenticated Access)
# ============================================================================

resource "google_cloudfunctions2_function_iam_member" "invoker" {
  count = local.is_http_trigger && var.allow_unauthenticated_invocations ? 1 : 0

  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"

  depends_on = [google_cloudfunctions2_function.function]
}
