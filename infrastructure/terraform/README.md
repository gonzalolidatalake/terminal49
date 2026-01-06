# Terminal49 Webhook Infrastructure - Terraform

This directory contains Terraform configuration for deploying the Terminal49 webhook infrastructure on Google Cloud Platform.

## Architecture Overview

```
Terminal49 Webhooks
        ↓
Cloud Function (Webhook Receiver)
        ↓
    Pub/Sub Topic
        ↓
Cloud Function (Event Processor)
        ↓
    ├─→ BigQuery (Raw Events Archive)
    └─→ Supabase PostgreSQL (Operational Data)
```

## Prerequisites

1. **Terraform** 1.5+ installed
2. **gcloud CLI** installed and authenticated
3. **GCP Project** access: `li-customer-datalake`
4. **Supabase Project** access: `srordjhkcvyfyvepzrzp`
5. **Required secrets**:
   - Terminal49 webhook secret
   - Supabase service role key
   - Supabase database password

## Quick Start

```bash
# 1. Navigate to terraform directory
cd infrastructure/terraform

# 2. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 3. Edit terraform.tfvars with your actual values
nano terraform.tfvars

# 4. Initialize Terraform
terraform init

# 5. Review the plan
terraform plan

# 6. Apply the configuration
terraform apply
```

## Directory Structure

```
infrastructure/terraform/
├── main.tf                      # Main configuration
├── variables.tf                 # Variable definitions
├── terraform.tfvars.example     # Example variables
├── terraform.tfvars             # Actual variables (gitignored)
├── outputs.tf                   # Output definitions
├── backend.tf                   # Backend configuration
├── README.md                    # This file
└── modules/                     # Terraform modules
    ├── pubsub/                  # Pub/Sub topics and subscriptions
    ├── bigquery/                # BigQuery datasets and tables
    ├── cloud_function/          # Cloud Functions (reusable)
    ├── service_accounts/        # Service accounts and IAM
    └── monitoring/              # Monitoring and alerting
```

## Modules

### Pub/Sub Module
Creates Pub/Sub topics and subscriptions for event distribution.

**Resources**:
- `terminal49-webhook-events-{env}` - Main event topic
- `terminal49-webhook-events-dlq-{env}` - Dead letter queue
- Subscriptions with retry policies

### BigQuery Module
Creates BigQuery datasets and tables for raw event archival.

**Resources**:
- Dataset: `terminal49_raw_events`
- Table: `raw_events_archive` (partitioned by date)
- Table: `events_historical` (archived from Supabase)
- Table: `processing_metrics` (aggregated metrics)

### Cloud Function Module
Reusable module for deploying Cloud Functions (2nd gen).

**Features**:
- HTTP or Pub/Sub triggers
- Environment variable management
- Service account configuration
- Auto-scaling settings
- Source code deployment

### Service Accounts Module
Creates service accounts with least-privilege IAM roles.

**Service Accounts**:
- `terminal49-webhook-receiver` - Webhook receiver permissions
- `terminal49-event-processor` - Event processor permissions

### Monitoring Module
Creates Cloud Monitoring dashboards and alert policies.

**Alerts**:
- Webhook error rate > 5%
- Event processing latency > 30s
- Dead letter queue depth > 100
- Signature validation failures

## Configuration

### Required Variables

Edit `terraform.tfvars` with these required values:

```hcl
# Supabase credentials
supabase_service_key = "eyJ..."
supabase_db_password = "your-password"

# Terminal49 webhook secret
terminal49_webhook_secret = "your-webhook-secret"
```

### Optional Variables

Customize these in `terraform.tfvars` as needed:

```hcl
# Environment
environment = "dev"  # dev, staging, or production

# Cloud Functions scaling
webhook_receiver_max_instances = 100
event_processor_max_instances = 50

# Pub/Sub configuration
pubsub_max_delivery_attempts = 5

# BigQuery retention
bigquery_partition_expiration_days = 730  # 2 years
```

