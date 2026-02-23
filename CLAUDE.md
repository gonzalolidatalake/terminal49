# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terminal49 webhook infrastructure on Google Cloud Platform. Receives container/shipment tracking webhooks from Terminal49, validates them, and routes events through Pub/Sub into BigQuery (long-term storage) and Supabase PostgreSQL (operational storage).

- **GCP Project:** `li-customer-datalake` (us-central1)
- **Supabase Project:** `srordjhkcvyfyvepzrzp`
- **BigQuery Dataset:** `terminal49_raw_events`
- **Python Version:** 3.11+ (see `.python-version`)

## Development Setup

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
gcloud auth application-default login
cp .env.example .env  # then fill in credentials
pre-commit install
```

## Common Commands

```bash
# Run all tests with coverage
pytest

# Run by category (unit | integration | slow | requires_gcp | requires_supabase)
pytest -m unit
pytest -m integration

# Run a single test file
pytest tests/unit/test_webhook_validator.py -v

# Local function testing
functions-framework --target=webhook_receiver --port=8080
functions-framework --target=process_webhook_event --port=8081 --signature-type=event

# Code quality (all run via pre-commit, but can be run individually)
black --line-length 100 .
isort .
flake8 .
mypy functions/
bandit -r functions/

# Terraform
cd infrastructure/terraform
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

## Architecture

```
Terminal49 Webhooks (HTTP POST)
    ↓
webhook_receiver (Cloud Function, HTTP trigger)
  - HMAC-SHA256 signature validation (constant-time)
  - Publishes to Pub/Sub
    ↓
Pub/Sub: terminal49-webhook-events
    ↓
event_processor (Cloud Function, Pub/Sub trigger)
  - Streams raw payload → BigQuery raw_events_archive (2-year retention)
  - Transforms and upserts → Supabase PostgreSQL (90-day retention)
    ↓
supabase_archiver (Cloud Function, Cloud Scheduler daily 2AM UTC)
  - Archives Supabase events >90 days old → BigQuery events_historical
```

### Key Source Files

| File | Purpose |
|------|---------|
| [functions/webhook_receiver/main.py](functions/webhook_receiver/main.py) | HTTP entry point, health check |
| [functions/webhook_receiver/webhook_validator.py](functions/webhook_receiver/webhook_validator.py) | HMAC-SHA256 validation |
| [functions/webhook_receiver/pubsub_publisher.py](functions/webhook_receiver/pubsub_publisher.py) | Pub/Sub publishing with retry |
| [functions/event_processor/main.py](functions/event_processor/main.py) | Pub/Sub entry point |
| [functions/event_processor/transformers.py](functions/event_processor/transformers.py) | Event routing/handler dispatch |
| [functions/event_processor/database.py](functions/event_processor/database.py) | PostgreSQL connection pool (1–5 connections) |
| [functions/event_processor/database_operations.py](functions/event_processor/database_operations.py) | CRUD for shipments, containers, events |
| [functions/event_processor/bigquery_archiver.py](functions/event_processor/bigquery_archiver.py) | BigQuery streaming inserts |
| [functions/supabase_archiver/main.py](functions/supabase_archiver/main.py) | Scheduled archival function |

### Supabase Schema (Operational, 90-day retention)

- `shipments`, `containers` — current state (upserted on events)
- `container_events` — recent event log
- `tracking_requests` — active Terminal49 subscriptions
- `webhook_deliveries` — idempotency tracking (keyed on `notification_id`)

### BigQuery Schema (Long-term, 2-year retention)

- `raw_events_archive` — all raw webhook payloads, daily-partitioned, streaming inserts
- `events_historical` — archived Supabase events after 90 days
- `processing_metrics` — aggregated operational metrics

## Idempotency

`webhook_deliveries` table in Supabase tracks `notification_id` to deduplicate redeliveries. Event processor checks this before writing to either storage system.

## Infrastructure

Terraform modules in [infrastructure/terraform/modules/](infrastructure/terraform/modules/):
- `service_accounts/` — least-privilege IAM per function
- `pubsub/` — topics, subscriptions, DLQ
- `bigquery/` — dataset and partitioned tables
- `cloud_function/` — reusable 2nd-gen function module
- `monitoring/` — dashboards, 6 alert policies

State backend: GCS bucket `li-customer-datalake-terraform-state`.

## Test Markers

Use pytest markers to target specific test subsets:
- `unit` — no external dependencies
- `integration` — requires running services
- `requires_gcp` — needs GCP credentials
- `requires_supabase` — needs Supabase access
- `slow` — long-running tests
