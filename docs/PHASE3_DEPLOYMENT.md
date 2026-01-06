# Phase 3 Deployment Guide: Event Processing & Data Storage

## Overview

This guide covers the deployment of the Event Processor Cloud Function, which processes Terminal49 webhook events from Pub/Sub and writes data to Supabase PostgreSQL and BigQuery.

**Phase 3 Deliverables:**
- ✅ Event processor Cloud Function
- ✅ Data transformation logic for all event types
- ✅ Database write operations (upsert patterns)
- ✅ Idempotency implementation
- ✅ Raw event archival to BigQuery
- ✅ Dead letter queue handling
- ✅ Comprehensive testing (55+ tests)

## Prerequisites

### Completed Phases
- ✅ Phase 1: Foundation & Infrastructure Setup
- ✅ Phase 2: Core Webhook Infrastructure

### Required Resources
- Supabase PostgreSQL database (schema deployed)
- BigQuery dataset and tables (created in Phase 1)
- Pub/Sub topic `terminal49-webhook-events` (created in Phase 2)
- Service account with appropriate permissions

### Required Credentials
- Supabase database connection details
- GCP project access with appropriate IAM roles

## Pre-Deployment Checklist

### 1. Verify Database Schema

Ensure Supabase schema is deployed:

```bash
# Connect to Supabase
psql "postgresql://user:password@host:5432/database"

# Verify tables exist
\dt

# Expected tables:
# - shipments
# - containers
# - container_events
# - tracking_requests
# - webhook_deliveries

# Verify unique constraints for idempotency
\d container_events
# Should see: UNIQUE CONSTRAINT on t49_event_id
```

### 2. Verify BigQuery Dataset

```bash
# Check dataset exists
bq ls --project_id=YOUR_PROJECT_ID

# Check raw_events_archive table
bq show YOUR_PROJECT_ID:terminal49_webhooks.raw_events_archive

# Verify schema
bq show --schema --format=prettyjson \
  YOUR_PROJECT_ID:terminal49_webhooks.raw_events_archive
```

### 3. Configure Environment Variables

Update [`terraform.tfvars`](../infrastructure/terraform/terraform.tfvars):

```hcl
# Supabase Configuration
supabase_db_host     = "db.xxxxx.supabase.co"
supabase_db_port     = "5432"
supabase_db_name     = "postgres"
supabase_db_user     = "postgres"
supabase_db_password = "your-secure-password"  # Use Secret Manager in production

# Event Processor Configuration
event_processor_memory_mb      = 512
event_processor_timeout_seconds = 120
event_processor_max_instances  = 10
event_processor_min_instances  = 0
```

### 4. Review Service Account Permissions

The event processor service account needs:

```bash
# BigQuery permissions
roles/bigquery.dataEditor
roles/bigquery.jobUser

# Pub/Sub permissions
roles/pubsub.subscriber

# Logging permissions
roles/logging.logWriter
```

Verify permissions:

```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:event-processor@YOUR_PROJECT_ID.iam.gserviceaccount.com"
```

## Deployment Steps

### Step 1: Run Tests Locally

Before deploying, ensure all tests pass:

```bash
# Install dependencies
pip install -r requirements.txt
pip install -r functions/event_processor/requirements.txt

# Run unit tests
pytest tests/unit/test_transformers.py -v
pytest tests/unit/test_database_operations.py -v

# Run integration tests
pytest tests/integration/test_event_processor.py -v

# Expected: All tests pass (55+ tests)
```

### Step 2: Deploy via Terraform

```bash
cd infrastructure/terraform

# Initialize Terraform (if not already done)
terraform init

# Review changes
terraform plan -out=tfplan

# Expected changes:
# + google_cloudfunctions2_function.event_processor
# + google_pubsub_subscription.event_processor_subscription
# ~ Updated IAM bindings

# Apply changes
terraform apply tfplan

# Verify deployment
terraform output event_processor_function_name
```

### Step 3: Verify Function Deployment