## State Management

Terraform state is stored in Google Cloud Storage:

```hcl
backend "gcs" {
  bucket = "li-customer-datalake-terraform-state"
  prefix = "terminal49-webhook-infrastructure"
}
```

### Initialize State Backend

```bash
# Create state bucket (one-time setup)
gsutil mb -p li-customer-datalake -l us-central1 \
  gs://li-customer-datalake-terraform-state

# Enable versioning
gsutil versioning set on gs://li-customer-datalake-terraform-state

# Initialize Terraform with backend
terraform init
```

## Deployment

### Development Environment

```bash
# Set environment
export TF_VAR_environment=dev

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

### Staging Environment

```bash
# Use staging variables
cp terraform.tfvars.staging terraform.tfvars

# Set environment
export TF_VAR_environment=staging

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan
```

### Production Environment

```bash
# Use production variables
cp terraform.tfvars.production terraform.tfvars

# Set environment
export TF_VAR_environment=production

# Plan with extra caution
terraform plan -out=tfplan

# Review plan carefully
terraform show tfplan

# Apply
terraform apply tfplan
```

## Outputs

After successful deployment, Terraform outputs:

```bash
# View all outputs
terraform output

# View specific output
terraform output webhook_receiver_url

# Get webhook URL for Terminal49 configuration
terraform output -raw webhook_receiver_url
```

**Key Outputs**:
- `webhook_receiver_url` - URL to configure in Terminal49
- `pubsub_topic_webhook_events` - Pub/Sub topic name
- `bigquery_dataset_id` - BigQuery dataset ID
- `deployment_summary` - Complete deployment summary

## Verification

### Verify Deployment

```bash
# Check Cloud Functions
gcloud functions list --project=li-customer-datalake

# Check Pub/Sub topics
gcloud pubsub topics list --project=li-customer-datalake

# Check BigQuery datasets
bq ls --project_id=li-customer-datalake

# Test webhook endpoint
curl -X POST $(terraform output -raw webhook_receiver_url) \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

### View Logs

```bash
# Webhook receiver logs
gcloud functions logs read terminal49-webhook-receiver-dev --limit=50

# Event processor logs
gcloud functions logs read terminal49-event-processor-dev --limit=50
```

## Updating Infrastructure

### Update Cloud Function Code

```bash
# After updating function code
terraform apply -target=module.webhook_receiver
terraform apply -target=module.event_processor
```

### Update Configuration

```bash
# After changing variables
terraform plan
terraform apply
```

### Update Specific Module

```bash
# Update only Pub/Sub
terraform apply -target=module.pubsub

# Update only BigQuery
terraform apply -target=module.bigquery
```

## Schema Management

### Overview

BigQuery table schemas are defined in two places:
1. **SQL Script**: [`infrastructure/database/bigquery_schema.sql`](../database/bigquery_schema.sql) - Manual table creation
2. **Terraform**: [`infrastructure/terraform/modules/bigquery/main.tf`](modules/bigquery/main.tf) - Infrastructure as Code

**CRITICAL**: These schemas MUST be kept in sync to avoid deployment errors.

### Schema Synchronization Process

#### When Creating New Tables

1. **Define schema in SQL first** (source of truth for data structure)
   ```bash
   # Edit the SQL schema file
   nano infrastructure/database/bigquery_schema.sql
   ```

2. **Update Terraform to match**
   ```bash
   # Edit the Terraform module
   nano infrastructure/terraform/modules/bigquery/main.tf
   ```

3. **Verify schemas match exactly**
   - Column names must be identical
   - Data types must match (STRING, INTEGER, TIMESTAMP, JSON, etc.)
   - Modes must match (REQUIRED, NULLABLE)
   - Descriptions should be consistent
   - Clustering columns must match
   - Partition fields must match

