# Terminal49 Webhook Infrastructure - Production Deployment Checklist

## Overview

This comprehensive checklist ensures all requirements are met before deploying the Terminal49 webhook infrastructure to production. Each item must be verified and checked off before proceeding to the next phase.

**Deployment Date**: _________________  
**Deployed By**: _________________  
**Reviewed By**: _________________  

---

## Phase 1: Pre-Deployment Preparation

### Infrastructure Provisioning

- [ ] **GCP Project Created**
  - Project ID: _________________
  - Billing account linked
  - Organization policies reviewed
  - Budget alerts configured ($___/month)

- [ ] **Required APIs Enabled**
  ```bash
  gcloud services enable cloudfunctions.googleapis.com
  gcloud services enable pubsub.googleapis.com
  gcloud services enable bigquery.googleapis.com
  gcloud services enable logging.googleapis.com
  gcloud services enable monitoring.googleapis.com
  gcloud services enable eventarc.googleapis.com
  gcloud services enable run.googleapis.com
  ```
  - [ ] Cloud Functions API
  - [ ] Pub/Sub API
  - [ ] BigQuery API
  - [ ] Cloud Logging API
  - [ ] Cloud Monitoring API
  - [ ] Eventarc API
  - [ ] Cloud Run API

- [ ] **Service Accounts Created**
  - [ ] `webhook-receiver-sa@<project>.iam.gserviceaccount.com`
    - [ ] Role: `roles/pubsub.publisher`
    - [ ] Role: `roles/logging.logWriter`
  - [ ] `event-processor-sa@<project>.iam.gserviceaccount.com`
    - [ ] Role: `roles/bigquery.dataEditor`
    - [ ] Role: `roles/logging.logWriter`
    - [ ] Role: `roles/pubsub.subscriber`

- [ ] **Terraform State Backend Configured**
  - [ ] GCS bucket created: `<project>-terraform-state`
  - [ ] Versioning enabled
  - [ ] Backend configuration in `terraform/main.tf`
  - [ ] State lock configured

### Database Setup

- [ ] **Supabase Project Created**
  - Project URL: _________________
  - Region: _________________
  - Plan: _________________ (Pro recommended)
  - [ ] Connection pooling enabled
  - [ ] SSL/TLS enforced

- [ ] **Database Schema Applied**
  ```bash
  psql "$SUPABASE_DB_URL" -f infrastructure/database/supabase_schema.sql
  ```
  - [ ] `shipments` table created
  - [ ] `containers` table created
  - [ ] `container_events` table created
  - [ ] `tracking_requests` table created
  - [ ] `webhook_deliveries` table created
  - [ ] All indexes created
  - [ ] Foreign key constraints verified

- [ ] **Database Backups Configured**
  - [ ] Automated daily backups enabled
  - [ ] Backup retention: 30 days
  - [ ] Point-in-time recovery enabled
  - [ ] Backup restoration tested

- [ ] **Database User Created**
  - Username: `terminal49_webhook`
  - [ ] Password stored in password manager
  - [ ] Least-privilege permissions granted
  - [ ] Connection tested from Cloud Shell

- [ ] **BigQuery Dataset Created**
  ```bash
  bq mk --dataset --location=US terminal49_webhooks
  ```
  - [ ] Dataset: `terminal49_webhooks`
  - [ ] Table: `raw_events_archive`
  - [ ] Partitioning configured (daily by `received_at`)
  - [ ] Expiration: 365 days
  - [ ] Schema applied from `infrastructure/database/bigquery_schema.sql`

### Secret Management

- [ ] **Secrets Obtained**
  - [ ] Terminal49 webhook secret obtained
  - [ ] Supabase connection string obtained
  - [ ] All secrets stored in password manager

- [ ] **Secrets Documented**
  - [ ] Secret rotation schedule documented
  - [ ] Secret access audit log enabled
  - [ ] Emergency secret rotation procedure documented

### Terminal49 Configuration