```bash
# Check function status
gcloud functions describe event-processor-dev \
  --gen2 \
  --region=us-central1 \
  --format="table(name,state,updateTime)"

# Expected state: ACTIVE

# View function configuration
gcloud functions describe event-processor-dev \
  --gen2 \
  --region=us-central1 \
  --format="yaml(serviceConfig.environmentVariables)"
```

### Step 4: Test Event Processing

#### Option A: Trigger via Webhook Receiver

Send a test webhook to the webhook receiver (deployed in Phase 2):

```bash
# Get webhook URL
WEBHOOK_URL=$(terraform output -raw webhook_receiver_url)

# Send test event
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-T49-Webhook-Signature: $(echo -n '{"test":"data"}' | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | cut -d' ' -f2)" \
  -d '{
    "data": {
      "id": "test-notif-123",
      "type": "container",
      "attributes": {
        "event": "container.updated"
      }
    },
    "included": [
      {
        "type": "shipment",
        "id": "test-ship-123",
        "attributes": {
          "bill_of_lading_number": "TEST-BOL-123",
          "shipping_line_scac": "TEST"
        }
      },
      {
        "type": "container",
        "id": "test-cont-123",
        "attributes": {
          "number": "TEST123456",
          "current_status": "available"
        },
        "relationships": {
          "shipment": {
            "data": {"id": "test-ship-123"}
          }
        }
      }
    ]
  }'
```

#### Option B: Publish Directly to Pub/Sub

```bash
# Publish test message
gcloud pubsub topics publish terminal49-webhook-events-dev \
  --message='{"data":{"id":"test-123","type":"container"},"included":[]}' \
  --attribute=event_type=container.updated,request_id=test-req-123
```

### Step 5: Verify Processing

#### Check Cloud Logs

```bash
# View recent logs
gcloud functions logs read event-processor-dev \
  --gen2 \
  --region=us-central1 \
  --limit=20

# Look for:
# - "Processing event started"
# - "Raw event archived to BigQuery"
# - "Event processed successfully"
# - Processing duration (should be <10s)
```

#### Verify BigQuery Archive

```sql
-- Query raw events
SELECT 
  event_id,
  received_at,
  event_type,
  JSON_EXTRACT_SCALAR(payload, '$.data.id') as notification_id
FROM `YOUR_PROJECT_ID.terminal49_webhooks.raw_events_archive`
WHERE received_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
ORDER BY received_at DESC
LIMIT 10;
```

#### Verify Supabase Data

```sql
-- Check shipments
SELECT 
  t49_shipment_id,
  bill_of_lading_number,
  shipping_line_scac,
  created_at,
  updated_at
FROM shipments
ORDER BY created_at DESC
LIMIT 10;

-- Check containers
SELECT 
  t49_container_id,
  number,
  current_status,
  shipment_id,
  created_at
FROM containers
ORDER BY created_at DESC
LIMIT 10;

-- Check webhook deliveries
SELECT 
  t49_notification_id,
  event_type,
  processing_status,
  processing_error,
  received_at,
  processed_at
FROM webhook_deliveries
ORDER BY received_at DESC
LIMIT 10;
```

### Step 6: Test Idempotency

Send the same event twice and verify only one database entry:

```bash
# Send event twice
for i in {1..2}; do
  gcloud pubsub topics publish terminal49-webhook-events-dev \
    --message='{"data":{"id":"idempotency-test-123","type":"container"},"included":[]}' \
    --attribute=event_type=container.updated,request_id=idempotency-test
  sleep 2
done

# Verify only one entry in BigQuery (both attempts archived)
# Verify only one entry in Supabase (idempotency working)
```

## Post-Deployment Verification

### 1. Performance Metrics

Monitor initial performance:

```bash
# Check function metrics
gcloud monitoring time-series list \
  --filter='metric.type="cloudfunctions.googleapis.com/function/execution_times"' \
  --format="table(metric.labels.function_name, points[0].value.distribution_value.mean)"

# Expected: <10 seconds p99
```

### 2. Error Rate

```bash
# Check for errors
gcloud functions logs read event-processor-dev \
  --gen2 \
  --region=us-central1 \
  --filter="severity>=ERROR" \
  --limit=50

# Expected: No errors (or only test-related errors)
```