4. **Validate with terraform plan**
   ```bash
   cd infrastructure/terraform
   terraform plan
   # Expected: "No changes" for existing tables
   ```

#### When Modifying Existing Tables

**Option A: Update Terraform to Match Existing Tables (RECOMMENDED)**
- Use when tables already exist with data
- Less risk of data loss
- Simpler to implement

```bash
# 1. Document current table schema
bq show --schema --format=prettyjson \
  li-customer-datalake:terminal49_raw_events.raw_events_archive

# 2. Update Terraform schemas to match
nano infrastructure/terraform/modules/bigquery/main.tf

# 3. Validate no destructive changes
terraform plan
# Should show only in-place updates, no table recreation
```

**Option B: Update Tables to Match Terraform**
- Use only for empty tables or non-production environments
- Risk of data loss if not careful
- Requires table recreation

```bash
# WARNING: This will delete and recreate tables
# 1. Backup data first
bq extract --destination_format=NEWLINE_DELIMITED_JSON \
  li-customer-datalake:terminal49_raw_events.raw_events_archive \
  gs://backup-bucket/raw_events_archive_*.json

# 2. Apply Terraform changes
terraform apply
```

### Schema Alignment Checklist

Use this checklist when aligning schemas:

- [ ] **Column Names**: Exact match (case-sensitive)
- [ ] **Data Types**: STRING, INTEGER, FLOAT, BOOLEAN, TIMESTAMP, DATE, JSON
- [ ] **Modes**: REQUIRED vs NULLABLE
- [ ] **Descriptions**: Consistent and clear
- [ ] **Partitioning**: Field and type match
- [ ] **Clustering**: Column order matches
- [ ] **Default Values**: Match between SQL and Terraform
- [ ] **require_partition_filter**: Matches SQL OPTIONS

### Common Schema Mismatches

#### 1. Missing Columns
**Error**: `Column 'event_category' cannot be dropped`

**Cause**: Terraform schema missing columns that exist in BigQuery

**Fix**: Add missing columns to Terraform schema
```hcl
{
  name        = "event_category"
  type        = "STRING"
  mode        = "NULLABLE"
  description = "High-level category: tracking_request, container, shipment"
}
```

#### 2. Mode Mismatch
**Error**: `Cannot change column mode from NULLABLE to REQUIRED`

**Cause**: SQL defines column as NULLABLE, Terraform as REQUIRED (or vice versa)

**Fix**: Update Terraform mode to match SQL
```hcl
mode = "NULLABLE"  # Must match SQL definition
```

#### 3. Clustering Mismatch
**Error**: Terraform shows clustering changes

**Cause**: Clustering columns don't match between SQL and Terraform

**Fix**: Update Terraform clustering to match SQL
```hcl
clustering = ["event_type", "processing_status", "event_category"]
```

### Current Table Schemas

#### raw_events_archive (24 columns)
- **Partition**: DATE(received_at)
- **Clustering**: event_type, processing_status, event_category
- **Key columns**: event_id, notification_id, event_type, event_category, payload, processing_status

#### events_historical (14 columns)
- **Partition**: DATE(event_timestamp)
- **Clustering**: event_type, container_id, location_locode
- **Key columns**: event_id, container_id, shipment_id, event_type, vessel_name, vessel_imo

#### processing_metrics (17 columns)
- **Partition**: DATE(metric_date)
- **Clustering**: event_type, event_category
- **Key columns**: metric_timestamp, event_type, total_events, successful_events, failed_events

### Validation Commands

```bash
# Compare SQL and Terraform schemas
cd infrastructure/terraform
terraform plan | grep -A 50 "google_bigquery_table"

# View current BigQuery schema
bq show --schema --format=prettyjson \
  li-customer-datalake:terminal49_raw_events.raw_events_archive

# Validate Terraform configuration
terraform validate

# Check for schema drift
terraform plan -detailed-exitcode
# Exit code 0 = no changes, 2 = changes detected
```

