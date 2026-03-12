# BigQuery Analytics Tables Implementation Plan

**Date**: 2026-01-08  
**Status**: Investigation Complete - Implementation Required  
**Priority**: Phase 1 (HIGH), Phase 2 (MEDIUM)

---

## Investigation Summary

### Tables Status

#### `events_historical`
- **Table exists**: ✅ Yes (Terraform definition)
- **Schema correct**: ✅ Yes
- **Write code exists**: ❌ **NO**
- **Write code is called**: ❌ **NO**
- **IAM permissions**: ✅ Yes (bigquery.dataEditor)
- **Root Cause**: Archival logic never implemented

#### `processing_metrics`
- **Table exists**: ✅ Yes (Terraform definition)
- **Schema correct**: ✅ Yes
- **Write code exists**: ❌ **NO** (SQL template exists in comments only)
- **Write code is called**: ❌ **NO**
- **IAM permissions**: ✅ Yes (bigquery.dataEditor)
- **Root Cause**: Scheduled query never configured

#### `raw_events_archive` (Working Correctly)
- **Table exists**: ✅ Yes
- **Schema correct**: ✅ Yes
- **Write code exists**: ✅ Yes (`bigquery_archiver.py`)
- **Write code is called**: ✅ Yes (every webhook event)
- **IAM permissions**: ✅ Yes
- **Status**: ✅ **WORKING CORRECTLY**

---

## Root Cause Analysis

### Why Tables Aren't Being Populated

1. **`events_historical`**: Designed for archiving old Supabase events (>90 days), but archival Cloud Function was never created
2. **`processing_metrics`**: Designed for hourly metrics aggregation, but BigQuery scheduled query was never configured
3. **Infrastructure-First Development**: Tables were created in anticipation of features, but implementation was deferred

### What IS Working

- ✅ Event processor successfully writes to `raw_events_archive` table
- ✅ BigQuery client initialization works correctly
- ✅ IAM permissions properly configured
- ✅ All webhook events are being archived with complete payloads

---

## Implementation Plan

### **Phase 1: Processing Metrics Collection** ⭐ HIGH PRIORITY

**Goal**: Populate `processing_metrics` with hourly aggregated performance data

**Why This Matters**:
- Enables performance monitoring dashboards
- Tracks processing success/failure rates over time
- Identifies performance degradation trends
- Low implementation effort, high value

**Implementation Steps**:

1. **Create BigQuery Scheduled Query** (Terraform)
   - Add to `infrastructure/terraform/modules/bigquery/main.tf`
   - Use existing SQL template from `bigquery_schema.sql` lines 237-260
   - Schedule: Hourly at :05 minutes past the hour
   - Aggregates previous hour's data from `raw_events_archive`

2. **Terraform Resource**:
```hcl
resource "google_bigquery_data_transfer_config" "processing_metrics_hourly" {
  display_name           = "Hourly Processing Metrics Aggregation"
  location               = var.region
  data_source_id         = "scheduled_query"
  schedule               = "every hour"
  destination_dataset_id = google_bigquery_dataset.terminal49_raw_events.dataset_id
  
  params = {
    query = <<-SQL
      INSERT INTO `${var.project_id}.${var.dataset_id}.${var.metrics_table_id}`
      SELECT 
        TIMESTAMP_TRUNC(received_at, HOUR) as metric_timestamp,
        DATE(received_at) as metric_date,
        EXTRACT(HOUR FROM received_at) as metric_hour,
        event_type,
        event_category,
        COUNT(*) as total_events,
        SUM(CASE WHEN processing_status = 'processed' THEN 1 ELSE 0 END) as successful_events,
        SUM(CASE WHEN processing_status = 'failed' THEN 1 ELSE 0 END) as failed_events,
        AVG(processing_duration_ms) as avg_processing_duration_ms,
        APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(50)] as p50_processing_duration_ms,
        APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(95)] as p95_processing_duration_ms,
        APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(99)] as p99_processing_duration_ms,
        MAX(processing_duration_ms) as max_processing_duration_ms,
        AVG(payload_size_bytes) as avg_payload_size_bytes,
        SUM(payload_size_bytes) as total_payload_bytes,
        SUM(CASE WHEN signature_valid = false THEN 1 ELSE 0 END) as signature_validation_failures,
        CURRENT_TIMESTAMP() as calculated_at
      FROM `${var.project_id}.${var.dataset_id}.raw_events_archive`
      WHERE TIMESTAMP_TRUNC(received_at, HOUR) = TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR), HOUR)
      GROUP BY metric_timestamp, metric_date, metric_hour, event_type, event_category
    SQL
  }
  
  depends_on = [
    google_bigquery_table.processing_metrics,
    google_bigquery_table.raw_events_archive
  ]
}
```

