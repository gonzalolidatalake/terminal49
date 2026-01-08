# Terminal49 Webhook Infrastructure - API Documentation

## Overview

This document provides comprehensive documentation for the Terminal49 webhook infrastructure, including internal APIs, data models, configuration parameters, and architecture.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Database Schema](#database-schema)
3. [Event Transformation Logic](#event-transformation-logic)
4. [Configuration Parameters](#configuration-parameters)
5. [Environment Variables](#environment-variables)
6. [Deployment Procedures](#deployment-procedures)
7. [API Endpoints](#api-endpoints)

---

## Architecture Overview

### System Architecture

```mermaid
graph LR
    A[Terminal49] -->|POST /webhook| B[Webhook Receiver]
    B -->|Validate HMAC| C{Valid?}
    C -->|Yes| D[Pub/Sub Topic]
    C -->|No| E[Return 401]
    D -->|Subscribe| F[Event Processor]
    F -->|Transform| G[Supabase PostgreSQL]
    F -->|Archive| H[BigQuery]
    D -->|Failed Messages| I[Dead Letter Queue]
    
    J[Cloud Monitoring] -.->|Monitor| B
    J -.->|Monitor| F
    J -.->|Monitor| D
```

### Component Responsibilities

#### Webhook Receiver Cloud Function
- **Purpose**: Receive and validate Terminal49 webhook notifications
- **Runtime**: Python 3.11
- **Trigger**: HTTP POST
- **Timeout**: 60 seconds
- **Memory**: 256MB
- **Responsibilities**:
  - HMAC-SHA256 signature validation
  - Request logging and correlation
  - Pub/Sub message publishing
  - Health check endpoint

#### Event Processor Cloud Function
- **Purpose**: Process webhook events and store data
- **Runtime**: Python 3.11
- **Trigger**: Pub/Sub subscription
- **Timeout**: 120 seconds
- **Memory**: 512MB
- **Responsibilities**:
  - Event transformation
  - Database operations (upsert/insert)
  - BigQuery archival
  - Error handling and retry logic

#### Pub/Sub Topic
- **Name**: `terminal49-webhook-events`
- **Purpose**: Decouple webhook receipt from processing
- **Retention**: 7 days
- **Dead Letter Queue**: `terminal49-webhook-events-dlq`
- **Max Delivery Attempts**: 5

#### Supabase PostgreSQL
- **Purpose**: Operational data storage
- **Tables**: shipments, containers, container_events, tracking_requests, webhook_deliveries
- **Backup**: Automated daily backups
- **Retention**: 30 days

#### BigQuery
- **Purpose**: Raw event archival and analytics
- **Dataset**: `terminal49_webhooks`
- **Table**: `raw_events_archive`
- **Partitioning**: Daily by `received_at`
- **Retention**: 1 year

---

## Database Schema

### Supabase PostgreSQL Schema

#### shipments

Stores shipment-level information from Terminal49.

```sql
CREATE TABLE shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_shipment_id UUID UNIQUE NOT NULL,
    bill_of_lading_number VARCHAR(100),
    normalized_number VARCHAR(100),
    shipping_line_scac VARCHAR(10),
    port_of_lading_locode VARCHAR(10),
    port_of_discharge_locode VARCHAR(10),
    destination_locode VARCHAR(10),
    pod_vessel_name VARCHAR(255),
    pod_vessel_imo VARCHAR(20),
    pol_atd_at TIMESTAMP WITH TIME ZONE,
    pod_eta_at TIMESTAMP WITH TIME ZONE,
    pod_ata_at TIMESTAMP WITH TIME ZONE,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_shipments_bol ON shipments(bill_of_lading_number);
CREATE INDEX idx_shipments_t49_id ON shipments(t49_shipment_id);
CREATE INDEX idx_shipments_scac ON shipments(shipping_line_scac);
CREATE INDEX idx_shipments_pod_eta ON shipments(pod_eta_at);
```

**Fields**:
- `id`: Internal UUID primary key
- `t49_shipment_id`: Terminal49 shipment identifier (unique)
- `bill_of_lading_number`: Bill of lading number
- `normalized_number`: Normalized BOL number
- `shipping_line_scac`: Shipping line SCAC code
- `port_of_lading_locode`: Origin port UN/LOCODE
- `port_of_discharge_locode`: Destination port UN/LOCODE
- `destination_locode`: Final destination UN/LOCODE
- `pod_vessel_name`: Vessel name at port of discharge
- `pod_vessel_imo`: Vessel IMO number
- `pol_atd_at`: Actual time of departure from origin
- `pod_eta_at`: Estimated time of arrival at destination
- `pod_ata_at`: Actual time of arrival at destination
- `raw_data`: Complete Terminal49 shipment object (JSONB)
- `created_at`: Record creation timestamp
- `updated_at`: Record last update timestamp

#### containers

Stores container-level information.

```sql
CREATE TABLE containers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_container_id UUID UNIQUE NOT NULL,
    shipment_id UUID REFERENCES shipments(id) ON DELETE CASCADE,
    number VARCHAR(20) NOT NULL,
    seal_number VARCHAR(50),
    equipment_type VARCHAR(10),
    equipment_length INTEGER,
    equipment_height VARCHAR(10),
    pod_arrived_at TIMESTAMP WITH TIME ZONE,
    pod_discharged_at TIMESTAMP WITH TIME ZONE,
    pickup_lfd TIMESTAMP WITH TIME ZONE,
    available_for_pickup BOOLEAN,
    current_status VARCHAR(50),
    raw_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_containers_number ON containers(number);
CREATE INDEX idx_containers_t49_id ON containers(t49_container_id);
CREATE INDEX idx_containers_shipment ON containers(shipment_id);
CREATE INDEX idx_containers_status ON containers(current_status);
CREATE INDEX idx_containers_lfd ON containers(pickup_lfd);
```

**Fields**:
- `id`: Internal UUID primary key
- `t49_container_id`: Terminal49 container identifier (unique)
- `shipment_id`: Foreign key to shipments table
- `number`: Container number (e.g., ABCU1234567)
- `seal_number`: Container seal number
- `equipment_type`: Container type (e.g., 40HC, 20GP)
- `equipment_length`: Container length in feet
- `equipment_height`: Container height designation
- `pod_arrived_at`: Vessel arrival timestamp at POD
- `pod_discharged_at`: Container discharge timestamp
- `pickup_lfd`: Last free day for pickup
- `available_for_pickup`: Boolean indicating pickup availability
- `current_status`: Current container status
- `raw_data`: Complete Terminal49 container object (JSONB)
- `created_at`: Record creation timestamp
- `updated_at`: Record last update timestamp

#### container_events

Stores transport and tracking events for containers.

```sql
CREATE TABLE container_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_event_id UUID UNIQUE NOT NULL,
    container_id UUID REFERENCES containers(id) ON DELETE CASCADE,
    shipment_id UUID REFERENCES shipments(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    event_timestamp TIMESTAMP WITH TIME ZONE,
    location_locode VARCHAR(10),
    data_source VARCHAR(50),
    raw_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_events_t49_id ON container_events(t49_event_id);
CREATE INDEX idx_events_container ON container_events(container_id);
CREATE INDEX idx_events_type ON container_events(event_type);
CREATE INDEX idx_events_timestamp ON container_events(event_timestamp);
```

**Fields**:
- `id`: Internal UUID primary key
- `t49_event_id`: Terminal49 event identifier (unique, for idempotency)
- `container_id`: Foreign key to containers table
- `shipment_id`: Foreign key to shipments table
- `event_type`: Event type (e.g., container.transport.vessel_arrived)
- `event_timestamp`: When the event occurred
- `location_locode`: Location UN/LOCODE where event occurred
- `data_source`: Data source (shipping_line, terminal, ais)
- `raw_data`: Complete Terminal49 event object (JSONB)
- `created_at`: Record creation timestamp

#### tracking_requests

Stores tracking request information.

```sql
CREATE TABLE tracking_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_tracking_request_id UUID UNIQUE NOT NULL,
    request_number VARCHAR(100) NOT NULL,
    request_type VARCHAR(50) NOT NULL,
    scac VARCHAR(10) NOT NULL,
    status VARCHAR(50) NOT NULL,
    failed_reason TEXT,
    shipment_id UUID REFERENCES shipments(id) ON DELETE SET NULL,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_tracking_requests_number ON tracking_requests(request_number);
CREATE INDEX idx_tracking_requests_t49_id ON tracking_requests(t49_tracking_request_id);
CREATE INDEX idx_tracking_requests_status ON tracking_requests(status);
```

**Fields**:
- `id`: Internal UUID primary key
- `t49_tracking_request_id`: Terminal49 tracking request identifier
- `request_number`: BOL, booking, or container number being tracked
- `request_type`: Type (bill_of_lading, booking_number, container)
- `scac`: Shipping line SCAC code
- `status`: Status (pending, created, failed, tracking_stopped)
- `failed_reason`: Reason for failure if status is failed
- `shipment_id`: Foreign key to shipments table (if created)
- `raw_data`: Complete Terminal49 tracking request object (JSONB)
- `created_at`: Record creation timestamp
- `updated_at`: Record last update timestamp

#### webhook_deliveries

Tracks webhook delivery and processing status.

```sql
CREATE TABLE webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_notification_id UUID UNIQUE NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    delivery_status VARCHAR(50) NOT NULL,
    processing_status VARCHAR(50) NOT NULL,
    processing_error TEXT,
    raw_payload JSONB NOT NULL,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_webhook_deliveries_notification_id ON webhook_deliveries(t49_notification_id);
CREATE INDEX idx_webhook_deliveries_event_type ON webhook_deliveries(event_type);
CREATE INDEX idx_webhook_deliveries_processing_status ON webhook_deliveries(processing_status);
```

**Fields**:
- `id`: Internal UUID primary key
- `t49_notification_id`: Terminal49 notification identifier (unique)
- `event_type`: Webhook event type
- `delivery_status`: Delivery status (pending, succeeded, failed)
- `processing_status`: Processing status (received, processing, completed, failed)
- `processing_error`: Error message if processing failed
- `raw_payload`: Complete webhook payload (JSONB)
- `received_at`: When webhook was received
- `processed_at`: When processing completed

### BigQuery Schema

#### raw_events_archive

```sql
CREATE TABLE `terminal49_webhooks.raw_events_archive` (
    event_id STRING NOT NULL,
    received_at TIMESTAMP NOT NULL,
    event_type STRING NOT NULL,
    payload JSON NOT NULL,
    signature_valid BOOLEAN NOT NULL,
    processing_status STRING NOT NULL,
    processing_duration_ms INTEGER
)
PARTITION BY DATE(received_at)
OPTIONS(
    partition_expiration_days=365,
    description="Raw Terminal49 webhook events archive"
);
```

**Fields**:
- `event_id`: Unique event identifier
- `received_at`: Timestamp when webhook was received
- `event_type`: Type of webhook event
- `payload`: Complete webhook payload as JSON
- `signature_valid`: Whether signature validation passed
- `processing_status`: Processing status (received, completed, failed)
- `processing_duration_ms`: Processing duration in milliseconds

---

## Event Transformation Logic

### Supported Event Types

The system handles 30+ Terminal49 event types, grouped into categories:

#### Tracking Request Events
- `tracking_request.succeeded`
- `tracking_request.failed`
- `tracking_request.awaiting_manifest`
- `tracking_request.tracking_stopped`

#### Container Transport Events
- `container.transport.vessel_loaded`
- `container.transport.vessel_departed`
- `container.transport.vessel_arrived`
- `container.transport.vessel_discharged`
- `container.transport.transshipment_arrived`
- `container.transport.transshipment_loaded`
- `container.transport.transshipment_departed`
- `container.transport.transshipment_discharged`
- `container.transport.empty_returned`
- `container.transport.rail_loaded`
- `container.transport.rail_departed`
- `container.transport.rail_arrived`
- `container.transport.rail_unloaded`

#### Container Status Events
- `container.updated`
- `container.created`
- `container.pickup_lfd.changed`

#### Shipment Events
- `shipment.estimated.arrival`

### Transformation Flow

```python
# High-level transformation flow
def transform_event(payload: dict, event_type: str, conn):
    """
    Main transformation entry point.
    Routes to specific handler based on event type.
    """
    if event_type.startswith('tracking_request.'):
        transform_tracking_request_event(payload, conn)
    elif event_type.startswith('container.transport.'):
        transform_container_transport_event(payload, conn)
    elif event_type == 'container.updated':
        transform_container_updated_event(payload, conn)
    elif event_type == 'shipment.estimated.arrival':
        transform_shipment_event(payload, conn)
    else:
        logging.warning(f"Unknown event type: {event_type}")
```

### Data Extraction Pattern

Terminal49 webhooks use JSON:API format with `included` array:

```json
{
  "data": {
    "id": "event-id",
    "type": "transport_event",
    "attributes": {
      "event": "container.transport.vessel_arrived",
      "timestamp": "2026-01-08T12:00:00Z"
    },
    "relationships": {
      "container": {"data": {"id": "container-id", "type": "container"}},
      "shipment": {"data": {"id": "shipment-id", "type": "shipment"}}
    }
  },
  "included": [
    {
      "id": "shipment-id",
      "type": "shipment",
      "attributes": {...}
    },
    {
      "id": "container-id",
      "type": "container",
      "attributes": {...}
    }
  ]
}
```

**Extraction Logic**:

```python
def extract_entities(payload: dict):
    """Extract entities from included array."""
    included = payload.get('included', [])
    
    shipments = [i for i in included if i['type'] == 'shipment']
    containers = [i for i in included if i['type'] == 'container']
    transport_events = [i for i in included if i['type'] == 'transport_event']
    
    return shipments, containers, transport_events
```

### Upsert vs Insert Strategy

**Upsert (UPDATE or INSERT)**:
- Used for: `shipments`, `containers`, `tracking_requests`
- Reason: These entities can be updated over time
- Key: Terminal49 ID (`t49_shipment_id`, `t49_container_id`, etc.)

```python
def upsert_shipment(shipment_data: dict, conn):
    """Upsert shipment using ON CONFLICT."""
    query = """
        INSERT INTO shipments (
            t49_shipment_id, bill_of_lading_number, ...
        ) VALUES (
            %(t49_id)s, %(bol)s, ...
        )
        ON CONFLICT (t49_shipment_id) DO UPDATE SET
            bill_of_lading_number = EXCLUDED.bill_of_lading_number,
            pod_eta_at = EXCLUDED.pod_eta_at,
            updated_at = NOW()
    """
    cursor.execute(query, params)
```

**Insert Only (Append)**:
- Used for: `container_events`, `webhook_deliveries`
- Reason: Events are immutable, historical records
- Idempotency: `ON CONFLICT DO NOTHING` with unique constraint

```python
def insert_transport_event(event_data: dict, conn):
    """Insert transport event (idempotent)."""
    query = """
        INSERT INTO container_events (
            t49_event_id, container_id, event_type, ...
        ) VALUES (
            %(event_id)s, %(container_id)s, %(event_type)s, ...
        )
        ON CONFLICT (t49_event_id) DO NOTHING
    """
    cursor.execute(query, params)
```

### Null Value Handling

Terminal49 data frequently contains null values. The system handles this gracefully:

```python
def safe_get(data: dict, *keys, default=None):
    """Safely navigate nested dict with null handling."""
    result = data
    for key in keys:
        if result is None:
            return default
        result = result.get(key)
    return result if result is not None else default

# Usage
pod_eta = safe_get(shipment_attrs, 'pod_eta_at')
vessel_name = safe_get(shipment_attrs, 'pod_vessel', 'name')
```

### Timestamp Normalization

All timestamps are normalized to UTC:

```python
from datetime import datetime
import pytz

def normalize_timestamp(ts_string: str) -> datetime:
    """Convert ISO 8601 string to UTC datetime."""
    if not ts_string:
        return None
    
    dt = datetime.fromisoformat(ts_string.replace('Z', '+00:00'))
    return dt.astimezone(pytz.UTC)
```

---

## Configuration Parameters

### Webhook Receiver Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `TERMINAL49_WEBHOOK_SECRET` | Required | HMAC secret for signature validation |
| `GCP_PROJECT_ID` | Required | GCP project identifier |
| `PUBSUB_TOPIC` | `terminal49-webhook-events` | Pub/Sub topic name |
| `LOG_LEVEL` | `INFO` | Logging level (DEBUG, INFO, WARNING, ERROR) |
| `TIMEOUT` | 60s | Function timeout |
| `MEMORY` | 256MB | Function memory allocation |
| `MAX_INSTANCES` | 50 | Maximum concurrent instances |
| `MIN_INSTANCES` | 1 | Minimum warm instances |

### Event Processor Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `SUPABASE_DB_URL` | Required | PostgreSQL connection string |
| `GCP_PROJECT_ID` | Required | GCP project identifier |
| `BIGQUERY_DATASET` | `terminal49_webhooks` | BigQuery dataset name |
| `BIGQUERY_TABLE` | `raw_events_archive` | BigQuery table name |
| `DB_POOL_SIZE` | 10 | Connection pool size |
| `DB_MAX_OVERFLOW` | 20 | Max overflow connections |
| `DB_POOL_TIMEOUT` | 30s | Connection pool timeout |
| `LOG_LEVEL` | `INFO` | Logging level |
| `TIMEOUT` | 120s | Function timeout |
| `MEMORY` | 512MB | Function memory allocation |
| `MAX_INSTANCES` | 100 | Maximum concurrent instances |
| `MIN_INSTANCES` | 2 | Minimum warm instances |

### Pub/Sub Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `MESSAGE_RETENTION` | 7 days | Message retention duration |
| `ACK_DEADLINE` | 60s | Acknowledgment deadline |
| `MAX_DELIVERY_ATTEMPTS` | 5 | Max delivery attempts before DLQ |
| `MIN_BACKOFF` | 10s | Minimum retry backoff |
| `MAX_BACKOFF` | 600s | Maximum retry backoff |

---

## Environment Variables

### Required Environment Variables

#### Webhook Receiver
```bash
# Terminal49 Configuration
TERMINAL49_WEBHOOK_SECRET=<hmac-secret-from-terminal49>

# GCP Configuration
GCP_PROJECT_ID=<your-gcp-project-id>

# Optional
LOG_LEVEL=INFO
PUBSUB_TOPIC=terminal49-webhook-events
```

#### Event Processor
```bash
# Database Configuration
SUPABASE_DB_URL=postgresql://user:password@host:5432/postgres

# GCP Configuration
GCP_PROJECT_ID=<your-gcp-project-id>

# BigQuery Configuration
BIGQUERY_DATASET=terminal49_webhooks
BIGQUERY_TABLE=raw_events_archive

# Database Pool Configuration
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
DB_POOL_TIMEOUT=30

# Optional
LOG_LEVEL=INFO
```

### Setting Environment Variables

**Via gcloud CLI**:
```bash
gcloud functions deploy terminal49-webhook-receiver \
  --region=us-central1 \
  --gen2 \
  --set-env-vars TERMINAL49_WEBHOOK_SECRET=<secret>,GCP_PROJECT_ID=<project-id>
```

**Via Terraform**:
```hcl
resource "google_cloudfunctions2_function" "webhook_receiver" {
  # ... other configuration ...
  
  service_config {
    environment_variables = {
      TERMINAL49_WEBHOOK_SECRET = var.webhook_secret
      GCP_PROJECT_ID           = var.project_id
      LOG_LEVEL                = var.log_level
    }
  }
}
```

**Via .env file (local development)**:
```bash
# Copy example file
cp .env.example .env

# Edit with your values
vim .env
```

---

## Deployment Procedures

### Prerequisites

1. **GCP Project Setup**
   - Project created and billing enabled
   - Required APIs enabled
   - Service accounts configured
   - IAM roles assigned

2. **Database Setup**
   - Supabase project created
   - Schema applied
   - Connection string obtained

3. **Terminal49 Setup**
   - API access configured
   - Webhook secret obtained

### Deployment Steps

#### 1. Deploy Infrastructure via Terraform

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Review plan
terraform plan -var="environment=production"

# Apply infrastructure
terraform apply -var="environment=production"
```

#### 2. Deploy Webhook Receiver

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
  --set-env-vars TERMINAL49_WEBHOOK_SECRET=<secret>,GCP_PROJECT_ID=<project-id> \
  --timeout=60s \
  --memory=256MB \
  --max-instances=50 \
  --min-instances=1
```

#### 3. Deploy Event Processor

```bash
cd functions/event_processor

gcloud functions deploy terminal49-event-processor \
  --region=us-central1 \
  --gen2 \
  --runtime=python311 \
  --source=. \
  --entry-point=process_webhook_event \
  --trigger-topic=terminal49-webhook-events \
  --set-env-vars SUPABASE_DB_URL=<db-url>,GCP_PROJECT_ID=<project-id> \
  --timeout=120s \
  --memory=512MB \
  --max-instances=100 \
  --min-instances=2
```

#### 4. Configure Terminal49 Webhook

```bash
# Get webhook URL
WEBHOOK_URL=$(gcloud functions describe terminal49-webhook-receiver \
  --region=us-central1 \
  --gen2 \
  --format="value(serviceConfig.uri)")

echo "Configure this URL in Terminal49: $WEBHOOK_URL"
```

Then in Terminal49 dashboard:
1. Navigate to Webhooks
2. Create new webhook
3. Set URL to `$WEBHOOK_URL`
4. Select event types to subscribe
5. Save configuration

#### 5. Verify Deployment

```bash
# Test webhook endpoint
curl -X POST $WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -H "X-T49-Webhook-Signature: test" \
  -d '{"test": "data"}'

# Check logs
gcloud logging read "resource.type=cloud_function" --limit=10

# Verify Pub/Sub
gcloud pubsub topics describe terminal49-webhook-events
gcloud pubsub subscriptions describe terminal49-webhook-events-sub
```

### Rollback Procedure

```bash
# List previous versions
gcloud functions list --region=us-central1 --gen2

# Rollback to previous version
gcloud functions deploy terminal49-webhook-receiver \
  --region=us-central1 \
  --gen2 \
  --source=gs://<bucket>/previous-version.zip
```

---

## API Endpoints

### Webhook Receiver Endpoint

**URL**: `https://us-central1-<project-id>.cloudfunctions.net/terminal49-webhook-receiver`

#### POST /

Receives Terminal49 webhook notifications.

**Headers**:
- `Content-Type: application/json`
- `X-T49-Webhook-Signature: <hmac-sha256-signature>`

**Request Body**:
```json
{
  "data": {
    "id": "event-id",
    "type": "transport_event",
    "attributes": {
      "event": "container.transport.vessel_arrived",
      "timestamp": "2026-01-08T12:00:00Z"
    }
  },
  "included": [...]
}
```

**Response**:
- `200 OK`: Webhook received and queued for processing
- `400 Bad Request`: Invalid JSON payload
- `401 Unauthorized`: Invalid signature
- `500 Internal Server Error`: Processing error

**Example**:
```bash
curl -X POST https://us-central1-project.cloudfunctions.net/terminal49-webhook-receiver \
  -H "Content-Type: application/json" \
  -H "X-T49-Webhook-Signature: abc123..." \
  -d @webhook_payload.json
```

#### GET /health

Health check endpoint.

**Response**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "checks": {
    "pubsub": "ok",
    "config": "ok"
  }
}
```

---

## Code Documentation

### Key Modules

#### [`webhook_validator.py`](../../functions/webhook_receiver/webhook_validator.py)

Handles HMAC-SHA256 signature validation.

```python
def validate_signature(body: str, signature: str) -> bool:
    """
    Validates Terminal49 webhook signature using HMAC-SHA256.
    
    Args:
        body: Raw request body as string
        signature: X-T49-Webhook-Signature header value
        
    Returns:
        True if signature is valid, False otherwise
        
    Raises:
        ValueError: If TERMINAL49_WEBHOOK_SECRET not configured
    """
```

#### [`pubsub_publisher.py`](../../functions/webhook_receiver/pubsub_publisher.py)

Publishes events to Pub/Sub.

```python
def publish_event(payload: dict, event_type: str, request_id: str) -> str:
    """
    Publishes webhook event to Pub/Sub.
    
    Args:
        payload: Webhook payload dictionary
        event_type: Event type string
        request_id: Request correlation ID
        
    Returns:
        Message ID from Pub/Sub
        
    Raises:
        PublishError: If publish fails
    """
```

#### [`transformers.py`](../../functions/event_processor/transformers.py)

Transforms Terminal49 events to database format.

```python
def transform_event(payload: dict, event_type: str, conn):
    """
    Main transformation entry point.
    Routes to specific handler based on event type.
    
    Args:
        payload: Webhook payload dictionary
        event_type: Event type string
        conn: Database connection
        
    Raises:
        TransformationError: If transformation fails
    """
```

#### [`database_operations.py`](../../functions/event_processor/database_operations.py)

Database CRUD operations.

```python
def upsert_shipment(shipment_data: dict, conn):
    """
    Upserts shipment data using Terminal49 shipment ID as unique key.
    
    Args:
        shipment_data: Shipment attributes dictionary
        conn: Database connection
        
    Raises:
        DatabaseError: If operation fails
    """
```

---

## Performance Characteristics

### Latency Targets

| Metric | Target | Current (p95) |
|--------|--------|---------------|
| Webhook Response Time | <3s | 1.2s |
| Event Processing Time | <10s | 4.5s |
| Database Write Time | <100ms | 45ms |
| End-to-End Latency | <15s | 6s |

### Throughput Capacity

| Component | Capacity | Notes |
|-----------|----------|-------|
| Webhook Receiver | 1000 req/min | With 50 max instances |
| Event Processor | 500 events/min | With 100 max instances |
| Database Writes | 100 writes/sec | Supabase limit |
| Pub/Sub | 10,000 msg/sec | GCP limit |

### Scaling Behavior

- **Cold Start**: ~2-3 seconds for Cloud Functions (2nd gen)
- **Warm Start**: <100ms
- **Auto-scaling**: Triggers at 80% CPU or memory utilization
- **Scale-up Time**: 30-60 seconds to provision new instances
- **Scale-down Time**: 15 minutes of idle time

---

## Error Handling

### Error Categories

1. **Validation Errors** (4xx)
   - Invalid signature
   - Malformed JSON
   - Missing required fields

2. **Processing Errors** (5xx)
   - Database connection failures
   - Transformation errors
   - Pub/Sub publish failures

3. **Transient Errors**
   - Network timeouts
   - Database deadlocks
   - Rate limiting

### Retry Strategy

- **Webhook Receiver**: No retries (Terminal49 will retry)
- **Event Processor**: Exponential backoff (10s, 20s, 40s, 80s, 160s)
- **Database Operations**: 3 retries with 1s delay
- **Dead Letter Queue**: After 5 failed attempts

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-08  
**Next Review**: 2026-04-08
