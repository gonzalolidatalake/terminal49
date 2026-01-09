# Monitoring Module - Outputs

output "dashboard_id" {
  description = "ID of the monitoring dashboard"
  value       = google_monitoring_dashboard.terminal49_webhook_infrastructure.id
}

output "webhook_error_rate_alert_id" {
  description = "ID of the webhook error rate alert policy"
  value       = google_monitoring_alert_policy.webhook_error_rate.id
}

# NOTE: Commented out because the alert policy is commented out in main.tf
# Uncomment this output when you uncomment the alert policy
# output "signature_validation_failures_alert_id" {
#   description = "ID of the signature validation failures alert policy"
#   value       = google_monitoring_alert_policy.signature_validation_failures.id
# }

output "event_processing_latency_alert_id" {
  description = "ID of the event processing latency alert policy"
  value       = google_monitoring_alert_policy.event_processing_latency.id
}

output "dlq_depth_alert_id" {
  description = "ID of the DLQ depth alert policy"
  value       = google_monitoring_alert_policy.dlq_depth.id
}

output "function_error_rate_alert_id" {
  description = "ID of the function error rate alert policy"
  value       = google_monitoring_alert_policy.function_error_rate.id
}

# NOTE: Commented out because the alert policy is commented out in main.tf
# Uncomment this output when you uncomment the alert policy
# output "database_connection_failures_alert_id" {
#   description = "ID of the database connection failures alert policy"
#   value       = google_monitoring_alert_policy.database_connection_failures.id
# }