3. **Add IAM Permission for Scheduled Query**:
```hcl
# Allow BigQuery Data Transfer Service to write to dataset
resource "google_bigquery_dataset_iam_member" "scheduled_query_editor" {
  dataset_id = google_bigquery_dataset.terminal49_raw_events.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:bigquery-data-transfer@system.gserviceaccount.com"
}
```

4. **Deploy**:
```bash
cd infrastructure/terraform
terraform plan
terraform apply
```

5. **Validate**:
```sql
-- Check if metrics are being populated (wait 1-2 hours after deployment)
SELECT 
  metric_date,
  metric_hour,
  event_type,
  total_events,
  successful_events,
  failed_events,
  avg_processing_duration_ms
FROM `li-customer-datalake.terminal49_raw_events.processing_metrics`
WHERE metric_date >= CURRENT_DATE()
ORDER BY metric_timestamp DESC
LIMIT 20;
```

**Estimated Effort**: 1-2 hours  
**Cost Impact**: ~$0.01/month (negligible)  
**Benefits**:
- Real-time performance monitoring
- Historical trend analysis
- Automated alerting on performance degradation
- No code maintenance (BigQuery native feature)

---

### **Phase 2: Historical Events Archival** 📊 MEDIUM PRIORITY

**Goal**: Archive old Supabase events to BigQuery for long-term storage and cost optimization

**Why This Matters**:
- Reduces Supabase storage costs (old events moved to cheaper BigQuery storage)
- Enables long-term analytics on historical data
- Maintains operational database performance (smaller Supabase tables)
- Complies with data retention policies

**When to Implement**:
- When Supabase storage exceeds 5GB
- When historical analytics beyond 90 days is needed
- When operational database performance degrades due to table size

**Implementation Steps**:

1. **Create Archival Cloud Function**
   - New function: `functions/supabase_archiver/`
   - Queries Supabase for events older than 90 days
   - Batch inserts to BigQuery `events_historical`
   - Optionally deletes archived events from Supabase