- [ ] **Terminal49 Account Verified**
  - [ ] API access confirmed
  - [ ] Webhook feature enabled
  - [ ] Rate limits understood: _________________

- [ ] **Test Webhook Available**
  - [ ] Test webhook created in Terminal49 sandbox (if available)
  - [ ] Test payloads collected for all event types

---

## Phase 2: Infrastructure Deployment

### Terraform Deployment

- [ ] **Terraform Initialized**
  ```bash
  cd infrastructure/terraform
  terraform init
  ```
  - [ ] Backend initialized successfully
  - [ ] Provider plugins downloaded
  - [ ] Modules initialized

- [ ] **Terraform Variables Configured**
  - [ ] `terraform.tfvars` created from `terraform.tfvars.example`
  - [ ] All required variables set:
    - [ ] `project_id`
    - [ ] `region`
    - [ ] `environment`
    - [ ] `webhook_secret` (use variable, not hardcoded)
    - [ ] `supabase_db_url` (use variable, not hardcoded)

- [ ] **Terraform Plan Reviewed**
  ```bash
  terraform plan -out=tfplan
  ```
  - [ ] Plan output reviewed
  - [ ] No unexpected resource deletions
  - [ ] Resource counts verified
  - [ ] Plan saved for audit

- [ ] **Terraform Applied**
  ```bash
  terraform apply tfplan
  ```
  - [ ] All resources created successfully
  - [ ] No errors in output
  - [ ] Resource IDs documented

- [ ] **Infrastructure Verified**
  - [ ] Pub/Sub topic created: `terminal49-webhook-events`
  - [ ] Pub/Sub subscription created: `terminal49-webhook-events-sub`
  - [ ] Dead letter queue created: `terminal49-webhook-events-dlq`
  - [ ] BigQuery dataset accessible
  - [ ] Service accounts have correct IAM roles

### Cloud Functions Deployment

- [ ] **Webhook Receiver Deployed**
  ```bash
  cd functions/webhook_receiver
  gcloud functions deploy terminal49-webhook-receiver \
    --region=us-central1 \
    --gen2 \
    --runtime=python311 \
    --source=. \
    --entry-point=webhook_receiver \
    --trigger-http \
    --allow-unauthenticated \
    --service-account=webhook-receiver-sa@<project>.iam.gserviceaccount.com \
    --set-env-vars TERMINAL49_WEBHOOK_SECRET=<secret>,GCP_PROJECT_ID=<project-id> \
    --timeout=60s \
    --memory=256MB \
    --max-instances=50 \
    --min-instances=1
  ```
  - [ ] Function deployed successfully
  - [ ] Function URL obtained: _________________
  - [ ] Environment variables set correctly
  - [ ] Service account attached
  - [ ] Timeout and memory configured

- [ ] **Event Processor Deployed**
  ```bash
  cd functions/event_processor
  gcloud functions deploy terminal49-event-processor \
    --region=us-central1 \
    --gen2 \
    --runtime=python311 \
    --source=. \
    --entry-point=process_webhook_event \
    --trigger-topic=terminal49-webhook-events \
    --service-account=event-processor-sa@<project>.iam.gserviceaccount.com \
    --set-env-vars SUPABASE_DB_URL=<db-url>,GCP_PROJECT_ID=<project-id>,BIGQUERY_DATASET=terminal49_webhooks,BIGQUERY_TABLE=raw_events_archive \
    --timeout=120s \
    --memory=512MB \
    --max-instances=100 \
    --min-instances=2
  ```
  - [ ] Function deployed successfully
  - [ ] Pub/Sub trigger configured
  - [ ] Environment variables set correctly
  - [ ] Service account attached
  - [ ] Timeout and memory configured

