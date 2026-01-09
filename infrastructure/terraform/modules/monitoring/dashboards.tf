# Cloud Monitoring Dashboards for Terminal49 Webhook Infrastructure
# Implements Phase 4 requirements with 4 comprehensive dashboards

# ============================================================================
# Dashboard 1: Webhook Health
# ============================================================================

resource "google_monitoring_dashboard" "webhook_health" {
  dashboard_json = jsonencode({
    displayName = "Terminal49 Webhook Health - ${upper(var.environment)}"

    mosaicLayout = {
      columns = 12

      tiles = [
        # Request Rate
        {
          xPos   = 0
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Webhook Request Rate (requests/min)"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.function_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Requests/min"
                scale = "LINEAR"
              }
            }
          }
        },
        # Response Time Percentiles
        {
          xPos   = 6
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Webhook Response Time (p50, p95, p99)"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [
                {
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
                  plotType       = "LINE"
                  targetAxis     = "Y1"
                  legendTemplate = "p50"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_95"
                      }
                    }
                  }
                  plotType       = "LINE"
                  targetAxis     = "Y1"
                  legendTemplate = "p95"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_99"
                      }
                    }
                  }
                  plotType       = "LINE"
                  targetAxis     = "Y1"
                  legendTemplate = "p99"
                }
              ]
              yAxis = {
                label = "Milliseconds"
                scale = "LINEAR"
              }
              thresholds = [
                {
                  value = 3000
                  label = "SLA Threshold (3s)"
                }
              ]
            }
          }
        },
        # Error Rate
        {
          xPos   = 0
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Error Rate (4xx, 5xx)"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status=\"error\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "5xx Errors"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"logging.googleapis.com/user/http_4xx\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "4xx Errors"
                }
              ]
              yAxis = {
                label = "Errors/min"
                scale = "LINEAR"
              }
            }
          }
        },
        # Signature Validation Failures
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Signature Validation Failures"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"logging.googleapis.com/user/signature_validation_failed\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Failures (5min window)"
                scale = "LINEAR"
              }
              thresholds = [
                {
                  value = 10
                  label = "Alert Threshold"
                }
              ]
            }
          }
        },
        # Success Rate Scorecard
        {
          xPos   = 0
          yPos   = 8
          width  = 3
          height = 3
          widget = {
            title = "Success Rate (Last Hour)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status=\"ok\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        },
        # Total Requests Scorecard
        {
          xPos   = 3
          yPos   = 8
          width  = 3
          height = 3
          widget = {
            title = "Total Requests (Last Hour)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        },
        # Average Response Time Scorecard
        {
          xPos   = 6
          yPos   = 8
          width  = 3
          height = 3
          widget = {
            title = "Avg Response Time (Last Hour)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_MEAN"
                    crossSeriesReducer = "REDUCE_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        },
        # Error Count Scorecard
        {
          xPos   = 9
          yPos   = 8
          width  = 3
          height = 3
          widget = {
            title = "Errors (Last Hour)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status=\"error\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}

# ============================================================================
# Dashboard 2: Event Processing
# ============================================================================

resource "google_monitoring_dashboard" "event_processing" {
  dashboard_json = jsonencode({
    displayName = "Terminal49 Event Processing - ${upper(var.environment)}"

    mosaicLayout = {
      columns = 12

      tiles = [
        # Pub/Sub Message Age
        {
          xPos   = 0
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Pub/Sub Message Age (Oldest Unacked)"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/oldest_unacked_message_age\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MAX"
                      crossSeriesReducer = "REDUCE_MAX"
                      groupByFields      = ["resource.subscription_id"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Seconds"
                scale = "LINEAR"
              }
              thresholds = [
                {
                  value = 30
                  label = "Warning (30s)"
                },
                {
                  value = 60
                  label = "Critical (60s)"
                }
              ]
            }
          }
        },
        # Processing Latency
        {
          xPos   = 6
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Event Processing Latency (p50, p95, p99)"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_50"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "p50"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_95"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "p95"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_99"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "p99"
                }
              ]
              yAxis = {
                label = "Milliseconds"
                scale = "LINEAR"
              }
              thresholds = [
                {
                  value = 10000
                  label = "SLA Threshold (10s)"
                }
              ]
            }
          }
        },
        # Database Write Latency
        {
          xPos   = 0
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Database Write Latency"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/database_write_latency_ms\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Milliseconds"
                scale = "LINEAR"
              }
              thresholds = [
                {
                  value = 100
                  label = "Target (100ms)"
                }
              ]
            }
          }
        },
        # Dead Letter Queue Depth
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Dead Letter Queue Depth"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.labels.subscription_id=monitoring.regex.full_match(\".*dlq.*\")"
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Messages"
                scale = "LINEAR"
              }
              thresholds = [
                {
                  value = 100
                  label = "Alert Threshold"
                }
              ]
            }
          }
        },
        # Processing Rate
        {
          xPos   = 0
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Event Processing Rate"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Events/min"
                scale = "LINEAR"
              }
            }
          }
        },
        # Retry Rate
        {
          xPos   = 6
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Event Retry Rate"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/num_outstanding_messages\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.subscription_id"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Outstanding Messages"
                scale = "LINEAR"
              }
            }
          }
        },
        # Scorecards
        {
          xPos   = 0
          yPos   = 12
          width  = 3
          height = 3
          widget = {
            title = "Events Processed (Last Hour)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status=\"ok\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        },
        {
          xPos   = 3
          yPos   = 12
          width  = 3
          height = 3
          widget = {
            title = "DLQ Messages"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.labels.subscription_id=monitoring.regex.full_match(\".*dlq.*\")"
                  aggregation = {
                    alignmentPeriod    = "60s"
                    perSeriesAligner   = "ALIGN_MAX"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 12
          width  = 3
          height = 3
          widget = {
            title = "Avg Processing Time (Last Hour)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_times\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_MEAN"
                    crossSeriesReducer = "REDUCE_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        },
        {
          xPos   = 9
          yPos   = 12
          width  = 3
          height = 3
          widget = {
            title = "Processing Errors (Last Hour)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status=\"error\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}

# ============================================================================
# Dashboard 3: Data Quality
# ============================================================================

resource "google_monitoring_dashboard" "data_quality" {
  dashboard_json = jsonencode({
    displayName = "Terminal49 Data Quality - ${upper(var.environment)}"

    mosaicLayout = {
      columns = 12

      tiles = [
        # Events by Type (Last 24h)
        {
          xPos   = 0
          yPos   = 0
          width  = 12
          height = 5
          widget = {
            title = "Events by Type (Last 24 Hours)"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/event_type_count\""
                    aggregation = {
                      alignmentPeriod    = "3600s"
                      perSeriesAligner   = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.event_type"]
                    }
                  }
                }
                plotType = "STACKED_AREA"
              }]
              yAxis = {
                label = "Event Count"
                scale = "LINEAR"
              }
            }
          }
        },
        # Duplicate Event Rate
        {
          xPos   = 0
          yPos   = 5
          width  = 6
          height = 4
          widget = {
            title = "Duplicate Event Rate"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/duplicate_event_detected\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Duplicates/min"
                scale = "LINEAR"
              }
            }
          }
        },
        # Null Value Frequency
        {
          xPos   = 6
          yPos   = 5
          width  = 6
          height = 4
          widget = {
            title = "Null Value Frequency by Field"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/null_field_count\""
                    aggregation = {
                      alignmentPeriod    = "3600s"
                      perSeriesAligner   = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.field_name"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
              yAxis = {
                label = "Null Count"
                scale = "LINEAR"
              }
            }
          }
        },
        # Processing Errors by Type
        {
          xPos   = 0
          yPos   = 9
          width  = 12
          height = 4
          widget = {
            title = "Processing Errors by Type"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/processing_error\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.error_type"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
              yAxis = {
                label = "Error Count"
                scale = "LINEAR"
              }
            }
          }
        },
        # Data Completeness Score
        {
          xPos   = 0
          yPos   = 13
          width  = 4
          height = 3
          widget = {
            title = "Data Completeness Score"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/data_completeness_score\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_MEAN"
                    crossSeriesReducer = "REDUCE_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
              thresholds = [
                {
                  value     = 95
                  color     = "YELLOW"
                  direction = "BELOW"
                },
                {
                  value     = 90
                  color     = "RED"
                  direction = "BELOW"
                }
              ]
            }
          }
        },
        # Total Events (24h)
        {
          xPos   = 4
          yPos   = 13
          width  = 4
          height = 3
          widget = {
            title = "Total Events (Last 24h)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                  aggregation = {
                    alignmentPeriod    = "86400s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        },
        # Unique Event Types
        {
          xPos   = 8
          yPos   = 13
          width  = 4
          height = 3
          widget = {
            title = "Unique Event Types (24h)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/unique_event_types\""
                  aggregation = {
                    alignmentPeriod    = "86400s"
                    perSeriesAligner   = "ALIGN_MAX"
                    crossSeriesReducer = "REDUCE_COUNT"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}

# ============================================================================
# Dashboard 4: Infrastructure
# ============================================================================

resource "google_monitoring_dashboard" "infrastructure" {
  dashboard_json = jsonencode({
    displayName = "Terminal49 Infrastructure - ${upper(var.environment)}"

    mosaicLayout = {
      columns = 12

      tiles = [
        # Cloud Function Invocations
        {
          xPos   = 0
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Cloud Function Invocations"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "Webhook Receiver"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "Event Processor"
                }
              ]
              yAxis = {
                label = "Invocations/min"
                scale = "LINEAR"
              }
            }
          }
        },
        # Memory Usage
        {
          xPos   = 6
          yPos   = 0
          width  = 6
          height = 4
          widget = {
            title = "Memory Usage"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.webhook_receiver_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/user_memory_bytes\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_MEAN"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "Webhook Receiver"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"cloudfunctions.googleapis.com/function/user_memory_bytes\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_MEAN"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "Event Processor"
                }
              ]
              yAxis = {
                label = "Bytes"
                scale = "LINEAR"
              }
            }
          }
        },
        # Cold Start Frequency
        {
          xPos   = 0
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Cold Start Frequency"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.execution_trigger=\"cold\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.function_name"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
              yAxis = {
                label = "Cold Starts (5min)"
                scale = "LINEAR"
              }
            }
          }
        },
        # Database Connection Pool Utilization
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Database Connection Pool Utilization"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/db_pool_active_connections\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_MEAN"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "Active Connections"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.event_processor_function_name}\" AND metric.type=\"logging.googleapis.com/user/db_pool_idle_connections\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_MEAN"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "Idle Connections"
                }
              ]
              yAxis = {
                label = "Connections"
                scale = "LINEAR"
              }
            }
          }
        },
        # Active Instances
        {
          xPos   = 0
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Active Function Instances"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/active_instances\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.function_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Instances"
                scale = "LINEAR"
              }
            }
          }
        },
        # Pub/Sub Throughput
        {
          xPos   = 6
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Pub/Sub Message Throughput"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"pubsub_topic\" AND metric.type=\"pubsub.googleapis.com/topic/send_message_operation_count\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "Published"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/pull_message_operation_count\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "Consumed"
                }
              ]
              yAxis = {
                label = "Messages/sec"
                scale = "LINEAR"
              }
            }
          }
        },
        # Scorecards
        {
          xPos   = 0
          yPos   = 12
          width  = 3
          height = 3
          widget = {
            title = "Total Invocations (1h)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        },
        {
          xPos   = 3
          yPos   = 12
          width  = 3
          height = 3
          widget = {
            title = "Avg Memory Usage"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/user_memory_bytes\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_MEAN"
                    crossSeriesReducer = "REDUCE_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 12
          width  = 3
          height = 3
          widget = {
            title = "Cold Starts (1h)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.execution_trigger=\"cold\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        },
        {
          xPos   = 9
          yPos   = 12
          width  = 3
          height = 3
          widget = {
            title = "Active Instances"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/active_instances\""
                  aggregation = {
                    alignmentPeriod    = "60s"
                    perSeriesAligner   = "ALIGN_MAX"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}
