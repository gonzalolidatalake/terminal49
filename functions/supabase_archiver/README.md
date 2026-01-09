# Supabase Archiver Cloud Function

Archives old container events from Supabase to BigQuery for long-term storage and cost optimization.

## Overview

This Cloud Function runs daily (via Cloud Scheduler) to archive container events older than 90 days from Supabase PostgreSQL to BigQuery's `events_historical` table. This reduces Supabase storage costs while maintaining long-term data retention for analytics and compliance.

## Features

- **Configurable Retention**: Archive events older than N days (default: 90)
- **Batch Processing**: Process events in configurable batches (default: 1000)
- **Optional Deletion**: Optionally delete archived events from Supabase
- **Idempotent**: Safe to run multiple times (BigQuery handles duplicates)
- **Comprehensive Logging**: Detailed logs for monitoring and debugging
- **Error Handling**: Graceful error handling with detailed error messages

## Architecture

```
Cloud Scheduler (Daily 2 AM UTC)
    ↓
Supabase Archiver Function
    ↓
Query Supabase (events older than 90 days)
    ↓
Transform to BigQuery Schema
    ↓
Insert to BigQuery (events_historical)
    ↓
[Optional] Delete from Supabase
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SUPABASE_URL` | Yes | - | Supabase project URL |
| `SUPABASE_SERVICE_KEY` | Yes | - | Supabase service role key |
| `GCP_PROJECT_ID` | Yes | - | GCP project ID |
| `BIGQUERY_DATASET_ID` | No | `terminal49_raw_events` | BigQuery dataset ID |
| `RETENTION_DAYS` | No | `90` | Archive events older than N days |
| `BATCH_SIZE` | No | `1000` | Number of events to process per run |
| `DELETE_AFTER_ARCHIVE` | No | `false` | Delete events from Supabase after archival |

## Response Format

### Success Response (200)

```json
{
  "status": "success",
  "archived_count": 1523,
  "deleted_from_supabase": false,
  "duration_ms": 2341.5,
  "cutoff_date": "2025-10-10T00:00:00.000000",
  "batch_size": 1000,
  "retention_days": 90
}
```

### Error Response (500)

```json
{
  "status": "error",
  "message": "BigQuery insert errors: [...]",
  "archived_count": 0
}
```

## Deployment

Deployed via Terraform as part of the BigQuery analytics infrastructure:

```bash
cd infrastructure/terraform
terraform plan
terraform apply
```

## Monitoring

### Cloud Logging Queries

```
# View archival runs
resource.type="cloud_function"
resource.labels.function_name="supabase-archiver"
textPayload=~"Starting archival"

# View errors
resource.type="cloud_function"
resource.labels.function_name="supabase-archiver"
severity>=ERROR
```

### Key Metrics

- **Archived Events**: Number of events archived per run
- **Duration**: Time taken to complete archival
- **Errors**: Any failures during archival process

## Testing

### Local Testing

```bash
# Set environment variables
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_SERVICE_KEY="your-service-key"
export GCP_PROJECT_ID="your-project-id"
export RETENTION_DAYS="90"
export BATCH_SIZE="100"
export DELETE_AFTER_ARCHIVE="false"

# Run locally
functions-framework --target=archive_old_events --debug
```

### Manual Trigger

```bash
# Trigger via gcloud
gcloud functions call supabase-archiver \
  --region=us-central1 \
  --data='{}'
```

## Validation Queries

### Check Archived Events

```sql
-- View archived events by date
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

### Verify Archival Completeness

```sql
-- Check for gaps in archival
SELECT 
  DATE(created_at) as event_date,
  COUNT(*) as events_in_supabase
FROM container_events
WHERE created_at < CURRENT_DATE - INTERVAL '90 days'
GROUP BY event_date
ORDER BY event_date DESC;
```

## Cost Optimization

### Storage Savings

- **Supabase**: ~$0.125/GB/month
- **BigQuery**: ~$0.02/GB/month (long-term storage)
- **Savings**: ~84% reduction in storage costs for archived data

### Function Costs

- **Execution**: ~$0.0000004/invocation
- **Daily Cost**: ~$0.012/month (1 run/day)
- **Break-even**: Archiving >100MB saves money

## Troubleshooting

### No Events Archived

- Check if events older than retention period exist in Supabase
- Verify `RETENTION_DAYS` configuration
- Check Cloud Scheduler is triggering function

### BigQuery Insert Errors

- Verify BigQuery dataset and table exist
- Check service account has `bigquery.dataEditor` role
- Validate event data matches BigQuery schema

### Supabase Connection Errors

- Verify `SUPABASE_URL` and `SUPABASE_SERVICE_KEY`
- Check Supabase project is accessible
- Verify service key has read permissions

## Security

- **Service Account**: Uses event processor service account
- **Secrets**: Stored as environment variables (encrypted at rest)
- **Network**: Private function, triggered by Cloud Scheduler
- **Audit**: All operations logged to Cloud Logging

## Maintenance

### Quarterly Tasks

- Review retention policy (adjust `RETENTION_DAYS` if needed)
- Validate archival completeness
- Check storage cost savings
- Review error logs

### Annual Tasks

- Rotate Supabase service key
- Review and optimize batch size
- Validate BigQuery partition expiration settings

## Version History

- **1.0.0** (2026-01-08): Initial implementation
  - Configurable retention and batch size
  - Optional deletion from Supabase
  - Comprehensive logging and error handling