- [ ] **Function Permissions Verified**
  ```bash
  # Verify webhook receiver can publish to Pub/Sub
  gcloud pubsub topics get-iam-policy terminal49-webhook-events
  
  # Verify event processor can write to BigQuery
  bq show --format=prettyjson terminal49_webhooks.raw_events_archive
  ```
  - [ ] Webhook receiver has `pubsub.publisher` on topic
  - [ ] Event processor has `bigquery.dataEditor` on dataset
  - [ ] Event processor has Eventarc permissions for Cloud Run invocation

---

## Phase 3: Monitoring & Alerting

### Cloud Monitoring Setup

- [ ] **Dashboards Created**
  - [ ] Dashboard 1: Webhook Health
    - Request rate chart
    - Response time percentiles (p50, p95, p99)
    - Error rate chart
    - Signature validation failures
  - [ ] Dashboard 2: Event Processing
    - Pub/Sub message age
    - Processing latency
    - Database write latency
    - Dead letter queue depth
  - [ ] Dashboard 3: Data Quality
    - Events by type
    - Duplicate event rate
    - Null value frequency
    - Processing errors by type
  - [ ] Dashboard 4: Infrastructure
    - Function invocations
    - Memory usage
    - Cold start frequency
    - Database connection pool utilization

- [ ] **Alert Policies Configured**
  - [ ] Webhook error rate >5% (5-minute window)
  - [ ] Signature validation failures >10/hour
  - [ ] Event processing latency >30 seconds (p99)
  - [ ] Dead letter queue depth >100 messages
  - [ ] Database connection failures
  - [ ] Cloud Function error rate >1%

- [ ] **Notification Channels Configured**
  - [ ] Email: _________________
  - [ ] Slack: _________________ (optional)
  - [ ] PagerDuty: _________________ (optional)
  - [ ] SMS: _________________ (for P1 alerts)

- [ ] **Alert Severity Levels Defined**
  - [ ] P1 (Critical): Immediate page
  - [ ] P2 (High): Notify within 15 minutes
  - [ ] P3 (Medium): Notify within 1 hour
  - [ ] P4 (Low): Next business day

- [ ] **On-Call Rotation Configured**
  - [ ] On-call schedule created
  - [ ] Team members added
  - [ ] Escalation policy defined

### Logging Configuration

- [ ] **Log Sinks Created**
  - [ ] All function logs to Cloud Logging
  - [ ] Error logs to separate sink (optional)
  - [ ] Audit logs enabled

- [ ] **Log Retention Configured**
  - [ ] Default retention: 30 days
  - [ ] Error logs retention: 90 days
  - [ ] Audit logs retention: 365 days

- [ ] **Log-Based Metrics Created**
  - [ ] `signature_validation_failed`
  - [ ] `database_connection_failed`
  - [ ] `event_type_count`
  - [ ] `duplicate_event_detected`

---

## Phase 4: Testing & Validation

### Unit Testing

- [ ] **All Unit Tests Pass**
  ```bash
  pytest tests/unit/ -v
  ```
  - [ ] `test_webhook_validator.py`: ___/22 tests passed
  - [ ] `test_transformers.py`: ___/25 tests passed
  - [ ] `test_database_operations.py`: ___/15 tests passed
  - [ ] Total: ___/62 tests passed

### Integration Testing

- [ ] **Integration Tests Pass**
  ```bash
  pytest tests/integration/ -v
  ```
  - [ ] `test_webhook_receiver.py`: ___/17 tests passed
  - [ ] `test_event_processor.py`: ___/15 tests passed
  - [ ] Total: ___/32 tests passed

### Smoke Testing

- [ ] **Webhook Endpoint Accessible**
  ```bash
  curl -X GET https://<function-url>/health
  ```
  - [ ] Returns 200 OK
  - [ ] Health check response valid

- [ ] **Signature Validation Works**
  ```bash
  # Test with invalid signature
  curl -X POST https://<function-url> \
    -H "Content-Type: application/json" \
    -H "X-T49-Webhook-Signature: invalid" \
    -d '{"test": "data"}'
  ```
  - [ ] Returns 401 Unauthorized
  - [ ] Logged as signature validation failure

