# Service Accounts Module - Main Configuration
# Creates service accounts with least-privilege IAM roles

# ============================================================================
# Webhook Receiver Service Account
# ============================================================================

resource "google_service_account" "webhook_receiver" {
  account_id   = var.webhook_receiver_sa_name
  project      = var.project_id
  display_name = "Terminal49 Webhook Receiver"
  description  = "Service account for webhook receiver Cloud Function"
}

# ============================================================================
# Event Processor Service Account
# ============================================================================

resource "google_service_account" "event_processor" {
  account_id   = var.event_processor_sa_name
  project      = var.project_id
  display_name = "Terminal49 Event Processor"
  description  = "Service account for event processor Cloud Function"
}

# ============================================================================
# Webhook Receiver IAM Roles
# ============================================================================

# Allow webhook receiver to publish to Pub/Sub
resource "google_project_iam_member" "webhook_receiver_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.webhook_receiver.email}"
}

# Allow webhook receiver to write logs
resource "google_project_iam_member" "webhook_receiver_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.webhook_receiver.email}"
}

# Allow webhook receiver to write metrics
resource "google_project_iam_member" "webhook_receiver_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.webhook_receiver.email}"
}

# ============================================================================
# Event Processor IAM Roles
# ============================================================================

# Allow event processor to subscribe to Pub/Sub
resource "google_project_iam_member" "event_processor_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.event_processor.email}"
}

# Allow event processor to view Pub/Sub topics
resource "google_project_iam_member" "event_processor_pubsub_viewer" {
  project = var.project_id
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.event_processor.email}"
}

# Allow event processor to write to BigQuery
resource "google_project_iam_member" "event_processor_bigquery_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.event_processor.email}"
}

# Allow event processor to create BigQuery jobs
resource "google_project_iam_member" "event_processor_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.event_processor.email}"
}

# Allow event processor to write logs
resource "google_project_iam_member" "event_processor_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.event_processor.email}"
}

# Allow event processor to write metrics
resource "google_project_iam_member" "event_processor_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.event_processor.email}"
}

# ============================================================================
# Cloud Functions IAM (Allow Functions to Use Service Accounts)
# ============================================================================

# Allow Cloud Functions service to use webhook receiver service account
resource "google_service_account_iam_member" "webhook_receiver_user" {
  service_account_id = google_service_account.webhook_receiver.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

# Allow Cloud Functions service to use event processor service account
resource "google_service_account_iam_member" "event_processor_user" {
  service_account_id = google_service_account.event_processor.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}
