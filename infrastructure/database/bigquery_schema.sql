-- Terminal49 Webhook Infrastructure - BigQuery Schema
-- Version: 1.0.0
-- Date: 2026-01-02
-- Description: Schema for raw event archival and analytical queries

-- ============================================================================
-- DATASET: terminal49_raw_events
-- Description: Dataset for storing all raw webhook events
-- ============================================================================

-- Create dataset (execute via gcloud or Terraform)
-- gcloud bigquery datasets create terminal49_raw_events \
--   --project=li-customer-datalake \
--   --location=us-central1 \
--   --description="Terminal49 webhook raw events archive"

-- ============================================================================
-- TABLE: raw_events_archive
-- Description: Stores all raw webhook payloads for debugging and reprocessing
-- ============================================================================

CREATE TABLE IF NOT EXISTS `li-customer-datalake.terminal49_raw_events.raw_events_archive`
(
  -- Event identification
  event_id STRING NOT NULL OPTIONS(description="Unique event identifier from Terminal49"),
  notification_id STRING OPTIONS(description="Webhook notification ID from Terminal49"),
  
  -- Timing information
  received_at TIMESTAMP NOT NULL OPTIONS(description="When webhook was received by our system"),
  event_timestamp TIMESTAMP OPTIONS(description="Event timestamp from Terminal49 payload"),
  
  -- Event classification
  event_type STRING NOT NULL OPTIONS(description="Type of event (e.g., container.transport.vessel_arrived)"),
  event_category STRING OPTIONS(description="High-level category: tracking_request, container, shipment"),
  
  -- Payload data
  payload JSON NOT NULL OPTIONS(description="Complete raw JSON payload from Terminal49"),
  payload_size_bytes INT64 OPTIONS(description="Size of payload in bytes"),
  
  -- Security and validation
  signature_valid BOOLEAN NOT NULL OPTIONS(description="Whether HMAC signature was valid"),
  signature_header STRING OPTIONS(description="Original X-T49-Webhook-Signature header value"),
  
  -- Processing metadata
  processing_status STRING NOT NULL OPTIONS(description="Status: received, processed, failed, reprocessed"),
  processing_duration_ms INT64 OPTIONS(description="Time taken to process event in milliseconds"),
  processing_error STRING OPTIONS(description="Error message if processing failed"),
  processed_at TIMESTAMP OPTIONS(description="When event processing completed"),
  
  -- Request metadata
  request_id STRING OPTIONS(description="Request ID for correlation across logs"),
  source_ip STRING OPTIONS(description="Source IP address of webhook request"),
  user_agent STRING OPTIONS(description="User-Agent header from request"),
  
  -- Data extraction (for quick queries without parsing JSON)
  shipment_id STRING OPTIONS(description="Extracted Terminal49 shipment ID"),
  container_id STRING OPTIONS(description="Extracted Terminal49 container ID"),
  tracking_request_id STRING OPTIONS(description="Extracted Terminal49 tracking request ID"),
  bill_of_lading STRING OPTIONS(description="Extracted Bill of Lading number"),
  container_number STRING OPTIONS(description="Extracted container number"),
  
  -- Reprocessing tracking
  reprocessing_count INT64 DEFAULT 0 OPTIONS(description="Number of times event was reprocessed"),
  last_reprocessed_at TIMESTAMP OPTIONS(description="Last reprocessing timestamp")
)
PARTITION BY DATE(received_at)
CLUSTER BY event_type, processing_status, event_category
OPTIONS(
  description="Archive of all Terminal49 webhook events with complete payloads",
  labels=[("source", "terminal49"), ("purpose", "webhook_archive")],
  require_partition_filter=true
);