- [ ] **Pub/Sub Publishing Works**
  ```bash
  # Send valid test webhook
  # Check Pub/Sub metrics
  gcloud pubsub topics describe terminal49-webhook-events
  ```
  - [ ] Message published to topic
  - [ ] Message count increased

- [ ] **Event Processing Works**
  ```bash
  # Check event processor logs
  gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=terminal49-event-processor" --limit=10
  ```
  - [ ] Event received from Pub/Sub
  - [ ] Event processed successfully
  - [ ] No errors in logs

- [ ] **Database Writes Work**
  ```sql
  -- Check for test data
  SELECT COUNT(*) FROM webhook_deliveries WHERE received_at > NOW() - INTERVAL '1 hour';
  ```
  - [ ] Test data written to database
  - [ ] Foreign key relationships intact
  - [ ] Timestamps in UTC

- [ ] **BigQuery Archival Works**
  ```bash
  bq query --use_legacy_sql=false \
    'SELECT COUNT(*) FROM `terminal49_webhooks.raw_events_archive` WHERE received_at > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)'
  ```
  - [ ] Events archived to BigQuery
  - [ ] Partitioning working correctly
  - [ ] JSON payload intact

### Load Testing

- [ ] **Baseline Load Test**
  - [ ] Test: 50 requests/minute for 10 minutes
  - [ ] Result: ___% success rate
  - [ ] Average latency: ___ms
  - [ ] p95 latency: ___ms
  - [ ] p99 latency: ___ms
  - [ ] No errors observed

- [ ] **Peak Load Test**
  - [ ] Test: 200 requests/minute for 5 minutes
  - [ ] Result: ___% success rate
  - [ ] Average latency: ___ms
  - [ ] p95 latency: ___ms (target: <3000ms)
  - [ ] p99 latency: ___ms (target: <10000ms)
  - [ ] Auto-scaling triggered: Yes/No
  - [ ] Max instances reached: ___

- [ ] **Sustained Load Test**
  - [ ] Test: 100 requests/minute for 1 hour
  - [ ] Result: ___% success rate
  - [ ] Memory leaks: None detected
  - [ ] Connection pool stable: Yes/No
  - [ ] No degradation over time

### Failure Scenario Testing

- [ ] **Database Unavailable**
  - [ ] Events queue in Pub/Sub: Yes/No
  - [ ] Alerts triggered: Yes/No
  - [ ] Recovery after database restored: Yes/No

- [ ] **Invalid Event Data**
  - [ ] Event sent to DLQ: Yes/No
  - [ ] Error logged with context: Yes/No
  - [ ] No crash or data corruption: Yes/No

- [ ] **Duplicate Events**
  - [ ] Idempotency working: Yes/No
  - [ ] No duplicate database entries: Yes/No
  - [ ] Logged as duplicate: Yes/No

---

## Phase 5: Security Review

### Security Checklist

- [ ] **Signature Validation**
  - [ ] HMAC-SHA256 implemented correctly
  - [ ] Constant-time comparison used
  - [ ] Invalid signatures rejected
  - [ ] Validation failures logged

- [ ] **Secrets Management**
  - [ ] No secrets in source code
  - [ ] No secrets in logs
  - [ ] Environment variables encrypted at rest
  - [ ] Secret rotation procedure documented

- [ ] **IAM & Permissions**
  - [ ] Least-privilege principle applied
  - [ ] Service accounts used (not default)
  - [ ] No overly permissive roles
  - [ ] IAM audit log enabled

- [ ] **Network Security**
  - [ ] HTTPS enforced for all endpoints
  - [ ] TLS 1.2+ required
  - [ ] Database connections encrypted
  - [ ] No public database access

- [ ] **Data Protection**
  - [ ] PII handling reviewed (if applicable)
  - [ ] Data retention policies defined
  - [ ] Backup encryption enabled
  - [ ] Access logs enabled

