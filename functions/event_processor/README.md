# Event Processor Cloud Function

## Overview

The Event Processor is a Cloud Function (2nd generation) that processes Terminal49 webhook events from Pub/Sub, transforms the data, and writes it to both Supabase PostgreSQL and BigQuery.

**Trigger**: Pub/Sub subscription to `terminal49-webhook-events` topic  
**Runtime**: Python 3.11  
**Memory**: 512MB  
**Timeout**: 120 seconds  

## Architecture

```
Pub/Sub Topic → Event Processor → [Supabase PostgreSQL, BigQuery]
                                   ↓
                            Idempotent Processing
```

## Key Features

- **Asynchronous Processing**: Triggered by Pub/Sub for decoupled architecture
- **Dual Storage**: Writes to both Supabase (operational) and BigQuery (archival)
- **Idempotency**: Uses Terminal49 event IDs to prevent duplicate processing
- **Connection Pooling**: Reuses database connections across invocations
- **Comprehensive Logging**: Structured logging with request correlation
- **Error Handling**: Automatic retries via Pub/Sub with dead letter queue

## Module Structure

```
event_processor/
├── main.py                    # Entry point and orchestration
├── database.py                # PostgreSQL connection management
├── database_operations.py     # Upsert/insert operations
├── transformers.py            # Event transformation logic
├── bigquery_archiver.py       # BigQuery raw event archival
├── requirements.txt           # Python dependencies
└── README.md                  # This file
```

## Event Processing Flow

1. **Receive Event**: Decode Pub/Sub message and extract payload
2. **Archive Raw Event**: Store complete payload in BigQuery (always first)
3. **Transform Data**: Extract entities (shipments, containers, events)
4. **Write to Database**: Upsert entities to Supabase with idempotency
5. **Record Delivery**: Track webhook delivery status
6. **Log Metrics**: Record processing duration and status

## Supported Event Types

### Container Transport Events
- `container.transport.vessel_arrived`
- `container.transport.vessel_departed`
- `container.transport.discharged`
- `container.transport.loaded`
- And 20+ other transport events

### Container Lifecycle Events
- `container.created`
- `container.updated`
- `container.pickup_lfd.changed`

### Tracking Request Events
- `tracking_request.succeeded`
- `tracking_request.failed`
- `tracking_request.awaiting_manifest`
- `tracking_request.tracking_stopped`

### Shipment Events
- `shipment.estimated.arrival`

## Environment Variables

### Required
- `GCP_PROJECT_ID`: Google Cloud project ID
- `BIGQUERY_DATASET_ID`: BigQuery dataset for raw events
- `SUPABASE_DB_HOST`: Supabase PostgreSQL host
- `SUPABASE_DB_NAME`: Database name
- `SUPABASE_DB_USER`: Database user
- `SUPABASE_DB_PASSWORD`: Database password

### Optional
- `SUPABASE_DB_PORT`: Database port (default: 5432)
- `LOG_LEVEL`: Logging level (default: INFO)
- `ENVIRONMENT`: Environment name (dev/staging/prod)

## Database Operations

### Upsert Pattern (Shipments & Containers)
```sql
INSERT INTO shipments (...)
VALUES (...)
ON CONFLICT (t49_shipment_id) DO UPDATE SET
    field = EXCLUDED.field,
    updated_at = NOW()
```

### Idempotent Insert (Events)
```sql
INSERT INTO container_events (...)
VALUES (...)
ON CONFLICT (t49_event_id) DO NOTHING
```

## Error Handling

### Transient Errors
- Database connection failures
- Temporary network issues
- **Action**: Pub/Sub automatically retries (exponential backoff)

### Permanent Errors
- Malformed payloads
- Missing required fields
- **Action**: After 5 retries, message moves to dead letter queue

### Monitoring
- All errors logged with full context
- Alerts triggered for high error rates
- Dead letter queue monitored for manual intervention

## Performance Characteristics

- **Cold Start**: ~2-3 seconds (includes connection pool initialization)
- **Warm Start**: ~100-500ms per event
- **Database Write**: <100ms per operation
- **BigQuery Archive**: <200ms streaming insert
- **Total Processing**: <10 seconds (p99)

