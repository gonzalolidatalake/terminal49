# Monitoring Module - Main Configuration
# Creates Cloud Monitoring dashboards and alert policies

# ============================================================================
# Alert Policy: Webhook Error Rate
# ============================================================================

resource "google_monitoring_alert_policy" "webhook_error_rate" {
  display_name = "[${upper(var.environment)}] Terminal49 Webhook Error Rate High"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Webhook error rate > ${var.webhook_error_rate_threshold}%"

    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status!=\"ok\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.webhook_error_rate_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Webhook receiver error rate has exceeded ${var.webhook_error_rate_threshold}%. Check Cloud Function logs for details."
    mime_type = "text/markdown"
  }
}

# ============================================================================
# Alert Policy: Signature Validation Failures
# ============================================================================
# NOTE: Commented out until log-based metric is created by application code
# The metric logging.googleapis.com/user/signature_validation_failed must exist
# before this alert policy can be created. Uncomment after first deployment.

# resource "google_monitoring_alert_policy" "signature_validation_failures" {
#   display_name = "[${upper(var.environment)}] Terminal49 Signature Validation Failures"
#   project      = var.project_id
#   combiner     = "OR"
#
#   conditions {
#     display_name = "Signature validation failures > 10/hour"
#
#     condition_threshold {
#       filter          = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"logging.googleapis.com/user/signature_validation_failed\""
#       duration        = "300s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 10
#
#       aggregations {
#         alignment_period   = "3600s"
#         per_series_aligner = "ALIGN_SUM"
#       }
#     }
#   }
#
#   notification_channels = var.notification_channels
#
#   alert_strategy {
#     auto_close = "3600s"
#   }
#
#   documentation {
#     content   = "Multiple signature validation failures detected. This may indicate an attack or misconfiguration."
#     mime_type = "text/markdown"
#   }
# }

# ============================================================================
# Alert Policy: Event Processing Latency
# ============================================================================

resource "google_monitoring_alert_policy" "event_processing_latency" {
  display_name = "[${upper(var.environment)}] Terminal49 Event Processing Latency High"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Event processing latency > ${var.event_processing_latency_threshold}s (p99)"

    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.event_processing_latency_threshold * 1000 # Convert to ms

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Event processing latency (p99) has exceeded ${var.event_processing_latency_threshold} seconds. Check for database connection issues or high load."
    mime_type = "text/markdown"
  }
}

# ============================================================================
# Alert Policy: Dead Letter Queue Depth
# ============================================================================

resource "google_monitoring_alert_policy" "dlq_depth" {
  display_name = "[${upper(var.environment)}] Terminal49 Dead Letter Queue Depth High"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "DLQ depth > ${var.dlq_depth_threshold} messages"

    condition_threshold {
      filter          = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.labels.subscription_id=monitoring.regex.full_match(\".*dlq.*\")"
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.dlq_depth_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = "Dead letter queue has more than ${var.dlq_depth_threshold} messages. Events are failing to process after multiple retries. Manual intervention required."
    mime_type = "text/markdown"
  }
}

# ============================================================================
# Alert Policy: Cloud Function Error Rate
# ============================================================================

resource "google_monitoring_alert_policy" "function_error_rate" {
  display_name = "[${upper(var.environment)}] Terminal49 Cloud Function Error Rate"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Function error rate > 1%"

    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND (resource.labels.function_name=\"${var.webhook_receiver_function_name}\" OR resource.labels.function_name=\"${var.event_processor_function_name}\") AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status=\"error\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Cloud Function error rate has exceeded 1%. Check function logs for error details."
    mime_type = "text/markdown"
  }
}

# ============================================================================
# Alert Policy: Database Connection Failures
# ============================================================================
# NOTE: Commented out until log-based metric is created by application code
# The metric logging.googleapis.com/user/database_connection_failed must exist
# before this alert policy can be created. Uncomment after first deployment.

# resource "google_monitoring_alert_policy" "database_connection_failures" {
#   display_name = "[${upper(var.environment)}] Terminal49 Database Connection Failures"
#   project      = var.project_id
#   combiner     = "OR"
#
#   conditions {
#     display_name = "Database connection failures detected"
#
#     condition_threshold {
#       filter          = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/database_connection_failed\""
#       duration        = "300s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 5
#
#       aggregations {
#         alignment_period   = "300s"
#         per_series_aligner = "ALIGN_SUM"
#       }
#     }
#   }
#
#   notification_channels = var.notification_channels
#
#   alert_strategy {
#     auto_close = "1800s"
#   }
#
#   documentation {
#     content   = "Multiple database connection failures detected. Check Supabase connectivity and credentials."
#     mime_type = "text/markdown"
#   }
# }

# ============================================================================
# Monitoring Dashboard
# ============================================================================

resource "google_monitoring_dashboard" "terminal49_webhook_infrastructure" {
  dashboard_json = jsonencode({
    displayName = "Terminal49 Webhook Infrastructure - ${upper(var.environment)}"

    mosaicLayout = {
      columns = 12

      tiles = [
        # Webhook Health Section
        {
          xPos   = 0
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Webhook Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Webhook Response Time (p50, p95, p99)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_PERCENTILE_50"
                    }
                  }
                }
              }]
            }
          }
        },
        # Event Processing Section
        {
          xPos   = 0
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Event Processing Latency"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_DELTA"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Pub/Sub Message Age"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/oldest_unacked_message_age\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        # Error Tracking Section
        {
          xPos   = 0
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Error Rate by Function"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status=\"error\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Dead Letter Queue Depth"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.labels.subscription_id=monitoring.regex.full_match(\".*dlq.*\")"
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}
