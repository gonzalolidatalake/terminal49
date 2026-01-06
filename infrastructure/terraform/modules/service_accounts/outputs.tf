# Service Accounts Module - Outputs

output "webhook_receiver_sa_email" {
  description = "Email of the webhook receiver service account"
  value       = google_service_account.webhook_receiver.email
}

output "webhook_receiver_sa_id" {
  description = "ID of the webhook receiver service account"
  value       = google_service_account.webhook_receiver.id
}

output "webhook_receiver_sa_name" {
  description = "Name of the webhook receiver service account"
  value       = google_service_account.webhook_receiver.name
}

output "event_processor_sa_email" {
  description = "Email of the event processor service account"
  value       = google_service_account.event_processor.email
}

output "event_processor_sa_id" {
  description = "ID of the event processor service account"
  value       = google_service_account.event_processor.id
}

output "event_processor_sa_name" {
  description = "Name of the event processor service account"
  value       = google_service_account.event_processor.name
}
