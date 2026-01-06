# Pub/Sub Module - Outputs

output "webhook_events_topic_id" {
  description = "ID of the webhook events topic"
  value       = google_pubsub_topic.webhook_events.id
}

output "webhook_events_topic_name" {
  description = "Name of the webhook events topic"
  value       = google_pubsub_topic.webhook_events.name
}

output "dlq_topic_id" {
  description = "ID of the dead letter queue topic"
  value       = google_pubsub_topic.dlq.id
}

output "dlq_topic_name" {
  description = "Name of the dead letter queue topic"
  value       = google_pubsub_topic.dlq.name
}

output "event_processor_subscription_id" {
  description = "ID of the event processor subscription"
  value       = google_pubsub_subscription.event_processor.id
}

output "event_processor_subscription_name" {
  description = "Name of the event processor subscription"
  value       = google_pubsub_subscription.event_processor.name
}

output "dlq_subscription_id" {
  description = "ID of the DLQ subscription"
  value       = google_pubsub_subscription.dlq_subscription.id
}

output "dlq_subscription_name" {
  description = "Name of the DLQ subscription"
  value       = google_pubsub_subscription.dlq_subscription.name
}