-- ============================================================================
-- TABLE: events_historical
-- Description: Historical events moved from Supabase (>90 days old)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `li-customer-datalake.terminal49_raw_events.events_historical`
(
  -- Event identification
  event_id STRING NOT NULL OPTIONS(description="Terminal49 event ID"),
  container_id STRING NOT NULL OPTIONS(description="Terminal49 container ID"),
  shipment_id STRING NOT NULL OPTIONS(description="Terminal49 shipment ID"),
  
  -- Event details
  event_type STRING NOT NULL OPTIONS(description="Type of transport/status event"),
  event_timestamp TIMESTAMP OPTIONS(description="When event occurred"),
  
  -- Location information
  location_locode STRING OPTIONS(description="UN/LOCODE of event location"),
  location_name STRING OPTIONS(description="Human-readable location name"),
  
  -- Vessel information
  vessel_name STRING OPTIONS(description="Vessel name if applicable"),
  vessel_imo STRING OPTIONS(description="Vessel IMO number if applicable"),
  voyage_number STRING OPTIONS(description="Voyage number if applicable"),
  
  -- Metadata
  data_source STRING OPTIONS(description="Source: shipping_line, terminal, ais"),
  raw_data JSON NOT NULL OPTIONS(description="Complete event data"),
  
  -- Timestamps
  created_at TIMESTAMP NOT NULL OPTIONS(description="When record was created in Supabase"),
  archived_at TIMESTAMP NOT NULL OPTIONS(description="When record was archived to BigQuery")
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY event_type, container_id, location_locode
OPTIONS(
  description="Historical container events archived from Supabase operational database",
  labels=[("source", "supabase"), ("purpose", "historical_archive")],
  require_partition_filter=true
);

-- ============================================================================
-- TABLE: processing_metrics
-- Description: Aggregated metrics for monitoring and analytics
-- ============================================================================

CREATE TABLE IF NOT EXISTS `li-customer-datalake.terminal49_raw_events.processing_metrics`
(
  -- Time dimension
  metric_timestamp TIMESTAMP NOT NULL OPTIONS(description="Timestamp of metric (hourly aggregation)"),
  metric_date DATE NOT NULL OPTIONS(description="Date of metric"),
  metric_hour INT64 NOT NULL OPTIONS(description="Hour of day (0-23)"),
  
  -- Event classification
  event_type STRING NOT NULL OPTIONS(description="Type of event"),
  event_category STRING OPTIONS(description="High-level category"),
  
  -- Volume metrics
  total_events INT64 NOT NULL OPTIONS(description="Total events received"),
  successful_events INT64 NOT NULL OPTIONS(description="Successfully processed events"),
  failed_events INT64 NOT NULL OPTIONS(description="Failed processing events"),
  
  -- Performance metrics
  avg_processing_duration_ms FLOAT64 OPTIONS(description="Average processing duration"),
  p50_processing_duration_ms FLOAT64 OPTIONS(description="Median processing duration"),
  p95_processing_duration_ms FLOAT64 OPTIONS(description="95th percentile processing duration"),
  p99_processing_duration_ms FLOAT64 OPTIONS(description="99th percentile processing duration"),
  max_processing_duration_ms INT64 OPTIONS(description="Maximum processing duration"),
  
  -- Data metrics
  avg_payload_size_bytes FLOAT64 OPTIONS(description="Average payload size"),
  total_payload_bytes INT64 OPTIONS(description="Total bytes processed"),
  
  -- Security metrics
  signature_validation_failures INT64 DEFAULT 0 OPTIONS(description="Number of signature validation failures"),
  
  -- Calculated at
  calculated_at TIMESTAMP NOT NULL OPTIONS(description="When metrics were calculated")
)
PARTITION BY metric_date
CLUSTER BY event_type, event_category
OPTIONS(
  description="Hourly aggregated metrics for monitoring and analytics",
  labels=[("purpose", "metrics")]
);

-- ============================================================================
-- VIEWS: Analytical queries
-- ============================================================================

-- View: Recent events summary (last 24 hours)
CREATE OR REPLACE VIEW `li-customer-datalake.terminal49_raw_events.recent_events_summary` AS
SELECT 
  event_type,
  event_category,
  processing_status,
  COUNT(*) as event_count,
  AVG(processing_duration_ms) as avg_duration_ms,
  MAX(processing_duration_ms) as max_duration_ms,
  SUM(CASE WHEN signature_valid = false THEN 1 ELSE 0 END) as invalid_signatures,
  MIN(received_at) as first_event_at,
  MAX(received_at) as last_event_at
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
GROUP BY event_type, event_category, processing_status
ORDER BY event_count DESC;

-- View: Failed events for investigation
CREATE OR REPLACE VIEW `li-customer-datalake.terminal49_raw_events.failed_events` AS
SELECT 
  event_id,
  notification_id,
  received_at,
  event_type,
  processing_error,
  processing_duration_ms,
  reprocessing_count,
  payload
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE processing_status = 'failed'
  AND DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY received_at DESC;

-- View: Processing performance by event type
CREATE OR REPLACE VIEW `li-customer-datalake.terminal49_raw_events.performance_by_event_type` AS
SELECT 
  event_type,
  COUNT(*) as total_events,
  AVG(processing_duration_ms) as avg_duration_ms,
  APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(50)] as p50_duration_ms,
  APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(95)] as p95_duration_ms,
  APPROX_QUANTILES(processing_duration_ms, 100)[OFFSET(99)] as p99_duration_ms,
  MAX(processing_duration_ms) as max_duration_ms,
  AVG(payload_size_bytes) as avg_payload_size_bytes
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND processing_status = 'processed'
GROUP BY event_type
ORDER BY total_events DESC;

