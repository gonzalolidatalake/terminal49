# Terminal49 Webhook Infrastructure - Development Plan

## Executive Summary

This plan outlines the development of a production-ready webhook infrastructure on Google Cloud Platform to receive, process, and store Terminal49 container and shipment tracking data. The system will handle 1000-5000 events/day initially, with capability to scale 10x, serving as the foundational data layer for all track and trace functionality.

**Architecture Pattern**: Event-driven, serverless architecture using Cloud Functions (2nd gen), Pub/Sub for event distribution, and BigQuery/Supabase for data storage.

**Timeline**: 5 weeks (MVP to Production)

**Key Success Metrics**:
- Webhook response time <3 seconds (p95)
- 99.9% uptime
- Idempotent event processing
- Zero data loss under normal conditions

---

## Phase 1: Foundation & Infrastructure Setup

### Phase Description
Establish GCP project, database infrastructure, and development environment. Make critical architectural decisions and create foundational schemas.

### Deliverables
1. GCP project configured with proper IAM roles
2. Database selection finalized (BigQuery vs Supabase)
3. Database schema designed and implemented
4. Development environment setup
5. Infrastructure as Code (Terraform) foundation
6. Secret management solution implemented

### Tasks

#### 1.1 GCP Project Setup
**Description**: Initialize GCP project with proper organization, billing, and IAM configuration.

**Acceptance Criteria**:
- GCP project created with appropriate naming convention
- Billing account linked
- Service accounts created with least-privilege IAM roles
- Cloud Logging and Cloud Monitoring enabled
- API services enabled (Cloud Functions, Pub/Sub, BigQuery, Secret Manager alternatives)

**Dependencies**: None

**Effort**: Small

**Risk**: Low

#### 1.2 Database Technology Selection
**Description**: Evaluate and decide between BigQuery and Supabase for structured tracking data storage.

**Acceptance Criteria**:
- Trade-off analysis documented comparing:
  - Query performance for typical access patterns
  - Cost at scale (1000-5000 events/day, 10x growth)
  - Real-time query capabilities
  - Integration complexity with Cloud Functions
  - Data modeling flexibility
  - Backup and disaster recovery
- Decision documented in Memory Bank decisionLog.md
- Rationale includes specific use cases and constraints

**Dependencies**: None

**Effort**: Medium

**Risk**: Medium (impacts entire architecture)

**Recommendation**: 
- **BigQuery** for raw event archival (append-only, cost-effective for large volumes)
- **Supabase PostgreSQL** for operational data (shipments, containers, real-time queries)
- Hybrid approach provides best of both worlds

#### 1.3 Secret Management Solution
**Description**: Implement cost-effective alternative to Secret Manager for API keys and webhook secrets.

**Acceptance Criteria**:
- Solution selected (options: Cloud Run environment variables, encrypted Cloud Storage, HashiCorp Vault, GCP Secret Manager with caching)
- Security assessment completed
- Implementation guide documented
- Secrets rotation strategy defined

**Dependencies**: 1.1

**Effort**: Small

**Risk**: Medium (security-critical)

**Recommendation**: Use Cloud Functions environment variables with encryption at rest, cached in function memory. Rotate secrets quarterly.

#### 1.4 Database Schema Design
**Description**: Design comprehensive database schema for shipments, containers, events, and tracking requests.

**Acceptance Criteria**:
- Entity-Relationship Diagram (ERD) created
- Schema supports all Terminal49 webhook event types
- Proper indexing strategy defined
- Foreign key relationships established
- JSONB columns for flexible/nested data (location, raw payloads)
- Migration scripts created
- Schema handles nullable fields gracefully
- Idempotency constraints implemented (unique on event_id)

**Dependencies**: 1.2

**Effort**: Large

**Risk**: High (foundational for all data operations)

