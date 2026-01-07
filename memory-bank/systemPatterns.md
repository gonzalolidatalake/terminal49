# System Patterns

This file documents recurring patterns and standards used in the project.
It is optional, but recommended to be updated as the project evolves.

## Coding Patterns

*   **Language**: Python 3.11+ with type hints required
*   **Style Guide**: PEP 8 compliance
*   **Documentation**: Google-style docstrings for all functions
*   **Error Handling**: Explicit exception handling with structured logging
*   **Configuration**: Environment-based configuration (dev/staging/prod)

## Architectural Patterns

*   **Event-Driven Architecture**: Webhook → Cloud Function → Pub/Sub → Processing Functions → Database
*   **Idempotency**: All event processing must be idempotent using Terminal49 event_id for deduplication
*   **Separation of Concerns**: Webhook receiver (fast response) separate from event processor (data transformation)
*   **Async Processing**: Use Pub/Sub for decoupling webhook reception from event processing
*   **Raw Data Archival**: Store raw webhook payloads in BigQuery for debugging and reprocessing
*   **Upsert Pattern**: Use upsert operations for entity tables (shipments, containers) to handle updates
*   **Append-Only Events**: Events table uses append-only pattern for audit trail

## Cloud Functions Gen 2 Patterns

*   **Eventarc Integration**: Cloud Functions Gen 2 with Pub/Sub triggers use Eventarc under the hood
*   **Cloud Run Foundation**: Gen 2 functions run on Cloud Run, requiring Cloud Run IAM permissions
*   **IAM for Pub/Sub Triggers**: Eventarc service account needs `roles/run.invoker` on the Cloud Run service
*   **Automatic Subscriptions**: Eventarc creates push subscriptions automatically; don't create manual pull subscriptions
*   **Service Account Pattern**: Use `service-{PROJECT_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com` for Pub/Sub triggers

## Testing Patterns

*   **Unit Tests**: Required for all business logic
*   **Integration Tests**: Required for Cloud Functions
*   **Test Coverage**: Comprehensive testing strategy to be defined
*   **Load Testing**: Required for scale validation before production deployment

---

2026-01-02 16:18:51 - Initial system patterns documented from ProjectBrief.md
