# Pub/Sub Module - Main Configuration
# Creates Pub/Sub topics and subscriptions for Terminal49 webhook events

# ============================================================================
# Main Webhook Events Topic
# ============================================================================

resource "google_pubsub_topic" "webhook_events" {
  name    = var.webhook_events_topic_name
  project = var.project_id

  message_retention_duration = var.message_retention_duration

  labels = var.labels
}

# ============================================================================
# Dead Letter Queue Topic
# ============================================================================

resource "google_pubsub_topic" "dlq" {
  name    = var.dlq_topic_name
  project = var.project_id

  message_retention_duration = var.message_retention_duration

  labels = var.labels
}

# ============================================================================
# Event Processor Subscription
# ============================================================================

resource "google_pubsub_subscription" "event_processor" {
  name    = "${var.webhook_events_topic_name}-subscription"
  project = var.project_id
  topic   = google_pubsub_topic.webhook_events.name

  # Acknowledgement deadline
  ack_deadline_seconds = var.ack_deadline_seconds

  # Message retention
  message_retention_duration = var.message_retention_duration

  # Retry policy with exponential backoff
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  # Dead letter policy
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  # Enable message ordering (optional, set to false for higher throughput)
  enable_message_ordering = false

  # Expiration policy (never expire)
  expiration_policy {
    ttl = ""
  }

  labels = var.labels

  depends_on = [
    google_pubsub_topic.webhook_events,
    google_pubsub_topic.dlq
  ]
}

# ============================================================================
# Dead Letter Queue Subscription
# ============================================================================

resource "google_pubsub_subscription" "dlq_subscription" {
  name    = "${var.dlq_topic_name}-subscription"
  project = var.project_id
  topic   = google_pubsub_topic.dlq.name

  # Longer acknowledgement deadline for manual processing
  ack_deadline_seconds = 600

  # Retain messages for 7 days
  message_retention_duration = "604800s"

  # No retry policy for DLQ
  # No dead letter policy for DLQ (terminal)

  # Expiration policy (never expire)
  expiration_policy {
    ttl = ""
  }

  labels = var.labels

  depends_on = [google_pubsub_topic.dlq]
}

# ============================================================================
# IAM Bindings
# ============================================================================

# Allow webhook receiver to publish to main topic
resource "google_pubsub_topic_iam_member" "webhook_receiver_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.webhook_events.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.webhook_receiver_sa_email}"
}

# Allow event processor to subscribe to main topic
resource "google_pubsub_subscription_iam_member" "event_processor_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.event_processor.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.event_processor_sa_email}"
}

# Allow event processor to view main topic
resource "google_pubsub_topic_iam_member" "event_processor_viewer" {
  project = var.project_id
  topic   = google_pubsub_topic.webhook_events.name
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${var.event_processor_sa_email}"
}

# Allow event processor to publish to DLQ (for manual reprocessing)
resource "google_pubsub_topic_iam_member" "event_processor_dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dlq.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.event_processor_sa_email}"
}
