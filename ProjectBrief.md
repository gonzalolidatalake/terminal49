# Terminal49 Track & Trace Infrastructure - Project Brief

## Project Overview
Building a production-ready webhook infrastructure on Google Cloud Platform (GCP) to receive, process, and store Terminal49 (T49) container and shipment tracking data. This system will serve as the foundational data layer for all track and trace functionality.

## Business Context
Terminal49 provides real-time container tracking via webhooks. We need a scalable, reliable infrastructure to:
- Receive webhook events from Terminal49 (container movements, status changes, vessel updates)
- Validate and process these events
- Store comprehensive tracking data for business intelligence and customer-facing applications
- Enable downstream systems to react to shipment/container events

## Technical Architecture

### Core Technologies
- **Primary Platform**: Google Cloud Platform (GCP)
- **Language**: Python 3.11+ (preferred for data processing and GCP integration)
- **Database**: BigQuery or Supabase for structured tracking data
- **Compute**: Cloud Functions (2nd gen) for webhook handling
- **Messaging**: Cloud Pub/Sub or Cloud Task for event distribution
- **Storage**: BogQuery for raw event archival
- **Secrets**: Secret Manager for API keys and credentials is too expensive, other options might be better, T49 information is not that sensitive.
- **Monitoring**: Cloud Logging + Cloud Monitoring

### Architecture Pattern
```
Terminal49 → Cloud Function (Webhook Receiver) → Pub/Sub Topic → Processing Functions → BigQuery or Supabase
                                                    ↓
                                            BigQuery (Raw Events)
```

## Terminal49 Integration Details

### API Configuration
- **Base URL**: `https://api.terminal49.com/v2`
- **Authentication**: Bearer token in Authorization header
- **Environment**: Production
- **Documentation Location**: `./docs/` (comprehensive API reference)

### Core Entities to Track
1. **Shipments** (`/v2/shipments`)
   - Bill of Lading, booking numbers
   - Origin/destination ports
   - Carrier information
   - ETAs and actual arrival times

2. **Containers** (`/v2/containers`)
   - Container numbers, size, type
   - Current location and status
   - Last Free Day (LFD) for demurrage
   - Associated shipment relationships

3. **Tracking Requests** (`/v2/tracking_requests`)
   - Active subscriptions to Terminal49
   - Container/shipment tracking status

4. **Webhooks** (`/v2/webhooks`)
   - Event subscriptions configuration
   - Delivery status and failures

### Key Webhook Events
- `container.transport.*` - Movement events (vessel loaded/discharged, gate in/out, rail/truck movements)
- `container.tracking.*` - Tracking lifecycle (created, updated, completed, failed)
- `shipment.*` - Shipment-level updates
- `tracking_request.*` - Tracking request status changes

### Data Characteristics
- **Event Volume**: Estimated 1000-5000 events/day initially
- **Peak Traffic**: Webhooks may arrive in bursts (vessel discharge events)
- **Payload Size**: 2-10 KB per webhook event
- **Duplicate Events**: Terminal49 may send duplicates - must be idempotent
- **Null Values**: Terminal49 frequently returns null for optional fields

## Functional Requirements

### 1. Webhook Reception & Validation
- Accept POST requests from Terminal49 webhook endpoints
- Validate HMAC-SHA256 signature (header: `x-terminal49-signature`)
- Return 200 OK within 5 seconds (Terminal49 requirement)
- Handle signature validation failures (401 response)
- Rate limiting: 100 req/min per Terminal49 webhook configuration

### 2. Event Processing
- Parse webhook payload (JSON)
- Identify event type and route accordingly
- Extract key entities (container, shipment, vessel)
- Handle nested/complex objects (location, transport details)
- Manage null values gracefully

### 3. Data Storage
- Idempotent writes using Terminal49 event_id
- Upsert patterns for entities (containers, shipments)
- Append-only for events table
- Store raw payloads for debugging
- Archive raw events to BigQuery

### 4. Error Handling
- Retry transient failures (network, database deadlocks)
- Dead letter queue for persistent failures
- Alert on signature validation failures
- Log all processing errors with context
- Graceful degradation (partial event processing)

### 5. Monitoring & Observability
- Log all webhook receipts with processing time
- Track event processing success/failure rates
- Monitor database write latency
- Alert on:
  - Webhook delivery failures (>5% failure rate)
  - Processing time >10 seconds
  - Database connection issues
  - Signature validation failures (potential security issue)

## Non-Functional Requirements