**Core Tables**:
```
shipments
- id (UUID, PK)
- t49_shipment_id (UUID, unique)
- bill_of_lading_number (VARCHAR)
- normalized_number (VARCHAR)
- shipping_line_scac (VARCHAR)
- port_of_lading_locode (VARCHAR)
- port_of_discharge_locode (VARCHAR)
- destination_locode (VARCHAR, nullable)
- pod_vessel_name (VARCHAR, nullable)
- pod_vessel_imo (VARCHAR, nullable)
- pol_atd_at (TIMESTAMP, nullable)
- pod_eta_at (TIMESTAMP, nullable)
- pod_ata_at (TIMESTAMP, nullable)
- raw_data (JSONB)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- indexes: bill_of_lading_number, t49_shipment_id, shipping_line_scac

containers
- id (UUID, PK)
- t49_container_id (UUID, unique)
- shipment_id (UUID, FK -> shipments)
- number (VARCHAR)
- seal_number (VARCHAR, nullable)
- equipment_type (VARCHAR, nullable)
- equipment_length (INTEGER, nullable)
- equipment_height (VARCHAR, nullable)
- pod_arrived_at (TIMESTAMP, nullable)
- pod_discharged_at (TIMESTAMP, nullable)
- pickup_lfd (TIMESTAMP, nullable)
- available_for_pickup (BOOLEAN, nullable)
- current_status (VARCHAR)
- raw_data (JSONB)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- indexes: number, t49_container_id, shipment_id, current_status

container_events
- id (UUID, PK)
- t49_event_id (UUID, unique) -- for idempotency
- container_id (UUID, FK -> containers)
- shipment_id (UUID, FK -> shipments)
- event_type (VARCHAR) -- e.g., container.transport.vessel_arrived
- event_timestamp (TIMESTAMP, nullable)
- location_locode (VARCHAR, nullable)
- data_source (VARCHAR) -- shipping_line, terminal, ais
- raw_data (JSONB)
- created_at (TIMESTAMP)
- indexes: t49_event_id, container_id, event_type, event_timestamp

tracking_requests
- id (UUID, PK)
- t49_tracking_request_id (UUID, unique)
- request_number (VARCHAR)
- request_type (VARCHAR) -- bill_of_lading, booking_number, container
- scac (VARCHAR)
- status (VARCHAR) -- pending, created, failed, tracking_stopped
- failed_reason (VARCHAR, nullable)
- shipment_id (UUID, FK -> shipments, nullable)
- raw_data (JSONB)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- indexes: request_number, t49_tracking_request_id, status

webhook_deliveries
- id (UUID, PK)
- t49_notification_id (UUID, unique)
- event_type (VARCHAR)
- delivery_status (VARCHAR) -- pending, succeeded, failed
- processing_status (VARCHAR) -- received, processing, completed, failed
- processing_error (TEXT, nullable)
- raw_payload (JSONB)
- received_at (TIMESTAMP)
- processed_at (TIMESTAMP, nullable)
- indexes: t49_notification_id, event_type, processing_status

raw_events_archive (BigQuery)
- event_id (STRING)
- received_at (TIMESTAMP)
- event_type (STRING)
- payload (JSON)
- signature_valid (BOOLEAN)
- processing_duration_ms (INTEGER)
```

#### 1.5 Development Environment Setup
**Description**: Configure local development environment and CI/CD pipeline foundation.

**Acceptance Criteria**:
- Python 3.11+ environment configured
- Required dependencies documented (requirements.txt)
- Pre-commit hooks configured (black, flake8, mypy)
- VS Code/IDE settings shared
- Local testing strategy defined
- Git repository structure established

**Dependencies**: None

**Effort**: Small

**Risk**: Low

#### 1.6 Terraform Infrastructure Foundation
**Description**: Create Terraform modules for infrastructure as code.

**Acceptance Criteria**:
- Terraform project structure created
- Modules for: Cloud Functions, Pub/Sub, BigQuery, Supabase (if selected)
- Environment separation (dev/staging/prod)
- State management configured (Cloud Storage backend)
- Variables and outputs defined
- Documentation for deployment process

**Dependencies**: 1.1, 1.2

**Effort**: Medium

**Risk**: Low

### Testing Strategy
- Database schema validation with sample Terminal49 data
- Terraform plan/apply in dev environment
- Secret retrieval performance testing

### Success Metrics
- All GCP services accessible
- Database schema supports all webhook event types
- Terraform can provision infrastructure in <5 minutes
- Development environment reproducible

---

## Phase 2: Core Webhook Infrastructure

### Phase Description
Implement webhook receiver Cloud Function with signature validation, basic event routing, and Pub/Sub integration.