-- View: Daily event volume trends
CREATE OR REPLACE VIEW `li-customer-datalake.terminal49_raw_events.daily_event_trends` AS
SELECT 
  DATE(received_at) as event_date,
  event_category,
  COUNT(*) as total_events,
  SUM(CASE WHEN processing_status = 'processed' THEN 1 ELSE 0 END) as successful_events,
  SUM(CASE WHEN processing_status = 'failed' THEN 1 ELSE 0 END) as failed_events,
  SUM(CASE WHEN signature_valid = false THEN 1 ELSE 0 END) as invalid_signatures,
  AVG(processing_duration_ms) as avg_duration_ms,
  SUM(payload_size_bytes) as total_bytes
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY event_date, event_category
ORDER BY event_date DESC, event_category;

-- ============================================================================
-- SCHEDULED QUERIES: Automated metric calculation
-- ============================================================================

-- Query to populate processing_metrics table (run hourly via Cloud Scheduler)
-- This would be configured as a scheduled query in BigQuery

/*
INSERT INTO `li-customer-datalake.terminal49_raw_events.processing_metrics`
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
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE TIMESTAMP_TRUNC(received_at, HOUR) = TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR), HOUR)
GROUP BY metric_timestamp, metric_date, metric_hour, event_type, event_category;
*/

-- ============================================================================
-- DATA RETENTION POLICY
-- ============================================================================

-- Set table expiration (optional - 2 years for raw_events_archive)
-- ALTER TABLE `li-customer-datalake.terminal49_raw_events.raw_events_archive`
-- SET OPTIONS (
--   partition_expiration_days=730
-- );

-- ============================================================================
-- USEFUL QUERIES FOR OPERATIONS
-- ============================================================================

-- Query: Find events for reprocessing
/*
SELECT 
  event_id,
  notification_id,
  event_type,
  received_at,
  processing_error,
  payload
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE processing_status = 'failed'
  AND reprocessing_count < 3
  AND DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY received_at DESC
LIMIT 100;
*/

-- Query: Event volume by hour (last 7 days)
/*
SELECT 
  TIMESTAMP_TRUNC(received_at, HOUR) as hour,
  event_category,
  COUNT(*) as event_count
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY hour, event_category
ORDER BY hour DESC;
*/

-- Query: Signature validation failures
/*
SELECT 
  DATE(received_at) as date,
  COUNT(*) as failure_count,
  ARRAY_AGG(DISTINCT source_ip LIMIT 10) as source_ips
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE signature_valid = false
  AND DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY date
ORDER BY date DESC;
*/

-- Query: Extract specific shipment events
/*
SELECT 
  event_id,
  event_type,
  event_timestamp,
  received_at,
  JSON_EXTRACT_SCALAR(payload, '$.data.attributes.event') as event_name,
  JSON_EXTRACT(payload, '$.included') as included_entities
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE shipment_id = 'YOUR_SHIPMENT_ID'
  AND DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
ORDER BY event_timestamp DESC;
*/

-- ============================================================================
-- COST OPTIMIZATION NOTES
-- ============================================================================

/*
Cost Optimization Strategies:

1. Partitioning:
   - All tables partitioned by date for efficient querying
   - require_partition_filter=true enforces partition filter in queries
   - Reduces scanned data and costs

2. Clustering:
   - Tables clustered by frequently filtered columns
   - Improves query performance and reduces costs

3. Expiration:
   - Set partition_expiration_days for automatic cleanup
   - Recommended: 730 days (2 years) for raw_events_archive

4. Query Best Practices:
   - Always include partition filter (DATE(received_at) >= ...)
   - Use clustering columns in WHERE clauses
   - Avoid SELECT * - specify needed columns
   - Use APPROX_QUANTILES instead of exact percentiles

5. Streaming Inserts:
   - Cost: $0.05 per GB
   - Expected: ~150 MB/month = $0.01/month
   - Use batch inserts where possible to reduce costs

6. Storage:
   - Active storage: $0.02 per GB/month
   - Long-term storage (90+ days): $0.01 per GB/month
   - Expected: ~5 GB/month = $0.10/month

Estimated Monthly Cost:
- Storage: $0.10
- Streaming inserts: $0.01
- Queries: $0.05
- Total: ~$0.16/month (negligible)
*/

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
