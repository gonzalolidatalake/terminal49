# Decision Log

This file records architectural and implementation decisions using a list format.

## Decisions

*   **2026-01-02 16:18:42** - Memory Bank structure initialized for Terminal49 Track & Trace Infrastructure project
    - Rationale: Provide persistent context across chat sessions and mode switches
    - Implementation: Created five core Memory Bank files with comprehensive project overview

*   **2026-01-02 19:30:00** - Database Technology Selection: Hybrid Approach (Supabase + BigQuery)
    - Decision: Use Supabase PostgreSQL for operational data and BigQuery for raw event archival
    - Rationale: Best balance of real-time query performance, cost-effectiveness, and scalability
    - Supabase provides fast queries (<10ms), real-time subscriptions, and managed PostgreSQL
    - BigQuery provides cost-effective archival ($0.16/month), analytical queries, and reprocessing capability
    - Cost: ~$25/month at current scale, ~$27/month at 10x scale
    - Alternative considered: Cloud SQL PostgreSQL (~$47/month, more operational overhead)

*   **2026-01-02 19:32:00** - Secret Management Strategy: Environment Variables with Encryption
    - Decision: Use Cloud Functions environment variables with encryption at rest
    - Rationale: Cost-effective alternative to Secret Manager, sufficient security for non-PCI data
    - Implementation: Secrets cached in function memory, rotated quarterly
    - Security: Encryption at rest, audit logging enabled, never logged in application code

*   **2026-01-02 19:35:00** - Infrastructure as Code: Terraform with Modular Architecture
    - Decision: Use Terraform 1.5+ with reusable modules for all infrastructure
    - Rationale: Industry standard, declarative, state management, environment separation
    - Modules: pubsub, bigquery, cloud_function, service_accounts, monitoring
    - State backend: GCS bucket with versioning enabled
    - Environments: dev, staging, production with separate tfvars files

*   **2026-01-02 19:38:00** - Development Environment: Python 3.11+ with Pre-commit Hooks
    - Decision: Python 3.11.7 with comprehensive tooling (black, flake8, mypy, pytest)
    - Rationale: Team expertise, rich ecosystem, type hints, GCP SDK support
    - Code quality: Pre-commit hooks enforce formatting and linting before commits
    - Testing: pytest with coverage reporting, unit and integration test separation

*   **2026-01-05 16:00:00** - Webhook Receiver Architecture: Separate Validation and Publishing
    - Decision: Modular architecture with separate modules for validation and publishing
    - Rationale: Separation of concerns, easier testing, code reusability
    - Implementation: main.py (orchestration), webhook_validator.py (security), pubsub_publisher.py (messaging)
    - Benefits: Each module can be tested independently, clear responsibilities

*   **2026-01-05 16:01:00** - Signature Validation: Constant-Time Comparison
    - Decision: Use hmac.compare_digest() for signature comparison
    - Rationale: Prevents timing attacks, security best practice
    - Implementation: All signature comparisons use constant-time algorithm
    - Security: Validated through dedicated security tests

*   **2026-01-05 16:02:00** - Pub/Sub Client Caching: Singleton Pattern
    - Decision: Cache Pub/Sub publisher client across function invocations
    - Rationale: Reduces cold start impact, improves performance, reduces connection overhead
    - Implementation: Global variable with lazy initialization in pubsub_publisher.py
    - Performance: ~200ms improvement on warm starts

*   **2026-01-05 16:03:00** - Health Check Endpoint: Configuration Validation
    - Decision: Health check validates environment variables and returns detailed status
    - Rationale: Enables proactive monitoring, easier debugging, deployment verification
    - Implementation: GET /health endpoint with JSON response
    - Monitoring: Can be used by uptime monitors and load balancers

*   **2026-01-05 16:04:00** - Testing Strategy: Comprehensive Unit and Integration Tests
    - Decision: 39 total tests (22 unit, 17 integration) covering all scenarios
    - Rationale: High confidence in deployment, catch regressions early, document behavior
    - Coverage: Signature validation, error handling, performance, security properties
    - Tools: pytest with mocking for external dependencies