### Deliverables
1. Webhook receiver Cloud Function (2nd gen)
2. HMAC-SHA256 signature validation
3. Pub/Sub topic and subscription configuration
4. Basic error handling and logging
5. Health check endpoint

### Tasks

#### 2.1 Webhook Receiver Cloud Function
**Description**: Create Cloud Function to receive POST requests from Terminal49.

**Acceptance Criteria**:
- Cloud Function (2nd gen) responds to HTTP POST
- Returns 200 OK within 5 seconds (Terminal49 requirement)
- Accepts JSON payload
- Structured logging implemented (Cloud Logging)
- Request ID tracking for correlation
- Handles concurrent requests (auto-scaling)
- Environment variables configured for secrets
- Timeout set to 60 seconds
- Memory allocation: 256MB (adjustable)

**Dependencies**: 1.1, 1.3, 1.6

**Effort**: Medium

**Risk**: Medium

**Code Structure**:
```python
# main.py
import functions_framework
import json
import logging
from datetime import datetime
from webhook_validator import validate_signature
from pubsub_publisher import publish_event

@functions_framework.http
def webhook_receiver(request):
    """
    Receives Terminal49 webhook notifications.
    Validates signature and publishes to Pub/Sub.
    """
    start_time = datetime.utcnow()
    request_id = request.headers.get('X-Request-ID', generate_request_id())
    
    # Log receipt
    logging.info(f"Webhook received", extra={
        'request_id': request_id,
        'content_length': request.content_length
    })
    
    try:
        # Validate signature
        signature = request.headers.get('X-T49-Webhook-Signature')
        body = request.get_data(as_text=True)
        
        if not validate_signature(body, signature):
            logging.warning(f"Invalid signature", extra={'request_id': request_id})
            return ('Unauthorized', 401)
        
        # Parse payload
        payload = json.loads(body)
        event_type = payload['data']['attributes']['event']
        
        # Publish to Pub/Sub
        publish_event(payload, event_type, request_id)
        
        # Calculate processing time
        duration_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
        logging.info(f"Webhook processed", extra={
            'request_id': request_id,
            'event_type': event_type,
            'duration_ms': duration_ms
        })
        
        return ('OK', 200)
        
    except json.JSONDecodeError as e:
        logging.error(f"Invalid JSON", extra={'request_id': request_id, 'error': str(e)})
        return ('Bad Request', 400)
    except Exception as e:
        logging.error(f"Processing error", extra={'request_id': request_id, 'error': str(e)})
        return ('Internal Server Error', 500)
```

#### 2.2 Signature Validation Implementation
**Description**: Implement HMAC-SHA256 signature validation for webhook security.

**Acceptance Criteria**:
- HMAC-SHA256 validation function implemented
- Compares X-T49-Webhook-Signature header with computed signature
- Constant-time comparison to prevent timing attacks
- Logs validation failures with context
- Unit tests with known good/bad signatures
- Performance: validation completes in <100ms

**Dependencies**: 2.1

**Effort**: Small

**Risk**: High (security-critical)

**Implementation**:
```python
# webhook_validator.py
import hmac
import hashlib
import os

def validate_signature(body: str, signature: str) -> bool:
    """
    Validates Terminal49 webhook signature using HMAC-SHA256.
    
    Args:
        body: Raw request body as string
        signature: X-T49-Webhook-Signature header value
        
    Returns:
        True if signature is valid, False otherwise
    """
    if not signature:
        return False
    
    secret = os.environ.get('TERMINAL49_WEBHOOK_SECRET')
    if not secret:
        raise ValueError("TERMINAL49_WEBHOOK_SECRET not configured")
    
    # Compute HMAC-SHA256
    computed_signature = hmac.new(
        secret.encode('utf-8'),
        body.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    # Constant-time comparison
    return hmac.compare_digest(computed_signature, signature)
```

#### 2.3 Pub/Sub Integration
**Description**: Configure Pub/Sub topic and implement event publishing.

**Acceptance Criteria**:
- Pub/Sub topic created: `terminal49-webhook-events`
- Dead letter topic created: `terminal49-webhook-events-dlq`
- Publisher function implemented with retry logic
- Message attributes include: event_type, request_id, timestamp
- Ordering not required (events have timestamps)
- Error handling for publish failures
- Monitoring configured for publish latency

**Dependencies**: 2.1

**Effort**: Small

**Risk**: Low

