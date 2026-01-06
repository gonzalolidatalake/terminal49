# BigQuery Module - Outputs

output "dataset_id" {
  description = "BigQuery dataset ID"
  value       = google_bigquery_dataset.terminal49_raw_events.dataset_id
}

output "dataset_location" {
  description = "BigQuery dataset location"
  value       = google_bigquery_dataset.terminal49_raw_events.location
}

output "raw_events_table_id" {
  description = "Raw events table ID"
  value       = google_bigquery_table.raw_events_archive.table_id
}

output "raw_events_table_full_id" {
  description = "Full table ID for raw events (project:dataset.table)"
  value       = "${var.project_id}:${google_bigquery_dataset.terminal49_raw_events.dataset_id}.${google_bigquery_table.raw_events_archive.table_id}"
}

output "historical_table_id" {
  description = "Historical events table ID"
  value       = google_bigquery_table.events_historical.table_id
}

output "historical_table_full_id" {
  description = "Full table ID for historical events (project:dataset.table)"
  value       = "${var.project_id}:${google_bigquery_dataset.terminal49_raw_events.dataset_id}.${google_bigquery_table.events_historical.table_id}"
}

output "metrics_table_id" {
  description = "Processing metrics table ID"
  value       = google_bigquery_table.processing_metrics.table_id
}

output "metrics_table_full_id" {
  description = "Full table ID for metrics (project:dataset.table)"
  value       = "${var.project_id}:${google_bigquery_dataset.terminal49_raw_events.dataset_id}.${google_bigquery_table.processing_metrics.table_id}"
}