### Performance
- Webhook response time: <3 seconds (p95)
- Event processing latency: <10 seconds (p99)
- Database write throughput: 100 inserts/second minimum

### Reliability
- Webhook availability: 99.9% uptime
- Idempotency: Safe to replay events
- Data consistency: No lost events under normal conditions

### Scalability
- Handle 10x traffic spikes without degradation
- Cloud Functions auto-scaling
- Database connection pooling

### Security
- Webhook signature validation (all requests)
- API keys in Secret Manager (not environment variables)
- Least privilege IAM roles
- VPC networking for Cloud SQL
- Audit logging enabled

## Development Guidelines

### Code Quality Standards
- **Python Style**: PEP 8 compliance, type hints required
- **Documentation**: Docstrings for all functions (Google style)
- **Testing**: Unit tests for business logic, integration tests for Cloud Functions
- **Error Handling**: Explicit exception handling, structured logging
- **Configuration**: Environment-based (dev/staging/prod)

### Environment Variables
- `TERMINAL49_WEBHOOK_SECRET` - Webhook signature validation secret
- `TERMINAL49_API_KEY` - API key for Terminal49 API calls
- `DATABASE_URL` - Cloud SQL connection string
- `PROJECT_ID` - GCP project ID
- `PUBSUB_TOPIC` - Event distribution topic name

## Success Criteria

### Phase 1: Core Infrastructure (MVP)
✅ Cloud Function receives Terminal49 webhooks
✅ Signature validation working correctly
✅ Events stored in Cloud SQL (idempotent)
✅ Raw events archived to Cloud Storage
✅ Basic monitoring/alerting configured

### Phase 2: Data Completeness
✅ All Terminal49 event types handled
✅ Full entity relationships (shipments ↔ containers ↔ events)
✅ Location data properly structured
✅ Vessel tracking integrated

### Phase 3: Production Readiness
✅ Comprehensive error handling
✅ Performance benchmarks met (p95 <3s)
✅ Integration tests passing
✅ Terraform infrastructure as code
✅ Runbooks for operations

## Known Challenges & Considerations

### Terminal49 API Quirks
- **Inconsistent null handling**: Some fields null when expected populated
- **Duplicate events**: Must use event_id for deduplication
- **Nested structures**: Complex JSON objects require careful parsing
- **Timestamp formats**: Mix of ISO8601 strings and Unix timestamps
- **Rate limiting**: 100 req/min (must implement backoff)

### GCP-Specific Considerations
- Cloud Function cold starts (~2s) - use 2nd gen functions
- Cloud SQL connection limits - implement connection pooling
- Pub/Sub message ordering not guaranteed - use timestamps
- Secret Manager API quotas - cache secrets in function memory

### Data Quality Issues
- Terminal49 location data quality varies by carrier
- Some carriers don't provide seal numbers
- ETA estimates can change dramatically
- Equipment size/type may be null initially

## Next Steps

1. **Database Design**:
   - Finalize schema (review with team)
   - Create migration scripts
   - Set up Cloud SQL instance

2. **Implement Webhook Receiver**:
   - Cloud Function for webhook ingestion
   - Signature validation
   - Pub/Sub publishing

3. **Implement Event Processor**:
   - Cloud Function subscribing to Pub/Sub
   - Data transformation logic
   - Database writes

4. **Testing & Validation**:
   - Unit tests for business logic
   - Integration tests with Terminal49 sandbox
   - Load testing for scale validation

5. **Deployment**:
   - Deploy Cloud Functions
   - Configure Terminal49 webhooks
   - Monitor initial production traffic

## Reference Materials

- **Terminal49 API Docs**: `./docs/` (comprehensive endpoint documentation)
- **GCP Cloud Functions**: https://cloud.google.com/functions/docs
- **Cloud SQL Best Practices**: https://cloud.google.com/sql/docs/postgres/best-practices
- **Pub/Sub Patterns**: https://cloud.google.com/pubsub/docs/overview

## Project Timeline (Estimated)

- **Week 1**: GCP setup + database schema finalized
- **Week 2**: Webhook receiver + signature validation implemented
- **Week 3**: Event processor + data transformation logic
- **Week 4**: Testing, monitoring, documentation
- **Week 5**: Production deployment + validation

## Contact & Escalation

- **Project Owner**: Gon (Industrial Engineer, technical lead)
- **Expertise**: Python, SQL, JavaScript, GCP, Terminal49 API
- **Decision Authority**: Architecture, technology selection, schema design