**Implementation**:
```python
# pubsub_publisher.py
from google.cloud import pubsub_v1
import json
import os

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(
    os.environ.get('GCP_PROJECT_ID'),
    'terminal49-webhook-events'
)

def publish_event(payload: dict, event_type: str, request_id: str) -> str:
    """
    Publishes webhook event to Pub/Sub.
    
    Returns:
        Message ID from Pub/Sub
    """
    message_data = json.dumps(payload).encode('utf-8')
    
    future = publisher.publish(
        topic_path,
        message_data,
        event_type=event_type,
        request_id=request_id,
        timestamp=datetime.utcnow().isoformat()
    )
    
    return future.result(timeout=5.0)
```

#### 2.4 Error Handling & Logging
**Description**: Implement comprehensive error handling and structured logging.

**Acceptance Criteria**:
- All exceptions caught and logged with context
- Structured logging with JSON format
- Log levels appropriate (INFO, WARNING, ERROR)
- Request correlation via request_id
- Performance metrics logged (processing time)
- Error alerts configured in Cloud Monitoring
- Graceful degradation (return 500 but log details)

**Dependencies**: 2.1

**Effort**: Small

**Risk**: Low

#### 2.5 Health Check Endpoint
**Description**: Add health check endpoint for monitoring.

**Acceptance Criteria**:
- GET /health endpoint returns 200 OK
- Checks Pub/Sub connectivity
- Checks secret availability
- Response includes version info
- Used by uptime monitoring

**Dependencies**: 2.1

**Effort**: Small

**Risk**: Low

### Testing Strategy
- Unit tests for signature validation (valid/invalid signatures)
- Integration tests with mock Terminal49 payloads
- Load testing: 100 requests/minute sustained
- Failure scenario testing (invalid JSON, missing signature, Pub/Sub down)
- Cold start performance measurement

### Success Metrics
- Webhook responds <3 seconds (p95)
- Signature validation 100% accurate
- Zero false positives/negatives in signature validation
- Pub/Sub publish success rate >99.9%
- Cloud Function auto-scales to handle traffic spikes

---

## Phase 3: Event Processing & Data Storage

### Phase Description
Implement event processor Cloud Function that subscribes to Pub/Sub, transforms Terminal49 data, and writes to database with idempotency.

### Deliverables
1. Event processor Cloud Function
2. Data transformation logic for all event types
3. Database write operations (upsert patterns)
4. Idempotency implementation
5. Raw event archival to BigQuery
6. Dead letter queue handling

### Tasks

#### 3.1 Event Processor Cloud Function
**Description**: Create Cloud Function triggered by Pub/Sub to process events.

**Acceptance Criteria**:
- Cloud Function triggered by Pub/Sub subscription
- Processes events asynchronously
- Acknowledges messages only after successful processing
- Handles message retries (exponential backoff)
- Timeout: 120 seconds
- Memory: 512MB
- Concurrent execution limit configured

**Dependencies**: 1.4, 2.3

**Effort**: Large

**Risk**: Medium

**Code Structure**:
```python
# event_processor/main.py
import functions_framework
import base64
import json
from database import get_db_connection
from transformers import transform_event
from bigquery_archiver import archive_raw_event

@functions_framework.cloud_event
def process_webhook_event(cloud_event):
    """
    Processes Terminal49 webhook events from Pub/Sub.
    Transforms data and writes to database.
    """
    # Decode Pub/Sub message
    message_data = base64.b64decode(cloud_event.data["message"]["data"])
    payload = json.loads(message_data)
    
    attributes = cloud_event.data["message"]["attributes"]
    event_type = attributes.get('event_type')
    request_id = attributes.get('request_id')
    
    logging.info(f"Processing event", extra={
        'request_id': request_id,
        'event_type': event_type
    })
    
    try:
        # Archive raw event to BigQuery
        archive_raw_event(payload, event_type, request_id)
        
        # Transform and write to database
        with get_db_connection() as conn:
            transform_event(payload, event_type, conn)
        
        logging.info(f"Event processed successfully", extra={
            'request_id': request_id,
            'event_type': event_type
        })
        
    except Exception as e:
        logging.error(f"Event processing failed", extra={
            'request_id': request_id,
            'event_type': event_type,
            'error': str(e)
        })
        raise  # Trigger retry
```