## Connection Pooling

The function uses a global connection pool that persists across invocations:

```python
# Pool configuration
minconn = 1
maxconn = 5
keepalives = enabled
```

This reduces connection overhead on warm starts by ~200ms.

## Testing

### Unit Tests
```bash
# Test transformers
pytest tests/unit/test_transformers.py -v

# Test database operations
pytest tests/unit/test_database_operations.py -v
```

### Integration Tests
```bash
# Test end-to-end processing
pytest tests/integration/test_event_processor.py -v
```

### Test Coverage
- 40+ unit tests covering all event types
- 15+ integration tests for end-to-end flows
- Idempotency verification tests
- Error handling scenarios

## Deployment

### Via Terraform
```bash
cd infrastructure/terraform
terraform apply
```

### Manual Deployment
```bash
gcloud functions deploy event-processor \
  --gen2 \
  --runtime=python311 \
  --region=us-central1 \
  --source=. \
  --entry-point=process_webhook_event \
  --trigger-topic=terminal49-webhook-events \
  --memory=512MB \
  --timeout=120s \
  --service-account=event-processor@project.iam.gserviceaccount.com \
  --set-env-vars="GCP_PROJECT_ID=project-id,..."
```

## Monitoring & Debugging

### View Logs
```bash
# Real-time logs
gcloud functions logs read event-processor --gen2 --region=us-central1 --limit=50

# Filter by request ID
gcloud functions logs read event-processor --gen2 --region=us-central1 \
  --filter="jsonPayload.request_id=req-123"
```

### Query Raw Events (BigQuery)
```sql
SELECT *
FROM `project.terminal49_webhooks.raw_events_archive`
WHERE event_type = 'container.transport.vessel_arrived'
  AND received_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
ORDER BY received_at DESC
LIMIT 100;
```

### Check Processing Status (Supabase)
```sql
SELECT 
  t49_notification_id,
  event_type,
  processing_status,
  processing_error,
  received_at,
  processed_at
FROM webhook_deliveries
WHERE processing_status = 'failed'
ORDER BY received_at DESC
LIMIT 20;
```

## Troubleshooting

### Issue: High Processing Latency
**Symptoms**: Events taking >30 seconds to process  
**Causes**: Database connection pool exhausted, slow queries  
**Solutions**:
- Check connection pool utilization
- Review slow query logs
- Increase max_instance_count if needed

### Issue: Duplicate Events in Database
**Symptoms**: Same event processed multiple times  
**Causes**: Idempotency constraint not working  
**Solutions**:
- Verify unique constraint on `t49_event_id`
- Check for null event IDs in payload
- Review database logs for constraint violations

### Issue: Events Stuck in Dead Letter Queue
**Symptoms**: Messages accumulating in DLQ  
**Causes**: Persistent processing errors  
**Solutions**:
- Query DLQ messages to identify pattern
- Check for schema changes in Terminal49 API
- Review error logs for specific failures
- Manually reprocess after fixing issue

## Security Considerations

- **Database Credentials**: Stored as environment variables, encrypted at rest
- **Service Account**: Least-privilege IAM roles
- **Network**: Private function, no public access
- **Logging**: Sensitive data (passwords, keys) never logged

## Maintenance

### Quarterly Tasks
- Review and optimize slow queries
- Update dependencies (requirements.txt)
- Rotate database credentials
- Review error patterns and improve handling

### As Needed
- Add support for new Terminal49 event types
- Adjust resource allocation based on metrics
- Update schema for new data fields

## Related Documentation

- [Phase 3 Development Plan](../../DEVELOPMENT_PLAN.md#phase-3-event-processing--data-storage)
- [Database Schema](../../infrastructure/database/supabase_schema.sql)
- [BigQuery Schema](../../infrastructure/database/bigquery_schema.sql)
- [Webhook Receiver](../webhook_receiver/README.md)

## Support

For issues or questions:
1. Check logs in Cloud Logging
2. Review error patterns in monitoring dashboard
3. Query raw events in BigQuery for debugging
4. Consult operational runbooks (Phase 4)
