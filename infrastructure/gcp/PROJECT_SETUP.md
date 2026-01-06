# GCP Project Setup Guide

## Project Information
- **GCP Project ID**: `li-customer-datalake`
- **Supabase Project ID**: `srordjhkcvyfyvepzrzp`
- **Region**: `us-central1` (recommended for cost and latency)
- **Environment**: Development → Staging → Production

## Prerequisites
- GCP CLI (`gcloud`) installed and authenticated
- Appropriate IAM permissions (Project Editor or Owner)
- Billing account linked to project

## Phase 1.1: GCP Project Setup

### 1. Verify Project Access
```bash
# Set the project
gcloud config set project li-customer-datalake

# Verify project details
gcloud projects describe li-customer-datalake

# Check current user permissions
gcloud projects get-iam-policy li-customer-datalake \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$(gcloud config get-value account)"
```

### 2. Enable Required APIs
```bash
# Enable all required GCP services
gcloud services enable \
  cloudfunctions.googleapis.com \
  pubsub.googleapis.com \
  bigquery.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  cloudresourcemanager.googleapis.com \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  storage-api.googleapis.com \
  storage-component.googleapis.com
```

### 3. Create Service Accounts

#### Webhook Receiver Service Account
```bash
# Create service account for webhook receiver
gcloud iam service-accounts create terminal49-webhook-receiver \
  --display-name="Terminal49 Webhook Receiver" \
  --description="Service account for receiving Terminal49 webhooks"

# Grant necessary permissions
gcloud projects add-iam-policy-binding li-customer-datalake \
  --member="serviceAccount:terminal49-webhook-receiver@li-customer-datalake.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"

gcloud projects add-iam-policy-binding li-customer-datalake \
  --member="serviceAccount:terminal49-webhook-receiver@li-customer-datalake.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"
```

#### Event Processor Service Account
```bash
# Create service account for event processor
gcloud iam service-accounts create terminal49-event-processor \
  --display-name="Terminal49 Event Processor" \
  --description="Service account for processing Terminal49 events"

# Grant necessary permissions
gcloud projects add-iam-policy-binding li-customer-datalake \
  --member="serviceAccount:terminal49-event-processor@li-customer-datalake.iam.gserviceaccount.com" \
  --role="roles/pubsub.subscriber"

gcloud projects add-iam-policy-binding li-customer-datalake \
  --member="serviceAccount:terminal49-event-processor@li-customer-datalake.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding li-customer-datalake \
  --member="serviceAccount:terminal49-event-processor@li-customer-datalake.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"
```

### 4. Configure Cloud Logging
```bash
# Create log sink for webhook events (optional - for long-term storage)
gcloud logging sinks create terminal49-webhook-logs \
  storage.googleapis.com/li-customer-datalake-logs \
  --log-filter='resource.type="cloud_function" AND resource.labels.function_name=~"terminal49-.*"'
```

### 5. Configure Cloud Monitoring
```bash
# Create notification channel for alerts (email)
gcloud alpha monitoring channels create \
  --display-name="Terminal49 Alerts" \
  --type=email \
  --channel-labels=email_address=alerts@example.com
```

### 6. Set Up Budget Alerts
```bash
# Note: Budget alerts are typically configured via Console
# Navigate to: Billing → Budgets & alerts
# Recommended thresholds:
# - Alert at 50%, 75%, 90%, 100% of budget
# - Monthly budget: $100-200 for development
```

## Verification Checklist

- [ ] Project ID verified: `li-customer-datalake`
- [ ] Billing account linked and active
- [ ] All required APIs enabled
- [ ] Service accounts created with least-privilege IAM roles
- [ ] Cloud Logging enabled and configured
- [ ] Cloud Monitoring enabled
- [ ] Budget alerts configured
- [ ] Current user has necessary permissions

## IAM Roles Summary

| Service Account | Roles | Purpose |
|----------------|-------|---------|
| `terminal49-webhook-receiver` | `pubsub.publisher`, `logging.logWriter` | Receive webhooks, publish to Pub/Sub |
| `terminal49-event-processor` | `pubsub.subscriber`, `bigquery.dataEditor`, `logging.logWriter` | Process events, write to BigQuery |

## Security Best Practices

1. **Least Privilege**: Service accounts have minimal required permissions
2. **Audit Logging**: All API calls are logged automatically
3. **No User Credentials**: Use service accounts for all automation
4. **Regular Reviews**: Audit IAM permissions quarterly
5. **Separation of Duties**: Separate service accounts for different functions

## Cost Optimization

1. **Cloud Functions**: Use 2nd gen for faster cold starts and better pricing
2. **Pub/Sub**: Messages retained for 7 days (default)
3. **BigQuery**: Use partitioning and clustering for cost-effective queries
4. **Logging**: Set retention policies (30 days for most logs)
5. **Monitoring**: Use free tier metrics where possible

## Next Steps

After completing this setup:
1. Proceed to Phase 1.2: Database Technology Selection
2. Document decision in [`memory-bank/decisionLog.md`](../../memory-bank/decisionLog.md)
3. Continue with Phase 1.3: Secret Management Solution

## Troubleshooting

### Issue: API not enabled
```bash
# Check which APIs are enabled
gcloud services list --enabled

# Enable specific API
gcloud services enable <api-name>.googleapis.com
```

### Issue: Permission denied
```bash
# Check your current permissions
gcloud projects get-iam-policy li-customer-datalake

# Request access from project owner
```

### Issue: Service account creation fails
```bash
# List existing service accounts
gcloud iam service-accounts list

# Check if service account already exists
```

## References

- [GCP IAM Best Practices](https://cloud.google.com/iam/docs/best-practices)
- [Cloud Functions IAM](https://cloud.google.com/functions/docs/securing/managing-access-iam)
- [Pub/Sub Access Control](https://cloud.google.com/pubsub/docs/access-control)
- [BigQuery Access Control](https://cloud.google.com/bigquery/docs/access-control)