### 3. Dead Letter Queue

```bash
# Check DLQ depth
gcloud pubsub subscriptions describe terminal49-webhook-events-dlq-subscription-dev \
  --format="value(numUndeliveredMessages)"

# Expected: 0 messages
```

## Rollback Procedure

If issues are detected:

### Option 1: Disable Function

```bash
# Stop processing new events
gcloud pubsub subscriptions update event-processor-subscription-dev \
  --ack-deadline=600

# This gives 10 minutes to investigate before messages are redelivered
```

### Option 2: Rollback Terraform

```bash
cd infrastructure/terraform

# Revert to previous state
terraform apply -target=module.event_processor \
  -var="event_processor_max_instances=0"

# This stops new instances from starting
```

### Option 3: Full Rollback

```bash
# Destroy event processor
terraform destroy -target=module.event_processor

# Events will accumulate in Pub/Sub (retained for 7 days)
# Can be reprocessed after fixing issues
```

## Monitoring Setup

### Key Metrics to Monitor

1. **Processing Latency** (p50, p95, p99)
2. **Error Rate** (should be <1%)
3. **Dead Letter Queue Depth** (should be 0)
4. **Database Connection Pool Utilization**
5. **BigQuery Streaming Insert Success Rate**

### Set Up Alerts

```bash
# Create alert for high error rate
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Event Processor High Error Rate" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=0.05 \
  --condition-threshold-duration=300s \
  --condition-filter='resource.type="cloud_function" AND metric.type="cloudfunctions.googleapis.com/function/execution_count" AND metric.label.status!="ok"'
```

## Troubleshooting

### Issue: Function Not Receiving Events

**Check:**
1. Pub/Sub subscription exists and is active
2. Service account has `pubsub.subscriber` role
3. Webhook receiver is publishing to correct topic

**Debug:**
```bash
# Check subscription
gcloud pubsub subscriptions describe event-processor-subscription-dev

# Check topic
gcloud pubsub topics describe terminal49-webhook-events-dev

# Manually publish test message
gcloud pubsub topics publish terminal49-webhook-events-dev \
  --message='{"test":"data"}' \
  --attribute=event_type=test
```

### Issue: Database Connection Failures

**Check:**
1. Supabase credentials are correct
2. Network connectivity from Cloud Functions to Supabase
3. Connection pool not exhausted

**Debug:**
```bash
# Check environment variables
gcloud functions describe event-processor-dev \
  --gen2 \
  --region=us-central1 \
  --format="yaml(serviceConfig.environmentVariables)"

# Test connection manually
psql "postgresql://user:password@host:5432/database" -c "SELECT 1"
```

### Issue: BigQuery Insert Failures

**Check:**
1. Service account has `bigquery.dataEditor` role
2. Dataset and table exist
3. Schema matches payload structure

**Debug:**
```bash
# Check IAM permissions
bq show --format=prettyjson YOUR_PROJECT_ID:terminal49_webhooks

# Test insert manually
bq query --use_legacy_sql=false \
  'SELECT COUNT(*) FROM `YOUR_PROJECT_ID.terminal49_webhooks.raw_events_archive`'
```

## Next Steps

After successful Phase 3 deployment:

1. **Monitor for 24 hours** - Ensure stable operation
2. **Review performance metrics** - Optimize if needed
3. **Test with production-like load** - Use load testing tools
4. **Proceed to Phase 4** - Monitoring, Alerting & Production Readiness

## Related Documentation

- [Event Processor README](../functions/event_processor/README.md)
- [Database Schema](../infrastructure/database/supabase_schema.sql)
- [Phase 3 Development Plan](../DEVELOPMENT_PLAN.md#phase-3-event-processing--data-storage)
- [Phase 2 Deployment](./PHASE2_DEPLOYMENT.md)

## Support

For deployment issues:
1. Check Cloud Logging for detailed error messages
2. Review Terraform state for configuration issues
3. Verify all prerequisites are met
4. Consult troubleshooting section above