### Best Practices

1. **SQL as Source of Truth**: Design schemas in SQL first, then replicate to Terraform
2. **Version Control**: Commit both SQL and Terraform changes together
3. **Documentation**: Update this README when schemas change
4. **Testing**: Always run `terraform plan` before `apply`
5. **Backups**: Backup data before schema changes
6. **Incremental Changes**: Make small, tested changes rather than large rewrites
7. **Code Reviews**: Have schema changes reviewed by team members

### Schema Change Workflow

```bash
# 1. Create feature branch
git checkout -b fix/bigquery-schema-alignment

# 2. Update SQL schema (if needed)
nano infrastructure/database/bigquery_schema.sql

# 3. Update Terraform to match
nano infrastructure/terraform/modules/bigquery/main.tf

# 4. Validate changes
cd infrastructure/terraform
terraform init
terraform plan -out=tfplan

# 5. Review plan carefully
terraform show tfplan

# 6. Apply if no destructive changes
terraform apply tfplan

# 7. Verify tables
bq show li-customer-datalake:terminal49_raw_events.raw_events_archive

# 8. Commit changes
git add infrastructure/database/bigquery_schema.sql
git add infrastructure/terraform/modules/bigquery/main.tf
git add infrastructure/terraform/README.md
git commit -m "fix: align BigQuery Terraform schemas with SQL definitions"

# 9. Push and create PR
git push origin fix/bigquery-schema-alignment
```

## Troubleshooting

### Issue: Terraform init fails

```bash
# Check GCP authentication
gcloud auth list
gcloud auth application-default login

# Check project access
gcloud projects describe li-customer-datalake
```

### Issue: State lock error

```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Issue: Resource already exists

```bash
# Import existing resource
terraform import module.pubsub.google_pubsub_topic.webhook_events \
  projects/li-customer-datalake/topics/terminal49-webhook-events-dev
```

### Issue: Permission denied

```bash
# Check IAM permissions
gcloud projects get-iam-policy li-customer-datalake \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$(gcloud config get-value account)"

# Required roles:
# - roles/editor or roles/owner
# - roles/iam.serviceAccountAdmin
# - roles/cloudfunctions.admin
```

## Cleanup

### Destroy Development Environment

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Destroy specific module
terraform destroy -target=module.webhook_receiver
```

### Destroy Production (CAUTION!)

```bash
# Production requires explicit confirmation
export TF_VAR_environment=production

# Review carefully
terraform plan -destroy

# Destroy with confirmation
terraform destroy
```

## Cost Estimation

### Development Environment
- Cloud Functions: ~$5-10/month
- Pub/Sub: ~$0.50/month
- BigQuery: ~$0.20/month
- **Total: ~$6-11/month**

### Production Environment (5000 events/day)
- Cloud Functions: ~$20-30/month
- Pub/Sub: ~$2/month
- BigQuery: ~$1/month
- Supabase: $25/month (external)
- **Total: ~$48-58/month**

## Security Best Practices

1. **Never commit secrets** to version control
2. **Use separate tfvars** for each environment
3. **Enable state locking** in GCS backend
4. **Review plans** before applying
5. **Use service accounts** with least privilege
6. **Enable audit logging** for all resources
7. **Rotate secrets** quarterly

## Maintenance

### Regular Tasks

- **Weekly**: Review Cloud Monitoring dashboards
- **Monthly**: Review and optimize costs
- **Quarterly**: Rotate secrets and credentials
- **Annually**: Review and update Terraform modules

### Monitoring

```bash
# View monitoring dashboard
gcloud monitoring dashboards list --project=li-customer-datalake

# View alert policies
gcloud alpha monitoring policies list --project=li-customer-datalake
```

## References

- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## Support

For issues or questions:
1. Check this README
2. Review Terraform documentation
3. Check GCP documentation
4. Contact platform team