#### 3.2 Data Transformation Logic
**Description**: Implement transformation logic for all Terminal49 event types.

**Acceptance Criteria**:
- Handlers for all event types:
  - tracking_request.succeeded/failed/awaiting_manifest/tracking_stopped
  - container.transport.* (20+ event types)
  - container.updated
  - container.created
  - shipment.estimated.arrival
  - container.pickup_lfd.changed
- Extracts entities from nested JSON (shipments, containers, events)
- Handles null values gracefully
- Normalizes timestamps to UTC
- Validates required fields
- Unit tests for each event type

**Dependencies**: 3.1

**Effort**: Large

**Risk**: Medium

**Implementation Pattern**:
```python
# transformers/container_transport.py
def transform_container_transport_event(payload: dict, conn):
    """
    Transforms container.transport.* events.
    Extracts container, shipment, and transport event data.
    """
    # Extract from included array
    included = payload.get('included', [])
    
    # Find entities by type
    shipments = [i for i in included if i['type'] == 'shipment']
    containers = [i for i in included if i['type'] == 'container']
    transport_events = [i for i in included if i['type'] == 'transport_event']
    
    # Upsert shipment
    for shipment_data in shipments:
        upsert_shipment(shipment_data, conn)
    
    # Upsert container
    for container_data in containers:
        upsert_container(container_data, conn)
    
    # Insert transport event (append-only)
    for event_data in transport_events:
        insert_transport_event(event_data, conn)
```

#### 3.3 Database Write Operations
**Description**: Implement upsert and insert operations with proper error handling.

**Acceptance Criteria**:
- Upsert functions for shipments and containers (INSERT ... ON CONFLICT UPDATE)
- Insert function for events (append-only)
- Transaction management (commit/rollback)
- Connection pooling configured
- Deadlock retry logic
- Foreign key constraint handling
- Performance: <100ms per write operation

**Dependencies**: 3.1, 3.2

**Effort**: Medium

**Risk**: Medium

**Implementation**:
```python
# database/operations.py
def upsert_shipment(shipment_data: dict, conn):
    """
    Upserts shipment data using Terminal49 shipment ID as unique key.
    """
    cursor = conn.cursor()
    
    query = """
        INSERT INTO shipments (
            t49_shipment_id, bill_of_lading_number, normalized_number,
            shipping_line_scac, port_of_lading_locode, port_of_discharge_locode,
            pod_vessel_name, pod_eta_at, pod_ata_at, raw_data, updated_at
        ) VALUES (
            %(t49_id)s, %(bol)s, %(normalized)s, %(scac)s, %(pol)s, %(pod)s,
            %(vessel)s, %(eta)s, %(ata)s, %(raw)s, NOW()
        )
        ON CONFLICT (t49_shipment_id) DO UPDATE SET
            bill_of_lading_number = EXCLUDED.bill_of_lading_number,
            pod_eta_at = EXCLUDED.pod_eta_at,
            pod_ata_at = EXCLUDED.pod_ata_at,
            raw_data = EXCLUDED.raw_data,
            updated_at = NOW()
    """
    
    params = extract_shipment_params(shipment_data)
    cursor.execute(query, params)
    conn.commit()
```

#### 3.4 Idempotency Implementation
**Description**: Ensure event processing is idempotent using Terminal49 event IDs.

**Acceptance Criteria**:
- Unique constraint on t49_event_id in container_events table
- Duplicate events silently ignored (INSERT ... ON CONFLICT DO NOTHING)
- Webhook deliveries table tracks processing status
- Replay safety: processing same event multiple times produces same result
- Unit tests verify idempotency

**Dependencies**: 3.3

**Effort**: Small

**Risk**: High (data integrity critical)

#### 3.5 BigQuery Raw Event Archival
**Description**: Archive all raw webhook payloads to BigQuery for debugging and reprocessing.

**Acceptance Criteria**:
- BigQuery dataset and table created
- Streaming insert configured
- Schema includes: event_id, received_at, event_type, payload (JSON), signature_valid
- Partitioned by received_at (daily)
- Retention policy: 1 year
- Cost monitoring configured

**Dependencies**: 3.1

**Effort**: Small

**Risk**: Low

#### 3.6 Dead Letter Queue Handling
**Description**: Implement handling for events that fail processing after retries.