- [ ] **Vulnerability Scanning**
  - [ ] Dependencies scanned for vulnerabilities
  - [ ] No critical vulnerabilities found
  - [ ] Security patches applied
  - [ ] Container images scanned (if applicable)

---

## Phase 6: Documentation

### Documentation Checklist

- [ ] **Architecture Documentation**
  - [ ] Architecture diagrams created
  - [ ] Component responsibilities documented
  - [ ] Data flow documented
  - [ ] Integration points documented

- [ ] **API Documentation**
  - [ ] Webhook endpoint documented
  - [ ] Request/response formats documented
  - [ ] Error codes documented
  - [ ] Authentication documented

- [ ] **Database Documentation**
  - [ ] Schema documented
  - [ ] Relationships documented
  - [ ] Indexes documented
  - [ ] Sample queries provided

- [ ] **Operational Runbooks**
  - [ ] Common issues documented
  - [ ] Resolution procedures documented
  - [ ] Escalation paths defined
  - [ ] Emergency contacts listed

- [ ] **Deployment Documentation**
  - [ ] Deployment steps documented
  - [ ] Configuration parameters documented
  - [ ] Rollback procedure documented
  - [ ] Disaster recovery plan documented

---

## Phase 7: Terminal49 Integration

### Webhook Configuration

- [ ] **Webhook Created in Terminal49**
  - [ ] Webhook URL: _________________
  - [ ] Webhook secret configured
  - [ ] Event types selected:
    - [ ] `tracking_request.*`
    - [ ] `container.transport.*`
    - [ ] `container.updated`
    - [ ] `container.created`
    - [ ] `container.pickup_lfd.changed`
    - [ ] `shipment.estimated.arrival`

- [ ] **Webhook Tested**
  - [ ] Test webhook sent from Terminal49
  - [ ] Webhook received successfully
  - [ ] Event processed correctly
  - [ ] Data visible in database

- [ ] **Webhook Monitoring**
  - [ ] Delivery success rate monitored
  - [ ] Failure notifications configured
  - [ ] Retry behavior understood

---

## Phase 8: Go-Live Preparation

### Pre-Launch Checklist

- [ ] **Team Readiness**
  - [ ] Team trained on system
  - [ ] Runbooks reviewed
  - [ ] On-call rotation active
  - [ ] Communication plan defined

- [ ] **Stakeholder Communication**
  - [ ] Launch date communicated
  - [ ] Expected behavior documented
  - [ ] Known limitations communicated
  - [ ] Support channels defined

- [ ] **Rollback Plan**
  - [ ] Rollback procedure documented
  - [ ] Rollback tested in staging
  - [ ] Rollback decision criteria defined
  - [ ] Rollback authority identified

- [ ] **Monitoring Ready**
  - [ ] All dashboards accessible
  - [ ] All alerts tested
  - [ ] Notification channels verified
  - [ ] Runbooks accessible

### Launch Window

- [ ] **Launch Timing**
  - Planned launch date: _________________
  - Launch time: _________________ (low-traffic period recommended)
  - Duration: _________________ (monitoring period)

- [ ] **Launch Team**
  - Launch lead: _________________
  - Technical lead: _________________
  - On-call engineer: _________________
  - Stakeholder contact: _________________

---

## Phase 9: Post-Launch Validation

### Immediate Post-Launch (First Hour)

- [ ] **System Health**
  - [ ] Webhooks being received: Yes/No
  - [ ] Events being processed: Yes/No
  - [ ] No errors in logs: Yes/No
  - [ ] Latency within SLA: Yes/No

- [ ] **Data Validation**
  - [ ] Data flowing to database: Yes/No
  - [ ] Data quality acceptable: Yes/No
  - [ ] No data loss: Yes/No
  - [ ] BigQuery archival working: Yes/No

- [ ] **Monitoring**
  - [ ] Dashboards showing data: Yes/No
  - [ ] Metrics within expected ranges: Yes/No
  - [ ] No alerts triggered: Yes/No

### First 24 Hours

