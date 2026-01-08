# Terminal49 Webhook Infrastructure - Operational Runbooks

This document provides step-by-step procedures for diagnosing and resolving common operational issues with the Terminal49 webhook infrastructure.

## Table of Contents

1. [Webhook Receiving Errors](#1-webhook-receiving-errors)
2. [Signature Validation Failures](#2-signature-validation-failures)
3. [Event Processing Delays](#3-event-processing-delays)
4. [Database Connection Issues](#4-database-connection-issues)
5. [Dead Letter Queue Processing](#5-dead-letter-queue-processing)
6. [Secret Rotation Procedure](#6-secret-rotation-procedure)
7. [Scaling for Traffic Spikes](#7-scaling-for-traffic-spikes)
8. [Disaster Recovery](#8-disaster-recovery)

---

## 1. Webhook Receiving Errors

### Symptoms
- Alert: "Terminal49 Webhook Error Rate High"
- HTTP 500 errors in Cloud Function logs
- Terminal49 reporting webhook delivery failures
- Increased error rate in Webhook Health dashboard

### Diagnosis Steps

1. **Check Cloud Function Logs**
   ```bash
   gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=terminal49-webhook-receiver AND severity>=ERROR" --limit 50 --format json
   ```

2. **Review Error Patterns**
   - Look for common error messages
   - Check if errors are consistent or intermittent
   - Identify affected time ranges

3. **Check Function Health**
   ```bash
   gcloud functions describe terminal49-webhook-receiver --region=us-central1 --gen2
   ```

4. **Verify Environment Variables**
   ```bash
   gcloud functions describe terminal49-webhook-receiver --region=us-central1 --gen2 --format="value(serviceConfig.environmentVariables)"
   ```

### Resolution Steps

#### If errors are due to missing environment variables:
```bash
# Update function with correct environment variables
gcloud functions deploy terminal49-webhook-receiver \
  --region=us-central1 \
  --gen2 \
  --set-env-vars TERMINAL49_WEBHOOK_SECRET=<secret>,GCP_PROJECT_ID=<project-id>
```

#### If errors are due to Pub/Sub connectivity:
1. Verify Pub/Sub topic exists:
   ```bash
   gcloud pubsub topics describe terminal49-webhook-events
   ```

2. Check IAM permissions:
   ```bash
   gcloud pubsub topics get-iam-policy terminal49-webhook-events
   ```

3. Verify service account has `pubsub.publisher` role

#### If errors are due to function crashes:
1. Check memory usage in monitoring dashboard
2. Increase memory allocation if needed:
   ```bash
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --memory=512MB
   ```

### Escalation Path
- **P1 (Critical)**: Page on-call engineer immediately
- **P2 (High)**: Notify team lead within 15 minutes
- **P3 (Medium)**: Create ticket for next business day

### Prevention
- Set up synthetic monitoring to test webhook endpoint
- Implement canary deployments for function updates
- Monitor memory and CPU usage trends

---

## 2. Signature Validation Failures

### Symptoms
- Alert: "Terminal49 Signature Validation Failures"
- HTTP 401 responses in logs
- `signature_validation_failed` metric increasing
- Terminal49 webhooks being rejected

### Diagnosis Steps

1. **Check Recent Signature Failures**
   ```bash
   gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=terminal49-webhook-receiver AND jsonPayload.message=~'Invalid signature'" --limit 20
   ```

2. **Verify Webhook Secret**
   - Confirm secret hasn't been rotated in Terminal49 dashboard
   - Check if secret in Cloud Function matches Terminal49

3. **Check for Pattern**
   - Are all requests failing or just some?
   - Is there a specific time pattern?
   - Are failures from specific IP addresses?

4. **Test Signature Validation**
   ```bash
   # Use test script to verify signature validation logic
   python tests/unit/test_webhook_validator.py
   ```

### Resolution Steps

#### If secret is incorrect:
1. Get correct secret from Terminal49 dashboard
2. Update Cloud Function:
   ```bash
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --update-env-vars TERMINAL49_WEBHOOK_SECRET=<new-secret>
   ```

3. Verify deployment:
   ```bash
   gcloud functions describe terminal49-webhook-receiver --region=us-central1 --gen2
   ```

#### If this is an attack:
1. Review source IP addresses in logs
2. Consider implementing IP allowlist:
   ```bash
   # Add ingress settings to function
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --ingress-settings=internal-and-gclb
   ```

3. Contact Terminal49 support to verify legitimate webhook sources

#### If validation logic is broken:
1. Review recent code changes
2. Rollback to previous version:
   ```bash
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --source=gs://<bucket>/previous-version.zip
   ```

### Escalation Path
- **P1 (Critical)**: If >50 failures/hour - immediate escalation
- **P2 (High)**: If 10-50 failures/hour - notify within 30 minutes
- **P3 (Medium)**: If <10 failures/hour - monitor and investigate

### Prevention
- Implement secret rotation reminders (quarterly)
- Set up test webhook in Terminal49 for validation
- Document secret management procedures

---

## 3. Event Processing Delays

### Symptoms
- Alert: "Terminal49 Event Processing Latency High"
- Pub/Sub message age increasing
- Events taking >30 seconds to process
- Backlog building in subscription

### Diagnosis Steps

1. **Check Pub/Sub Metrics**
   ```bash
   gcloud monitoring time-series list \
     --filter='metric.type="pubsub.googleapis.com/subscription/oldest_unacked_message_age" AND resource.labels.subscription_id="terminal49-webhook-events-sub"' \
     --format=json
   ```

2. **Check Event Processor Logs**
   ```bash
   gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=terminal49-event-processor AND severity>=WARNING" --limit 50
   ```

3. **Check Database Performance**
   - Review Supabase dashboard for slow queries
   - Check connection pool utilization
   - Look for lock contention

4. **Check Function Scaling**
   ```bash
   gcloud monitoring time-series list \
     --filter='metric.type="cloudfunctions.googleapis.com/function/active_instances" AND resource.labels.function_name="terminal49-event-processor"' \
     --format=json
   ```

### Resolution Steps

#### If database is slow:
1. Check Supabase connection pool:
   - Review active connections
   - Look for long-running queries

2. Optimize slow queries:
   ```sql
   -- Check for missing indexes
   SELECT schemaname, tablename, indexname 
   FROM pg_indexes 
   WHERE schemaname = 'public';
   
   -- Check for slow queries
   SELECT query, mean_exec_time, calls 
   FROM pg_stat_statements 
   ORDER BY mean_exec_time DESC 
   LIMIT 10;
   ```

3. Increase connection pool size if needed

#### If function is under-scaled:
1. Increase max instances:
   ```bash
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --max-instances=100
   ```

2. Increase memory for better performance:
   ```bash
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --memory=1GB
   ```

#### If there's a message backlog:
1. Check dead letter queue:
   ```bash
   gcloud pubsub subscriptions describe terminal49-webhook-events-dlq
   ```

2. Temporarily increase processing capacity:
   ```bash
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --max-instances=200 \
     --min-instances=5
   ```

3. Monitor until backlog clears

### Escalation Path
- **P1 (Critical)**: If backlog >1000 messages - immediate escalation
- **P2 (High)**: If latency >60 seconds - notify within 15 minutes
- **P3 (Medium)**: If latency 30-60 seconds - monitor and investigate

### Prevention
- Set up auto-scaling policies
- Implement database query optimization reviews
- Monitor trends to predict capacity needs

---

## 4. Database Connection Issues

### Symptoms
- Alert: "Terminal49 Database Connection Failures"
- `database_connection_failed` errors in logs
- Event processing failures
- Timeouts in database operations

### Diagnosis Steps

1. **Check Supabase Status**
   - Visit Supabase dashboard
   - Check for maintenance windows
   - Review connection metrics

2. **Check Connection Pool**
   ```bash
   gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=terminal49-event-processor AND jsonPayload.message=~'connection'" --limit 30
   ```

3. **Test Database Connectivity**
   ```bash
   # From Cloud Shell or local machine with credentials
   psql "postgresql://[user]:[password]@[host]:5432/postgres" -c "SELECT 1;"
   ```

4. **Check Network Configuration**
   - Verify VPC connector (if used)
   - Check firewall rules
   - Verify Supabase IP allowlist

### Resolution Steps

#### If connection pool is exhausted:
1. Review current pool configuration in `database.py`
2. Increase pool size:
   ```python
   # Update in database.py
   pool = create_engine(
       database_url,
       poolclass=QueuePool,
       pool_size=20,  # Increase from 10
       max_overflow=40,  # Increase from 20
       pool_timeout=30,
       pool_recycle=3600
   )
   ```

3. Redeploy function with updated configuration

#### If credentials are invalid:
1. Verify credentials in Supabase dashboard
2. Update environment variables:
   ```bash
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --update-env-vars SUPABASE_DB_URL=<new-url>
   ```

#### If Supabase is down:
1. Check Supabase status page
2. If extended outage, consider:
   - Pausing webhook receiver temporarily
   - Messages will queue in Pub/Sub (up to 7 days)
   - Communicate with stakeholders

3. Once restored, monitor backlog processing

#### If network connectivity issues:
1. Check VPC connector status:
   ```bash
   gcloud compute networks vpc-access connectors describe <connector-name> --region=us-central1
   ```

2. Verify firewall rules allow egress to Supabase

### Escalation Path
- **P1 (Critical)**: If all connections failing - immediate escalation
- **P2 (High)**: If >50% connections failing - notify within 15 minutes
- **P3 (Medium)**: If intermittent failures - investigate within 1 hour

### Prevention
- Implement connection retry logic with exponential backoff
- Monitor connection pool utilization
- Set up Supabase backup and failover
- Document connection string rotation procedure

---

## 5. Dead Letter Queue Processing

### Symptoms
- Alert: "Terminal49 Dead Letter Queue Depth High"
- DLQ has >100 messages
- Events failing after multiple retries
- Data gaps in database

### Diagnosis Steps

1. **Check DLQ Depth**
   ```bash
   gcloud pubsub subscriptions describe terminal49-webhook-events-dlq --format="value(numUndeliveredMessages)"
   ```

2. **Pull Sample Messages**
   ```bash
   gcloud pubsub subscriptions pull terminal49-webhook-events-dlq --limit=5 --format=json
   ```

3. **Analyze Failure Patterns**
   ```bash
   gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=terminal49-event-processor AND severity=ERROR" --limit 50 --format json
   ```

4. **Identify Root Cause**
   - Schema validation errors?
   - Database constraint violations?
   - Malformed data?
   - Code bugs?

### Resolution Steps

#### For schema validation errors:
1. Review error messages to identify issue
2. Update transformation logic in `transformers.py`
3. Redeploy function
4. Reprocess DLQ messages

#### For database constraint violations:
1. Identify constraint being violated
2. Options:
   - Fix data in database
   - Update schema if constraint is too strict
   - Update transformation logic to handle edge case

#### To manually reprocess DLQ messages:
1. Create reprocessing script:
   ```python
   # scripts/reprocess_dlq.py
   from google.cloud import pubsub_v1
   
   subscriber = pubsub_v1.SubscriberClient()
   publisher = pubsub_v1.PublisherClient()
   
   dlq_subscription = "projects/<project>/subscriptions/terminal49-webhook-events-dlq"
   main_topic = "projects/<project>/topics/terminal49-webhook-events"
   
   # Pull messages from DLQ
   response = subscriber.pull(
       request={"subscription": dlq_subscription, "max_messages": 100}
   )
   
   # Republish to main topic
   for msg in response.received_messages:
       publisher.publish(main_topic, msg.message.data, **msg.message.attributes)
       subscriber.acknowledge(
           request={"subscription": dlq_subscription, "ack_ids": [msg.ack_id]}
       )
   ```

2. Run reprocessing:
   ```bash
   python scripts/reprocess_dlq.py
   ```

3. Monitor processing in main subscription

#### To purge invalid messages:
```bash
# Only if messages are confirmed invalid and should be discarded
gcloud pubsub subscriptions seek terminal49-webhook-events-dlq --time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
```

### Escalation Path
- **P1 (Critical)**: If DLQ >1000 messages - immediate escalation
- **P2 (High)**: If DLQ >500 messages - notify within 30 minutes
- **P3 (Medium)**: If DLQ 100-500 messages - investigate within 2 hours

### Prevention
- Implement comprehensive error handling
- Add data validation before processing
- Set up alerts for DLQ depth
- Regular review of DLQ messages for patterns

---

## 6. Secret Rotation Procedure

### Overview
Rotate webhook secrets and database credentials quarterly or when compromised.

### Prerequisites
- Access to Terminal49 dashboard
- Access to Supabase dashboard
- GCP project admin permissions
- Maintenance window scheduled (if rotating during business hours)

### Procedure

#### Rotating Terminal49 Webhook Secret

1. **Generate New Secret in Terminal49**
   - Log into Terminal49 dashboard
   - Navigate to Webhooks → Settings
   - Click "Regenerate Secret"
   - Copy new secret (will be shown once)

2. **Update Cloud Function (Zero-Downtime)**
   ```bash
   # Update webhook receiver with new secret
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --update-env-vars TERMINAL49_WEBHOOK_SECRET=<new-secret>
   ```

3. **Verify Deployment**
   ```bash
   # Check function is healthy
   gcloud functions describe terminal49-webhook-receiver --region=us-central1 --gen2
   
   # Monitor logs for successful webhook receipts
   gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=terminal49-webhook-receiver" --limit 10
   ```

4. **Test Webhook**
   - Trigger test webhook from Terminal49 dashboard
   - Verify successful receipt in logs
   - Check no signature validation errors

5. **Document Rotation**
   - Update password manager with new secret
   - Log rotation in change management system
   - Update runbook if procedure changed

#### Rotating Database Credentials

1. **Create New Database User in Supabase**
   ```sql
   -- In Supabase SQL editor
   CREATE USER terminal49_webhook_new WITH PASSWORD '<new-password>';
   GRANT CONNECT ON DATABASE postgres TO terminal49_webhook_new;
   GRANT USAGE ON SCHEMA public TO terminal49_webhook_new;
   GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO terminal49_webhook_new;
   ```

2. **Update Connection String**
   ```bash
   # Update event processor with new credentials
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --update-env-vars SUPABASE_DB_URL=postgresql://terminal49_webhook_new:<new-password>@<host>:5432/postgres
   ```

3. **Verify Connectivity**
   ```bash
   # Monitor logs for successful database operations
   gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=terminal49-event-processor AND jsonPayload.message=~'database'" --limit 20
   ```

4. **Remove Old User (After 24 Hours)**
   ```sql
   -- Verify no active connections from old user
   SELECT * FROM pg_stat_activity WHERE usename = 'terminal49_webhook_old';
   
   -- Drop old user
   DROP USER terminal49_webhook_old;
   ```

### Rollback Procedure

If issues occur after rotation:

1. **Revert to Previous Secret**
   ```bash
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --update-env-vars TERMINAL49_WEBHOOK_SECRET=<old-secret>
   ```

2. **Verify Service Restored**
   - Check webhook receipts in logs
   - Verify no errors in monitoring dashboard

3. **Investigate Issue**
   - Review what went wrong
   - Update procedure if needed

### Schedule
- **Quarterly rotation**: First Monday of each quarter
- **Emergency rotation**: Immediately upon suspected compromise
- **Maintenance window**: 2 AM - 4 AM UTC (low traffic period)

---

## 7. Scaling for Traffic Spikes

### Symptoms
- Anticipated high traffic event (e.g., major vessel arrival)
- Historical traffic patterns show spikes
- Proactive scaling before known event

### Pre-Event Preparation

1. **Review Current Capacity**
   ```bash
   # Check current function configuration
   gcloud functions describe terminal49-webhook-receiver --region=us-central1 --gen2 --format="value(serviceConfig.maxInstanceCount)"
   gcloud functions describe terminal49-event-processor --region=us-central1 --gen2 --format="value(serviceConfig.maxInstanceCount)"
   ```

2. **Estimate Required Capacity**
   - Review historical traffic data
   - Calculate expected peak load
   - Add 50% buffer for safety

3. **Scale Up Functions**
   ```bash
   # Increase webhook receiver capacity
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --max-instances=200 \
     --min-instances=10
   
   # Increase event processor capacity
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --max-instances=300 \
     --min-instances=15
   ```

4. **Verify Database Capacity**
   - Check Supabase plan limits
   - Increase connection pool if needed
   - Consider temporary plan upgrade

5. **Set Up Enhanced Monitoring**
   ```bash
   # Create temporary high-frequency alerts
   gcloud alpha monitoring policies create \
     --notification-channels=<channel-id> \
     --display-name="High Traffic Event Monitoring" \
     --condition-display-name="Request Rate Spike" \
     --condition-threshold-value=1000 \
     --condition-threshold-duration=60s
   ```

### During Event

1. **Monitor Dashboards Actively**
   - Webhook Health dashboard
   - Event Processing dashboard
   - Infrastructure dashboard

2. **Watch Key Metrics**
   - Request rate
   - Error rate
   - Processing latency
   - DLQ depth
   - Active instances

3. **Be Ready to Scale Further**
   ```bash
   # If needed, increase limits further
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --max-instances=500
   ```

### Post-Event Cleanup

1. **Scale Down Functions**
   ```bash
   # Return to normal capacity
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --max-instances=50 \
     --min-instances=1
   
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --max-instances=100 \
     --min-instances=2
   ```

2. **Review Performance**
   - Analyze peak metrics
   - Identify any issues
   - Document lessons learned

3. **Remove Temporary Alerts**
   ```bash
   gcloud alpha monitoring policies delete <policy-id>
   ```

### Automation

Consider creating a scaling script:

```bash
#!/bin/bash
# scripts/scale_infrastructure.sh

MODE=$1  # "up" or "down"

if [ "$MODE" == "up" ]; then
  echo "Scaling up for high traffic..."
  gcloud functions deploy terminal49-webhook-receiver --max-instances=200 --min-instances=10
  gcloud functions deploy terminal49-event-processor --max-instances=300 --min-instances=15
elif [ "$MODE" == "down" ]; then
  echo "Scaling down to normal capacity..."
  gcloud functions deploy terminal49-webhook-receiver --max-instances=50 --min-instances=1
  gcloud functions deploy terminal49-event-processor --max-instances=100 --min-instances=2
else
  echo "Usage: $0 {up|down}"
  exit 1
fi
```

---

## 8. Disaster Recovery

### Scenarios Covered
- Complete GCP region failure
- Supabase database corruption
- Accidental data deletion
- Complete infrastructure loss

### Recovery Time Objectives (RTO)
- **Critical Functions**: 4 hours
- **Full Service**: 24 hours
- **Historical Data**: 7 days

### Recovery Point Objectives (RPO)
- **Operational Data**: 1 hour (Supabase backups)
- **Raw Events**: 0 (BigQuery streaming)

### Disaster Recovery Procedures

#### Scenario 1: GCP Region Failure

1. **Assess Situation**
   - Check GCP status dashboard
   - Determine if failure is partial or complete
   - Estimate recovery time

2. **Activate DR Region** (if configured)
   ```bash
   # Deploy functions to backup region
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-east1 \
     --gen2 \
     --source=gs://<backup-bucket>/latest/webhook-receiver.zip
   
   gcloud functions deploy terminal49-event-processor \
     --region=us-east1 \
     --gen2 \
     --source=gs://<backup-bucket>/latest/event-processor.zip
   ```

3. **Update Terminal49 Webhook URL**
   - Log into Terminal49 dashboard
   - Update webhook URL to new region endpoint
   - Test webhook delivery

4. **Monitor Recovery**
   - Watch for successful webhook receipts
   - Verify event processing
   - Check data consistency

#### Scenario 2: Database Corruption

1. **Stop Event Processing**
   ```bash
   # Pause event processor to prevent further corruption
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --max-instances=0
   ```

2. **Assess Damage**
   ```sql
   -- Check for corrupted data
   SELECT COUNT(*) FROM shipments WHERE created_at > NOW() - INTERVAL '1 hour';
   SELECT COUNT(*) FROM containers WHERE created_at > NOW() - INTERVAL '1 hour';
   ```

3. **Restore from Backup**
   - Access Supabase dashboard
   - Navigate to Database → Backups
   - Select most recent clean backup
   - Initiate restore (creates new database)

4. **Update Connection String**
   ```bash
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --update-env-vars SUPABASE_DB_URL=<new-database-url> \
     --max-instances=100
   ```

5. **Reprocess Missing Events**
   ```python
   # Query BigQuery for events after backup time
   from google.cloud import bigquery
   
   client = bigquery.Client()
   query = """
   SELECT payload
   FROM `project.dataset.raw_events_archive`
   WHERE received_at > TIMESTAMP('<backup-time>')
   ORDER BY received_at ASC
   """
   
   # Republish to Pub/Sub for reprocessing
   ```

#### Scenario 3: Accidental Data Deletion

1. **Identify Scope**
   ```sql
   -- Check what was deleted
   SELECT COUNT(*) FROM shipments;
   SELECT COUNT(*) FROM containers;
   SELECT MAX(created_at) FROM shipments;
   ```

2. **Stop Further Operations**
   ```bash
   # Pause processing
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --max-instances=0
   ```

3. **Restore from Point-in-Time**
   - Use Supabase point-in-time recovery
   - Select timestamp before deletion
   - Restore to new database

4. **Verify Data Integrity**
   ```sql
   -- Verify restored data
   SELECT COUNT(*) FROM shipments;
   SELECT COUNT(*) FROM containers;
   SELECT MAX(created_at) FROM shipments;
   ```

5. **Resume Operations**
   ```bash
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --update-env-vars SUPABASE_DB_URL=<restored-database-url> \
     --max-instances=100
   ```

#### Scenario 4: Complete Infrastructure Loss

1. **Provision New GCP Project**
   ```bash
   gcloud projects create terminal49-webhook-dr --name="Terminal49 Webhook DR"
   gcloud config set project terminal49-webhook-dr
   ```

2. **Deploy Infrastructure via Terraform**
   ```bash
   cd infrastructure/terraform
   terraform init
   terraform plan -var="environment=production"
   terraform apply -var="environment=production"
   ```

3. **Restore Database**
   - Create new Supabase project
   - Restore from latest backup
   - Update connection strings

4. **Deploy Functions**
   ```bash
   # Deploy from source control
   cd functions/webhook_receiver
   gcloud functions deploy terminal49-webhook-receiver \
     --region=us-central1 \
     --gen2 \
     --runtime=python311 \
     --source=. \
     --entry-point=webhook_receiver \
     --trigger-http
   
   cd ../event_processor
   gcloud functions deploy terminal49-event-processor \
     --region=us-central1 \
     --gen2 \
     --runtime=python311 \
     --source=. \
     --entry-point=process_webhook_event \
     --trigger-topic=terminal49-webhook-events
   ```

5. **Verify and Test**
   - Test webhook endpoint
   - Verify event processing
   - Check data consistency

### DR Testing Schedule

- **Quarterly**: Test database restore procedure
- **Semi-annually**: Full DR drill with region failover
- **Annually**: Complete infrastructure rebuild test

### DR Checklist

- [ ] Latest code in source control
- [ ] Infrastructure as Code up to date
- [ ] Database backups verified
- [ ] BigQuery data retention configured
- [ ] DR procedures documented
- [ ] Team trained on DR procedures
- [ ] Contact list updated
- [ ] Backup region configured (optional)

---

## Emergency Contacts

### Internal Team
- **On-Call Engineer**: [Rotation schedule link]
- **Team Lead**: [Contact info]
- **Database Admin**: [Contact info]
- **DevOps Lead**: [Contact info]

### External Vendors
- **Terminal49 Support**: support@terminal49.com
- **Supabase Support**: [Support portal link]
- **GCP Support**: [Support case link]

### Escalation Matrix

| Severity | Response Time | Escalation Path |
|----------|--------------|-----------------|
| P1 (Critical) | 15 minutes | On-call → Team Lead → VP Engineering |
| P2 (High) | 1 hour | On-call → Team Lead |
| P3 (Medium) | 4 hours | On-call Engineer |
| P4 (Low) | Next business day | Ticket queue |

---

## Appendix: Useful Commands

### Monitoring
```bash
# View real-time logs
gcloud logging tail "resource.type=cloud_function"

# Check function metrics
gcloud monitoring time-series list --filter='metric.type="cloudfunctions.googleapis.com/function/execution_count"'

# View Pub/Sub metrics
gcloud pubsub subscriptions describe terminal49-webhook-events-sub
```

### Debugging
```bash
# Get function details
gcloud functions describe <function-name> --region=us-central1 --gen2

# View recent errors
gcloud logging read "severity>=ERROR" --limit=50 --format=json

# Test database connection
psql "$SUPABASE_DB_URL" -c "SELECT 1;"
```

### Deployment
```bash
# Deploy function
gcloud functions deploy <function-name> --region=us-central1 --gen2

# Rollback function
gcloud functions deploy <function-name> --region=us-central1 --gen2 --source=gs://<bucket>/previous-version.zip

# Update environment variables
gcloud functions deploy <function-name> --update-env-vars KEY=VALUE
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-08  
**Next Review**: 2026-04-08