**Acceptance Criteria**:
- Dead letter subscription configured (max 5 retries)
- Separate Cloud Function monitors DLQ
- Failed events logged with full context
- Alert triggered for DLQ messages
- Manual reprocessing capability

**Dependencies**: 3.1

**Effort**: Small

**Risk**: Low

### Testing Strategy
- Unit tests for each transformation function
- Integration tests with real Terminal49 webhook samples
- Idempotency tests (process same event 3x, verify single DB entry)
- Database constraint tests (foreign keys, unique constraints)
- Load testing: 100 events/second sustained
- Failure recovery testing (database down, partial writes)

### Success Metrics
- Event processing latency <10 seconds (p99)
- Zero data loss (all events archived to BigQuery)
- Idempotency 100% effective
- Database write success rate >99.9%
- All 30+ event types handled correctly

---

## Phase 4: Monitoring, Alerting & Production Readiness

### Phase Description
Implement comprehensive monitoring, alerting, documentation, and operational runbooks for production deployment.

### Deliverables
1. Cloud Monitoring dashboards
2. Alert policies and notification channels
3. Performance benchmarks
4. Operational runbooks
5. API documentation
6. Load testing results
7. Production deployment checklist

### Tasks

#### 4.1 Cloud Monitoring Dashboards
**Description**: Create dashboards for operational visibility.

**Acceptance Criteria**:
- Dashboard 1: Webhook Health
  - Request rate (requests/min)
  - Response time (p50, p95, p99)
  - Error rate (4xx, 5xx)
  - Signature validation failures
- Dashboard 2: Event Processing
  - Pub/Sub message age
  - Processing latency
  - Database write latency
  - Dead letter queue depth
- Dashboard 3: Data Quality
  - Events by type (last 24h)
  - Duplicate event rate
  - Null value frequency
  - Processing errors by type
- Dashboard 4: Infrastructure
  - Cloud Function invocations
  - Memory usage
  - Cold start frequency
  - Database connection pool utilization

**Dependencies**: All previous phases

**Effort**: Medium

**Risk**: Low

#### 4.2 Alert Policies
**Description**: Configure alerts for critical issues.

**Acceptance Criteria**:
- Alert: Webhook error rate >5% (5-minute window)
- Alert: Signature validation failures >10/hour
- Alert: Event processing latency >30 seconds (p99)
- Alert: Dead letter queue depth >100 messages
- Alert: Database connection failures
- Alert: Cloud Function error rate >1%
- Notification channels: Email, Slack, PagerDuty
- Alert severity levels defined (P1-P4)
- On-call rotation configured

**Dependencies**: 4.1

**Effort**: Small

**Risk**: Low

#### 4.3 Performance Benchmarking
**Description**: Conduct comprehensive performance testing and document results.

**Acceptance Criteria**:
- Load test: 100 requests/minute sustained for 1 hour
- Spike test: 1000 requests/minute for 5 minutes
- Soak test: 50 requests/minute for 24 hours
- Measure and document:
  - Webhook response time (p50, p95, p99)
  - Event processing latency (p50, p95, p99)
  - Database write throughput
  - Cold start impact
  - Cost per 1000 events
- Results meet requirements (p95 <3s, p99 <10s)

**Dependencies**: All previous phases

**Effort**: Medium

**Risk**: Medium

#### 4.4 Operational Runbooks
**Description**: Create runbooks for common operational scenarios.

**Acceptance Criteria**:
- Runbook: Webhook receiving errors
- Runbook: Signature validation failures
- Runbook: Event processing delays
- Runbook: Database connection issues
- Runbook: Dead letter queue processing
- Runbook: Secret rotation procedure
- Runbook: Scaling for traffic spikes
- Runbook: Disaster recovery
- Each runbook includes:
  - Symptoms
  - Diagnosis steps
  - Resolution steps
  - Escalation path

**Dependencies**: 4.1, 4.2

**Effort**: Medium

**Risk**: Low

#### 4.5 API Documentation
**Description**: Document internal APIs and data models.

**Acceptance Criteria**:
- Database schema documentation
- Event transformation logic documented
- Configuration parameters documented
- Environment variables documented
- Deployment procedures documented
- Architecture diagrams (Mermaid)
- Code comments and docstrings complete

**Dependencies**: All previous phases