- [ ] **Performance Metrics**
  - Webhook response time (p95): ___ms (target: <3000ms)
  - Event processing time (p99): ___ms (target: <10000ms)
  - Success rate: ___% (target: >99.9%)
  - Total events processed: ___

- [ ] **Error Analysis**
  - Total errors: ___
  - Error rate: ___% (target: <0.1%)
  - DLQ messages: ___ (target: 0)
  - Signature validation failures: ___ (target: 0)

- [ ] **Capacity Analysis**
  - Peak request rate: ___ req/min
  - Max instances used: ___
  - Database connection pool utilization: ___%
  - No capacity issues: Yes/No

### First Week

- [ ] **Operational Review**
  - [ ] Daily metrics reviewed
  - [ ] No major incidents
  - [ ] Performance within SLA
  - [ ] Team comfortable with operations

- [ ] **Data Quality Review**
  - [ ] Sample data reviewed
  - [ ] All event types processed correctly
  - [ ] No data anomalies
  - [ ] Stakeholders satisfied

- [ ] **Optimization Opportunities**
  - [ ] Performance bottlenecks identified
  - [ ] Cost optimization opportunities noted
  - [ ] Feature requests collected
  - [ ] Improvement backlog created

---

## Phase 10: Sign-Off

### Final Approval

- [ ] **Technical Sign-Off**
  - Name: _________________
  - Title: _________________
  - Date: _________________
  - Signature: _________________

- [ ] **Operations Sign-Off**
  - Name: _________________
  - Title: _________________
  - Date: _________________
  - Signature: _________________

- [ ] **Business Sign-Off**
  - Name: _________________
  - Title: _________________
  - Date: _________________
  - Signature: _________________

### Post-Deployment Actions

- [ ] **Documentation Updated**
  - [ ] Production URLs documented
  - [ ] Configuration documented
  - [ ] Lessons learned documented
  - [ ] Known issues documented

- [ ] **Handoff Complete**
  - [ ] Operations team trained
  - [ ] Support team notified
  - [ ] Monitoring transferred
  - [ ] On-call rotation active

- [ ] **Project Closure**
  - [ ] Project retrospective scheduled
  - [ ] Success metrics defined
  - [ ] Ongoing maintenance plan created
  - [ ] Future enhancements prioritized

---

## Rollback Procedure

If critical issues are discovered post-launch:

1. **Assess Severity**
   - [ ] Determine if rollback is necessary
   - [ ] Notify stakeholders
   - [ ] Document issue

2. **Disable Webhook**
   - [ ] Pause webhook in Terminal49 dashboard
   - [ ] Verify no new events being received

3. **Rollback Functions** (if needed)
   ```bash
   gcloud functions deploy terminal49-webhook-receiver \
     --source=gs://<bucket>/previous-version.zip
   
   gcloud functions deploy terminal49-event-processor \
     --source=gs://<bucket>/previous-version.zip
   ```

4. **Verify Rollback**
   - [ ] Previous version deployed
   - [ ] System stable
   - [ ] No data loss

5. **Post-Rollback**
   - [ ] Root cause analysis
   - [ ] Fix identified
   - [ ] Redeployment plan created

---

## Success Criteria

The deployment is considered successful when:

- [ ] All checklist items completed
- [ ] System operational for 7 days without major incidents
- [ ] Performance metrics within SLA
- [ ] No data loss or corruption
- [ ] Team comfortable with operations
- [ ] Stakeholders satisfied

---

## Appendix: Contact Information

### Internal Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| Project Lead | | | |
| Technical Lead | | | |
| DevOps Engineer | | | |
| Database Admin | | | |
| On-Call Engineer | | | |

### External Contacts

| Vendor | Contact | Email | Phone | Support Portal |
|--------|---------|-------|-------|----------------|
| Terminal49 | | support@terminal49.com | | |
| Supabase | | | | |
| GCP Support | | | | |

---

**Checklist Version**: 1.0  
**Last Updated**: 2026-01-08  
**Next Review**: After first production deployment