2. **Function Code Structure**:
```python
# functions/supabase_archiver/main.py
"""
Supabase to BigQuery Archival Function

Archives container events older than 90 days from Supabase to BigQuery.
Runs daily via Cloud Scheduler.
"""

import functions_framework
from google.cloud import bigquery
from datetime import datetime, timedelta
import os
import logging
from supabase import create_client, Client

logger = logging.getLogger(__name__)

def _get_supabase_client() -> Client:
    """Initialize Supabase client"""
    url = os.environ.get('SUPABASE_URL')
    key = os.environ.get('SUPABASE_SERVICE_KEY')
    return create_client(url, key)

def _get_bigquery_client() -> bigquery.Client:
    """Initialize BigQuery client"""
    return bigquery.Client()

@functions_framework.http
def archive_old_events(request):
    """
    Archives events older than 90 days from Supabase to BigQuery.
    
    Process:
    1. Query Supabase for events where created_at < (now - 90 days)
    2. Transform to BigQuery schema
    3. Batch insert to events_historical table
    4. Delete from Supabase (if DELETE_AFTER_ARCHIVE=true)
    5. Return statistics
    """
    start_time = datetime.utcnow()
    
    # Configuration
    retention_days = int(os.environ.get('RETENTION_DAYS', '90'))
    batch_size = int(os.environ.get('BATCH_SIZE', '1000'))
    delete_after_archive = os.environ.get('DELETE_AFTER_ARCHIVE', 'false').lower() == 'true'
    
    cutoff_date = datetime.utcnow() - timedelta(days=retention_days)
    
    logger.info(f"Starting archival for events older than {cutoff_date.isoformat()}")
    
    try:
        supabase = _get_supabase_client()
        bq_client = _get_bigquery_client()
        
        project_id = os.environ.get('GCP_PROJECT_ID')
        dataset_id = os.environ.get('BIGQUERY_DATASET_ID', 'terminal49_raw_events')
        table_id = 'events_historical'
        table_ref = f"{project_id}.{dataset_id}.{table_id}"
        
        # Query old events from Supabase
        response = supabase.table('container_events') \
            .select('*') \
            .lt('created_at', cutoff_date.isoformat()) \
            .limit(batch_size) \
            .execute()
        
        events = response.data
        
        if not events:
            logger.info("No events to archive")
            return {"status": "success", "archived_count": 0}
        
        # Transform to BigQuery schema
        rows_to_insert = []
        for event in events:
            row = {
                'event_id': event['event_id'],
                'container_id': event['container_id'],
                'shipment_id': event['shipment_id'],
                'event_type': event['event_type'],
                'event_timestamp': event['event_timestamp'],
                'location_locode': event.get('location_locode'),
                'location_name': event.get('location_name'),
                'vessel_name': event.get('vessel_name'),
                'vessel_imo': event.get('vessel_imo'),
                'voyage_number': event.get('voyage_number'),
                'data_source': event.get('data_source'),
                'raw_data': event.get('raw_data', {}),
                'created_at': event['created_at'],
                'archived_at': datetime.utcnow().isoformat()
            }
            rows_to_insert.append(row)
        
        # Insert to BigQuery
        errors = bq_client.insert_rows_json(table_ref, rows_to_insert)
        
        if errors:
            logger.error(f"BigQuery insert errors: {errors}")
            return {"status": "error", "message": str(errors)}, 500
        
        archived_count = len(rows_to_insert)
        logger.info(f"Successfully archived {archived_count} events to BigQuery")
        
        # Delete from Supabase if configured
        if delete_after_archive:
            event_ids = [event['event_id'] for event in events]
            supabase.table('container_events') \
                .delete() \
                .in_('event_id', event_ids) \
                .execute()
            logger.info(f"Deleted {archived_count} events from Supabase")
        
        duration_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        return {
            "status": "success",
            "archived_count": archived_count,
            "deleted_from_supabase": delete_after_archive,
            "duration_ms": duration_ms,
            "cutoff_date": cutoff_date.isoformat()
        }
        
    except Exception as e:
        logger.error(f"Archival failed: {str(e)}", exc_info=True)
        return {"status": "error", "message": str(e)}, 500
```

3. **Terraform Configuration**:
```hcl
# In infrastructure/terraform/modules/cloud_function/main.tf

# Storage bucket for function source
resource "google_storage_bucket_object" "supabase_archiver_source" {
  name   = "supabase-archiver-${data.archive_file.supabase_archiver_source.output_md5}.zip"
  bucket = google_storage_bucket.functions_source.name
  source = data.archive_file.supabase_archiver_source.output_path
}

data "archive_file" "supabase_archiver_source" {
  type        = "zip"
  source_dir  = "${path.root}/../../functions/supabase_archiver"
  output_path = "${path.root}/.terraform/tmp/supabase_archiver.zip"
}

# Cloud Function
resource "google_cloudfunctions2_function" "supabase_archiver" {
  name     = "supabase-archiver"
  location = var.region
  project  = var.project_id
  
  build_config {
    runtime     = "python311"
    entry_point = "archive_old_events"
    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = google_storage_bucket_object.supabase_archiver_source.name
      }
    }
  }
  
  service_config {
    max_instance_count    = 1
    min_instance_count    = 0
    available_memory      = "512Mi"
    timeout_seconds       = 540  # 9 minutes
    service_account_email = var.event_processor_sa_email
    
    environment_variables = {
      SUPABASE_URL           = var.supabase_url
      SUPABASE_SERVICE_KEY   = var.supabase_service_key
      GCP_PROJECT_ID         = var.project_id
      BIGQUERY_DATASET_ID    = var.bigquery_dataset_id
      RETENTION_DAYS         = "90"
      BATCH_SIZE             = "1000"
      DELETE_AFTER_ARCHIVE   = "false"  # Set to "true" to delete after archival
    }
  }
}

# Cloud Scheduler job to trigger archival daily
resource "google_cloud_scheduler_job" "supabase_archival" {
  name             = "supabase-archival-daily"
  description      = "Daily archival of old Supabase events to BigQuery"
  schedule         = "0 2 * * *"  # Daily at 2 AM UTC
  time_zone        = "UTC"
  attempt_deadline = "600s"
  
  http_target {
    uri         = google_cloudfunctions2_function.supabase_archiver.service_config[0].uri
    http_method = "POST"
    
    oidc_token {
      service_account_email = var.event_processor_sa_email
    }
  }
  
  retry_config {
    retry_count = 3
  }
}
```