**Effort**: Small

**Risk**: Low

#### 4.6 Production Deployment Checklist
**Description**: Create comprehensive pre-deployment checklist.

**Acceptance Criteria**:
- Infrastructure provisioned via Terraform
- Secrets configured and tested
- Database migrations applied
- Cloud Functions deployed
- Pub/Sub topics and subscriptions created
- Monitoring and alerting configured
- Load testing completed
- Security review completed
- Backup and recovery tested
- Terminal49 webhook registered
- Smoke tests passed
- Rollback plan documented

**Dependencies**: All previous phases

**Effort**: Small

**Risk**: High (production deployment)

### Testing Strategy
- End-to-end testing with Terminal49 sandbox (if available)
- Chaos engineering: simulate failures (database down, Pub/Sub unavailable)
- Security testing: invalid signatures, malformed payloads, injection attempts
- Performance testing under various load patterns
- Disaster recovery drill

### Success Metrics
- All alerts trigger correctly in test scenarios
- Performance benchmarks meet requirements
- Zero critical issues in production deployment
- Mean time to detection (MTTD) <5 minutes
- Mean time to resolution (MTTR) <30 minutes

---

## Risk Matrix

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Database technology choice doesn't scale | High | Medium | Conduct thorough load testing in Phase 1; hybrid approach (BigQuery + Supabase) provides flexibility |
| Terminal49 API changes breaking integration | High | Low | Archive raw payloads for reprocessing; version webhook handlers; monitor Terminal49 changelog |
| Signature validation bypass | Critical | Low | Implement constant-time comparison; security audit; IP whitelist as secondary validation |
| Event processing delays under load | High | Medium | Implement auto-scaling; Pub/Sub provides buffering; monitor queue depth |
| Data loss during failures | Critical | Low | BigQuery archival before processing; idempotent operations; transaction management |
| Cost overruns | Medium | Medium | Implement cost monitoring; set budget alerts; optimize BigQuery queries; cache secrets |
| Cold start latency | Medium | Medium | Use Cloud Functions 2nd gen (faster cold starts); minimum instances for critical functions |
| Duplicate event processing | Medium | Low | Idempotency via unique constraints; comprehensive testing |
| Secret exposure | Critical | Low | Encrypt at rest; rotate regularly; audit access logs; never log secrets |
| Database connection exhaustion | High | Medium | Connection pooling; monitor pool utilization; implement circuit breaker |

---

## Technical Decision Log

| Decision | Options | Recommendation | Rationale |
|----------|---------|----------------|-----------|
| Database for operational data | BigQuery, Supabase PostgreSQL, Cloud SQL PostgreSQL | **Supabase PostgreSQL** | Real-time queries, JSONB support, familiar SQL, cost-effective at scale, managed service |
| Database for raw event archival | BigQuery, Cloud Storage + BigQuery | **BigQuery** | Optimized for append-only, cost-effective for large volumes, SQL queryable, partitioning support |
| Secret management | Secret Manager, Environment variables, Cloud Storage encrypted | **Environment variables with caching** | Cost-effective, sufficient security for non-PCI data, simple implementation |
| Event distribution | Pub/Sub, Cloud Tasks | **Pub/Sub** | Better for fan-out patterns, built-in retry, dead letter queues, decouples components |
| Compute platform | Cloud Functions, Cloud Run, GKE | **Cloud Functions (2nd gen)** | Serverless, auto-scaling, pay-per-use, simpler operations, faster cold starts |
| Programming language | Python, Node.js, Go | **Python 3.11+** | Team expertise, rich ecosystem for data processing, type hints, GCP SDK support |
| Infrastructure as Code | Terraform, Pulumi, gcloud CLI | **Terraform** | Industry standard, declarative, state management, reusable modules |
| Logging strategy | Cloud Logging, ELK stack, Datadog | **Cloud Logging** | Native GCP integration, structured logging, cost-effective, query capabilities |
| Testing framework | pytest, unittest | **pytest** | Modern, fixtures, parametrization, better assertions, plugin ecosystem |
| Connection pooling | pgbouncer, SQLAlchemy pool, psycopg2 pool | **SQLAlchemy pool** | Python-native, configurable, works well with Cloud Functions |

---

## Project Timeline

```mermaid
gantt
    title Terminal49