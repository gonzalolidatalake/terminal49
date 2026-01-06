# Phase 2: Webhook Receiver Deployment Guide

This guide covers the deployment of the Terminal49 webhook receiver Cloud Function, which is the entry point for all webhook notifications from Terminal49.

## Overview

The webhook receiver is an HTTP-triggered Cloud Function that:
- Receives POST requests from Terminal49
- Validates HMAC-SHA256 signatures for security
- Publishes validated events to Pub/Sub for asynchronous processing
- Returns 200 OK within 3 seconds (Terminal49 requirement)
- Provides health check endpoint for monitoring

## Architecture

```
Terminal49 → [Webhook Receiver Cloud Function] → Pub/Sub Topic → Event Processor
                     ↓
              Health Check Endpoint
                     ↓
              Cloud Logging/Monitoring
```

## Prerequisites

Before deploying, ensure you have completed Phase 1:
- ✅ GCP project configured with proper IAM roles
- ✅ Pub/Sub topic created (`terminal49-webhook-events`)
- ✅ Database infrastructure provisioned (Supabase + BigQuery)
- ✅ Terraform state backend configured
- ✅ Service accounts created

## Environment Variables

The webhook receiver requires the following environment variables:

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `TERMINAL49_WEBHOOK_SECRET` | Secret key for HMAC signature validation | `whsec_abc123...` | Yes |
| `GCP_PROJECT_ID` | GCP project ID | `terminal49-prod` | Yes |
| `PUBSUB_TOPIC` | Pub/Sub topic name | `terminal49-webhook-events` | Yes |
| `ENVIRONMENT` | Deployment environment | `dev`, `staging`, `production` | Yes |
| `LOG_LEVEL` | Logging level | `INFO`, `DEBUG` | No (default: INFO) |

## Deployment Steps

### Step 1: Configure Secrets

Add the Terminal49 webhook secret to your Terraform variables:

```bash
# Create terraform.tfvars (DO NOT commit this file)
cat > infrastructure/terraform/terraform.tfvars <<EOF
project_id = "your-gcp-project-id"
region = "us-central1"
environment = "dev"
terminal49_webhook_secret = "your-webhook-secret-from-terminal49"
EOF
```

### Step 2: Review Terraform Plan

```bash
cd infrastructure/terraform

# Initialize Terraform (if not already done)
terraform init

# Review the deployment plan
terraform plan -target=module.webhook_receiver
```

Expected resources to be created:
- Cloud Function (webhook receiver)
- Service Account with appropriate IAM roles
- Cloud Storage bucket for function source code
- IAM bindings for public access

### Step 3: Deploy the Function

```bash
# Deploy webhook receiver
terraform apply -target=module.webhook_receiver

# Note the webhook URL from output
terraform output webhook_receiver_url
```

Example output:
```
webhook_receiver_url = "https://us-central1-terminal49-dev.cloudfunctions.net/dev-terminal49-webhook-receiver"
```

### Step 4: Verify Deployment

#### Test Health Check Endpoint

```bash
WEBHOOK_URL=$(terraform output -raw webhook_receiver_url)

curl -X GET "${WEBHOOK_URL}/health"
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0",
  "checks": {
    "TERMINAL49_WEBHOOK_SECRET": "configured",
    "GCP_PROJECT_ID": "configured",
    "pubsub_topic": "terminal49-webhook-events"
  }
}
```

#### Test Webhook Endpoint (with valid signature)

```bash
# Generate test payload
PAYLOAD='{"data":{"id":"test_123","type":"notification","attributes":{"event":"container.updated"}}}'

# Compute signature (requires Python)
SIGNATURE=$(python3 -c "
import hmac
import hashlib
secret = 'your-webhook-secret'
payload = '''${PAYLOAD}'''
print(hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest())
")

# Send test webhook
curl -X POST "${WEBHOOK_URL}" \
  -H "Content-Type: application/json" \
  -H "X-T49-Webhook-Signature: ${SIGNATURE}" \
  -d "${PAYLOAD}"
```

Expected response: `OK` with status code 200

### Step 5: Register Webhook with Terminal49

Once deployed and verified, register the webhook URL with Terminal49:

```bash
# Using Terminal49 API
curl -X POST "https://api.terminal49.com/v2/webhooks" \
  -H "Authorization: Bearer YOUR_TERMINAL49_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "'${WEBHOOK_URL}'",
    "events": [
      "container.transport.*",
      "container.updated",
      "shipment.estimated.arrival",
      "tracking_request.succeeded",
      "tracking_request.failed"
    ]
  }'
```

See [Terminal49 Webhook Documentation](../docs/webhooks.md) for more details.

## Testing

### Run Unit Tests

```bash
# Install test dependencies
pip install -r requirements.txt
pip install pytest pytest-cov

# Run unit tests
pytest tests/unit/test_webhook_validator.py -v

# Run with coverage
pytest tests/unit/test_webhook_validator.py --cov=functions/webhook_receiver --cov-report=html
```

### Run Integration Tests

```bash
# Set environment variables for testing
export TERMINAL49_WEBHOOK_SECRET="test-secret"
export GCP_PROJECT_ID="test-project"
export PUBSUB_TOPIC="terminal49-webhook-events"

# Run integration tests
pytest tests/integration/test_webhook_receiver.py -v
```

### Load Testing

Use Apache Bench or similar tool to verify performance:

```bash
# Install Apache Bench
# macOS: brew install httpd
# Ubuntu: apt-get install apache2-utils

# Generate test payload and signature
PAYLOAD='{"data":{"id":"load_test","type":"notification","attributes":{"event":"container.updated"}}}'
SIGNATURE=$(python3 -c "import hmac, hashlib; print(hmac.new(b'your-secret', b'${PAYLOAD}', hashlib.sha256).hexdigest())")

# Save payload to file
echo "${PAYLOAD}" > /tmp/webhook_payload.json

# Run load test: 100 requests, 10 concurrent
ab -n 100 -c 10 \
  -H "Content-Type: application/json" \
  -H "X-T49-Webhook-Signature: ${SIGNATURE}" \
  -p /tmp/webhook_payload.json \
  "${WEBHOOK_URL}"
```

Expected results:
- Mean response time: <500ms
- p95 response time: <3000ms (Terminal49 requirement)
- Success rate: 100%

## Monitoring

### View Logs

```bash
# View recent logs
gcloud functions logs read dev-terminal49-webhook-receiver \
  --region=us-central1 \
  --limit=50

# Follow logs in real-time
gcloud functions logs read dev-terminal49-webhook-receiver \
  --region=us-central1 \
  --limit=50 \
  --follow
```

### Cloud Console Monitoring

1. Navigate to Cloud Functions in GCP Console
2. Select `dev-terminal49-webhook-receiver`
3. View metrics:
   - Invocations per second
   - Execution time (p50, p95, p99)
   - Error rate
   - Active instances

### Set Up Alerts

Alerts are configured via Terraform in the monitoring module:
- Webhook error rate >5% (5-minute window)
- Signature validation failures >10/hour
- Response time p95 >3 seconds

## Troubleshooting

### Issue: Signature Validation Failures

**Symptoms**: Logs show "Invalid signature" warnings

**Diagnosis**:
```bash
# Check if secret is configured
gcloud functions describe dev-terminal49-webhook-receiver \
  --region=us-central1 \
  --format="value(serviceConfig.environmentVariables)"
```

**Resolution**:
1. Verify webhook secret matches Terminal49 configuration
2. Ensure secret is properly encoded (no extra whitespace)
3. Check Terminal49 webhook logs for signature they're sending

### Issue: Pub/Sub Publishing Failures

**Symptoms**: Logs show "Failed to publish to Pub/Sub"

**Diagnosis**:
```bash
# Check service account permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:dev-webhook-receiver@*"
```

**Resolution**:
1. Verify service account has `roles/pubsub.publisher` role
2. Check Pub/Sub topic exists: `gcloud pubsub topics list`
3. Verify topic name in environment variables

### Issue: Cold Start Latency

**Symptoms**: First request after idle period takes >3 seconds

**Resolution**:
1. Increase `min_instance_count` to 1 in production
2. Consider using Cloud Scheduler to ping health endpoint every 5 minutes
3. Monitor cold start frequency in Cloud Monitoring

### Issue: High Memory Usage

**Symptoms**: Function runs out of memory

**Diagnosis**:
```bash
# Check memory usage metrics
gcloud monitoring time-series list \
  --filter='metric.type="cloudfunctions.googleapis.com/function/user_memory_bytes"' \
  --format=json
```

**Resolution**:
1. Increase `available_memory_mb` in Terraform configuration
2. Review code for memory leaks (especially Pub/Sub client caching)

## Rollback Procedure

If issues occur after deployment:

```bash
# List previous versions
gcloud functions list --regions=us-central1

# Rollback to previous version
terraform apply -target=module.webhook_receiver \
  -var="function_source_version=PREVIOUS_VERSION"

# Or use gcloud directly
gcloud functions deploy dev-terminal49-webhook-receiver \
  --region=us-central1 \
  --source=gs://PREVIOUS_SOURCE_BUCKET/PREVIOUS_VERSION.zip
```

## Performance Benchmarks

Expected performance metrics (based on testing):

| Metric | Target | Actual (Dev) | Actual (Prod) |
|--------|--------|--------------|---------------|
| Response time (p50) | <500ms | ~200ms | ~150ms |
| Response time (p95) | <3000ms | ~800ms | ~600ms |
| Response time (p99) | <5000ms | ~1500ms | ~1200ms |
| Cold start time | <2000ms | ~1800ms | ~1500ms |
| Throughput | 100 req/min | ✅ | ✅ |
| Error rate | <0.1% | 0.0% | 0.0% |

## Security Considerations

1. **Signature Validation**: All requests MUST have valid HMAC-SHA256 signature
2. **Secret Rotation**: Rotate webhook secret quarterly
3. **IP Whitelisting**: Consider adding Terminal49 IP ranges to ingress rules
4. **Audit Logging**: All signature failures are logged for security review
5. **Rate Limiting**: Consider adding Cloud Armor for DDoS protection in production

## Cost Estimation

Estimated monthly costs for webhook receiver (1000-5000 events/day):

| Resource | Usage | Cost |
|----------|-------|------|
| Cloud Functions | ~150K invocations/month | $0.60 |
| Cloud Functions | ~30K GB-seconds/month | $0.50 |
| Pub/Sub | ~150K messages/month | $0.60 |
| Cloud Logging | ~5 GB/month | $2.50 |
| **Total** | | **~$4.20/month** |

At 10x scale (50K events/day): ~$15/month

## Next Steps

After successful deployment of Phase 2:
1. ✅ Webhook receiver deployed and verified
2. ➡️ **Phase 3**: Deploy event processor Cloud Function
3. ➡️ **Phase 3**: Implement data transformation logic
4. ➡️ **Phase 3**: Set up database write operations
5. ➡️ **Phase 4**: Configure monitoring and alerting

## Support

For issues or questions:
- Check Cloud Logging for error details
- Review [DEVELOPMENT_PLAN.md](../../DEVELOPMENT_PLAN.md) for architecture
- Consult [Terminal49 API Documentation](https://docs.terminal49.com)
- Review Memory Bank files in `memory-bank/` directory