4. **Requirements File**:
```txt
# functions/supabase_archiver/requirements.txt
functions-framework==3.*
google-cloud-bigquery==3.*
supabase==2.*
```

5. **Deploy**:
```bash
cd infrastructure/terraform
terraform plan
terraform apply
```

6. **Validate**:
```sql
-- Check archived events
SELECT 
  DATE(archived_at) as archive_date,
  COUNT(*) as archived_events,
  MIN(event_timestamp) as oldest_event,
  MAX(event_timestamp) as newest_event,
  COUNT(DISTINCT container_id) as unique_containers
FROM `li-customer-datalake.terminal49_raw_events.events_historical`
GROUP BY archive_date
ORDER BY archive_date DESC;
```

**Estimated Effort**: 4-6 hours  
**Cost Impact**: ~$0.05/month (daily function execution)  
**Benefits**:
- Reduced Supabase storage costs
- Long-term data retention for compliance
- Historical analytics capabilities
- Improved operational database performance

---

### **Phase 3: Monitoring & Validation** 📈 LOW PRIORITY

**Goal**: Ensure archival processes work correctly and provide visibility

**Implementation Steps**:

1. **Add Monitoring Metrics**:
```hcl
# Alert on processing_metrics population failures
resource "google_monitoring_alert_policy" "metrics_population_failure" {
  display_name = "Processing Metrics Not Populating"
  combiner     = "OR"
  
  conditions {
    display_name = "No metrics in last 2 hours"
    
    condition_threshold {
      filter          = "resource.type=\"bigquery_dataset\" AND metric.type=\"bigquery.googleapis.com/storage/table_count\""
      duration        = "7200s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1
    }
  }
  
  notification_channels = [var.notification_channel_id]
}

# Alert on archival function failures
resource "google_monitoring_alert_policy" "archival_function_failure" {
  display_name = "Supabase Archival Function Failing"
  combiner     = "OR"
  
  conditions {
    display_name = "Function execution errors"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"supabase-archiver\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status!=\"ok\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
    }
  }
  
  notification_channels = [var.notification_channel_id]
}
```

2. **Create Validation Dashboard**:
```hcl
# Add to monitoring dashboards
resource "google_monitoring_dashboard" "bigquery_analytics" {
  dashboard_json = jsonencode({
    displayName = "BigQuery Analytics Pipeline"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Processing Metrics - Hourly Population"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"bigquery_table\" AND resource.labels.table_id=\"processing_metrics\""
                  }
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Historical Events - Daily Archival"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"bigquery_table\" AND resource.labels.table_id=\"events_historical\""
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}
```

3. **Validation Queries**:
```sql
-- Verify processing_metrics completeness
SELECT 
  metric_date,
  COUNT(DISTINCT metric_hour) as hours_with_data,
  SUM(total_events) as total_events_tracked,
  AVG(avg_processing_duration_ms) as avg_duration
FROM `li-customer-datalake.terminal49_raw_events.processing_metrics`
WHERE metric_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY metric_date
ORDER BY metric_date DESC;

-- Expected: 24 hours_with_data per day (if events occurred)

-- Verify events_historical archival rate
SELECT 
  DATE(archived_at) as archive_date,
  COUNT(*) as archived_events,
  COUNT(DISTINCT container