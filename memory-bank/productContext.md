# Product Context

This file provides a high-level overview of the project and the expected product that will be created. Initially it is based upon projectBrief.md and all other available project-related information in the working directory. This file is intended to be updated as the project evolves, and should be used to inform all other modes of the project's goals and context.

## Project Goal

Build a production-ready webhook infrastructure on Google Cloud Platform (GCP) to receive, process, and store Terminal49 container and shipment tracking data. This system will serve as the foundational data layer for all track and trace functionality.

## Key Features

*   **Webhook Reception & Validation**: Accept POST requests from Terminal49, validate HMAC-SHA256 signatures, return 200 OK within 5 seconds
*   **Event Processing**: Parse JSON payloads, identify event types, extract key entities (container, shipment, vessel), handle nested objects and null values
*   **Data Storage**: Idempotent writes using Terminal49 event_id, upsert patterns for entities, append-only events table, raw payload archival to BigQuery
*   **Error Handling**: Retry transient failures, dead letter queue for persistent failures, alert on signature validation failures, comprehensive logging
*   **Monitoring & Observability**: Track webhook receipts, processing success/failure rates, database write latency, alerting on failures and performance issues

## Overall Architecture

```
Terminal49 → Cloud Function (Webhook Receiver) → Pub/Sub Topic → Processing Functions → BigQuery or Supabase
                                                    ↓
                                            BigQuery (Raw Events)
```

**Core Technologies:**
- Primary Platform: Google Cloud Platform (GCP)
- Language: Python 3.11+
- Database: BigQuery or Supabase for structured tracking data
- Compute: Cloud Functions (2nd gen) for webhook handling
- Messaging: Cloud Pub/Sub or Cloud Task for event distribution
- Storage: BigQuery for raw event archival
- Monitoring: Cloud Logging + Cloud Monitoring

**Core Entities to Track:**
1. Shipments - Bill of Lading, booking numbers, origin/destination ports, carrier info, ETAs
2. Containers - Container numbers, size, type, current location/status, Last Free Day (LFD)
3. Tracking Requests - Active subscriptions to Terminal49
4. Webhooks - Event subscriptions configuration, delivery status

**Key Webhook Events:**
- container.transport.* - Movement events
- container.tracking.* - Tracking lifecycle
- shipment.* - Shipment-level updates
- tracking_request.* - Tracking request status changes

**Data Characteristics:**
- Event Volume: 1000-5000 events/day initially
- Peak Traffic: Bursts during vessel discharge events
- Payload Size: 2-10 KB per webhook event
- Must handle duplicates (idempotent processing)
- Frequent null values in optional fields

**Performance Requirements:**
- Webhook response time: <3 seconds (p95)
- Event processing latency: <10 seconds (p99)
- Database write throughput: 100 inserts/second minimum
- Webhook availability: 99.9% uptime

**Security:**
- Webhook signature validation (all requests)
- API keys management (not Secret Manager due to cost)
- Least privilege IAM roles
- Audit logging enabled

---

2026-01-02 16:18:03 - Initial Memory Bank creation based on ProjectBrief.md
