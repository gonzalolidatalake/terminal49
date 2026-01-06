# Cloud Function Module - Outputs

output "function_name" {
  description = "Name of the Cloud Function"
  value       = google_cloudfunctions2_function.function.name
}

output "function_id" {
  description = "ID of the Cloud Function"
  value       = google_cloudfunctions2_function.function.id
}

output "function_url" {
  description = "URL of the Cloud Function (for HTTP triggers)"
  value       = google_cloudfunctions2_function.function.service_config[0].uri
}

output "function_state" {
  description = "State of the Cloud Function"
  value       = google_cloudfunctions2_function.function.state
}

output "source_bucket" {
  description = "Cloud Storage bucket for function source"
  value       = google_storage_bucket.function_source.name
}

output "source_object" {
  description = "Cloud Storage object for function source"
  value       = google_storage_bucket_object.function_source.name
}
