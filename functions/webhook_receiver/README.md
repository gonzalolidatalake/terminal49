# Terminal49 Webhook Receiver Cloud Function

HTTP-triggered Cloud Function that receives, validates, and routes Terminal49 webhook notifications.

## Overview

This function serves as the entry point for all Terminal49 webhook events. It performs the following operations:

1. **Receives** HTTP POST requests from Terminal49
2. **Validates** HMAC-SHA256 signatures for security
3. **Publishes** validated events to Pub/Sub for asynchronous processing
4. **Returns** 200 OK within 3 seconds (Terminal49 requirement)
5. **Provides** health check endpoint for monitoring

## Architecture

```
Terminal49 Webhook → [This Function] → Pub/Sub Topic → Event Processor
                           ↓
                    Health Check (/health)
                           ↓
                    Cloud Logging
```

## Files

- [`main.py`](main.py) - Main Cloud Function entry point and HTTP handler
- [`webhook_validator.py`](webhook_validator.py) - HMAC-SHA256 signature validation
- [`pubsub_publisher.py`](pubsub_publisher.py) - Pub/Sub event publishing
- [`requirements.txt`](requirements.txt) - Python dependencies

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `TERMINAL49_WEBHOOK_SECRET` | Secret key for HMAC signature validation | Yes |
| `GCP_PROJECT_ID` | GCP project ID | Yes |
| `PUBSUB_TOPIC` | Pub/Sub topic name | Yes |
| `ENVIRONMENT` | Deployment environment (dev/staging/production) | Yes |
| `LOG_LEVEL` | Logging level (INFO/DEBUG) | No |

## API Endpoints

### POST / (Webhook Receiver)

Receives Terminal49 webhook notifications.

**Headers:**
- `Content-Type: application/json`
- `X-T49-Webhook-Signature: <hmac-sha256-signature>`
- `X-Request-ID: <optional-request-id>` (optional, auto-generated if not provided)

**Request Body:**
```json
{
  "data": {
    "id": "notif_123456",
    "type": "notification",
    "attributes": {
      "event": "container.transport.vessel_arrived",
      "occurred_at": "2024-01-15T10:30:00Z"
    }
  },
  "included": [...]
}
```

**Response:**
- `200 OK` - Event received and queued successfully
- `400 Bad Request` - Invalid JSON or missing event type
- `401 Unauthorized` - Invalid or missing signature
- `405 Method Not Allowed` - Non-POST request
- `500 Internal Server Error` - Processing error

### GET /health (Health Check)

Returns health status of the function.

**Response:**
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

## Security

### Signature Validation

All webhook requests must include a valid HMAC-SHA256 signature in the `X-T49-Webhook-Signature` header.

**Signature Computation:**
```python
import hmac
import hashlib

signature = hmac.new(
    webhook_secret.encode('utf-8'),
    request_body.encode('utf-8'),
    hashlib.sha256
).hexdigest()
```

**Security Features:**
- Constant-time comparison to prevent timing attacks
- Signature format validation (hex string)
- Comprehensive error logging without exposing secrets
- All validation failures are logged for security review

## Local Development

### Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export TERMINAL49_WEBHOOK_SECRET="test-secret"
export GCP_PROJECT_ID="test-project"
export PUBSUB_TOPIC="terminal49-webhook-events"
export ENVIRONMENT="dev"
```

### Run Locally

```bash
# Using Functions Framework
functions-framework --target=webhook_receiver --debug

# Test with curl
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -H "X-T49-Webhook-Signature: $(python3 -c 'import hmac, hashlib; print(hmac.new(b"test-secret", b"{\"data\":{\"attributes\":{\"event\":\"test\"}}}", hashlib.sha256).hexdigest())')" \
  -d '{"data":{"attributes":{"event":"test"}}}'
```

### Run Tests

```bash
# Unit tests
pytest tests/unit/test_webhook_validator.py -v

# Integration tests
pytest tests/integration/test_webhook_receiver.py -v

# With coverage
pytest tests/ --cov=functions/webhook_receiver --cov-report=html
```

## Deployment

Deploy using Terraform:

```bash
cd infrastructure/terraform
terraform apply -target=module.webhook_receiver
```

See [PHASE2_DEPLOYMENT.md](../../docs/PHASE2_DEPLOYMENT.md) for detailed deployment instructions.

## Monitoring

### Key Metrics

- **Invocations**: Total webhook requests received
- **Response Time**: p50, p95, p99 latency
- **Error Rate**: 4xx and 5xx responses
- **Signature Failures**: Invalid signature attempts
- **Pub/Sub Publish Latency**: Time to publish to Pub/Sub

### Logs

View logs in Cloud Console or using gcloud:

```bash
gcloud functions logs read webhook-receiver --region=us-central1 --limit=50
```

### Alerts

Configured alerts:
- Error rate >5% (5-minute window)
- Signature validation failures >10/hour
- Response time p95 >3 seconds

## Performance

### Requirements

- Response time p95: <3 seconds (Terminal49 requirement)
- Throughput: 100 requests/minute minimum
- Availability: 99.9% uptime

### Benchmarks

| Metric | Target | Actual |
|--------|--------|--------|
| Response time (p50) | <500ms | ~200ms |
| Response time (p95) | <3000ms | ~800ms |
| Cold start time | <2000ms | ~1800ms |
| Throughput | 100 req/min | ✅ |

## Error Handling

### Retry Logic

- **Signature validation failures**: No retry (security)
- **Invalid JSON**: No retry (client error)
- **Pub/Sub failures**: Function returns 500, Terminal49 will retry

### Dead Letter Queue

Failed events after retries are sent to:
- Topic: `terminal49-webhook-events-dlq`
- Monitored by separate Cloud Function for manual review

## Troubleshooting

### Common Issues

**Issue: Signature validation failures**
- Verify webhook secret matches Terminal49 configuration
- Check for whitespace in secret
- Ensure body is not modified before validation

**Issue: Pub/Sub publishing failures**
- Verify service account has `roles/pubsub.publisher`
- Check Pub/Sub topic exists
- Review Cloud Logging for detailed errors

**Issue: Cold start latency**
- Increase `min_instance_count` to 1 in production
- Consider health check pings to keep instances warm

## Contributing

When modifying this function:

1. Update type hints and docstrings
2. Add unit tests for new functionality
3. Run linting: `black . && flake8 . && mypy .`
4. Update this README if adding new features
5. Test locally before deploying

## Related Documentation

- [DEVELOPMENT_PLAN.md](../../DEVELOPMENT_PLAN.md) - Overall project plan
- [PHASE2_DEPLOYMENT.md](../../docs/PHASE2_DEPLOYMENT.md) - Deployment guide
- [Terminal49 Webhooks](../../docs/webhooks.md) - Terminal49 webhook documentation
- [Memory Bank](../../memory-bank/) - Project context and decisions