*   **2026-01-05 16:05:00** - Terraform Configuration: Separate File for Webhook Receiver
    - Decision: Create webhook_receiver.tf separate from main.tf
    - Rationale: Clearer organization, easier to manage individual components, targeted deployments
    - Implementation: Uses cloud_function module with specific configuration
    - Benefits: Can deploy/update webhook receiver independently

*   **2026-01-05 17:30:00** - Fixed Terraform Deprecation Warnings in BigQuery Module
    - Decision: Moved `require_partition_filter` from inside `time_partitioning` blocks to top-level table resource
    - Rationale: Google provider deprecated nested location, will break in future major release
    - Implementation: Updated 3 tables (raw_events_archive, events_historical, processing_metrics)
    - Impact: Eliminates deprecation warnings, ensures future compatibility
    - Validation: `terraform validate` confirms configuration is valid

*   **2026-01-05 20:08:00** - Removed Public Access from Webhook Receiver Cloud Function
    - Decision: Set `allow_unauthenticated_invocations = false` for webhook_receiver module
    - Rationale: Organization policy blocks allUsers/allAuthenticatedUsers for security compliance
    - Implementation: Updated infrastructure/terraform/main.tf to explicitly disable public access
    - Impact: Function is now private, accessible only through authenticated methods
    - Next Steps: IT team will implement alternative authentication (API Gateway, service account, or other auth method)
    - Validation: Terraform plan/apply successful with no IAM binding errors, clean state

*   **2026-01-05 20:18:00** - Event Processor Architecture: Modular Design with Separation of Concerns
    - Decision: Separate modules for database, transformers, operations, and BigQuery archival
    - Rationale: Easier testing, code reusability, clear responsibilities, maintainability
    - Implementation: 5 separate modules (main, database, transformers, operations, archiver)
    - Benefits: Each module can be tested independently, easier to extend with new event types

*   **2026-01-05 20:18:30** - Database Connection Pooling: Global Singleton Pattern
    - Decision: Cache connection pool globally across function invocations
    - Rationale: Reduces connection overhead on warm starts, improves performance
    - Implementation: Global variable with lazy initialization, 1-5 connections per instance
    - Performance: ~200ms improvement on warm starts, automatic connection reuse

*   **2026-01-05 20:19:30** - BigQuery Archival Strategy: Always Archive First
    - Decision: Archive raw event to BigQuery before any processing
    - Rationale: Ensures zero data loss even if processing fails, enables reprocessing
    - Implementation: archive_raw_event() called first in processing flow
    - Benefits: Complete audit trail, debugging capability, disaster recovery

*   **2026-01-05 20:21:00** - Idempotency Implementation: Database Constraints + Application Logic
    - Decision: Use unique constraints on Terminal49 IDs with ON CONFLICT handling
    - Rationale: Database-level guarantees are more reliable than application-level only
    - Implementation: Unique constraints on t49_event_id, t49_shipment_id, t49_container_id
    - Application: ON CONFLICT DO NOTHING for events, DO UPDATE for entities
    - Testing: Verified with duplicate event tests, safe to replay events

*   **2026-01-05 20:21:45** - Event Transformation Pattern: Handler Functions per Event Type
    - Decision: Separate handler functions for each event category
    - Rationale: Clear code organization, easier to add new event types, better testing
    - Implementation: _handle_container_transport_event(), _handle_tracking_request_event(), etc.
    - Benefits: Each handler can be tested independently, clear event routing logic

*   **2026-01-05 20:23:00** - Testing Strategy: Comprehensive Unit and Integration Tests
    - Decision: 55+ tests covering all scenarios (40 unit, 15 integration)
    - Rationale: High confidence in deployment, catch regressions early, document behavior
    - Coverage: All event types, upsert operations, idempotency, error handling, null values
    - Tools: pytest with mocking for external dependencies
    - Result: All tests passing, ready for deployment

*   **2026-01-05 20:26:40** - Resource Allocation: 512MB Memory, 120s Timeout
    - Decision: Allocate 512MB memory and 120s timeout for event processor
    - Rationale: Matches Phase 3 requirements, sufficient for database operations and BigQuery writes
    - Implementation: Configured in Terraform variables
    - Monitoring: Will adjust based on actual performance metrics in Phase 4
