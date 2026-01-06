# Database Technology Selection

## Phase 1.2: Database Technology Decision

### Executive Summary

**Decision**: Hybrid approach using **Supabase PostgreSQL** for operational data and **BigQuery** for raw event archival.

**Rationale**: This combination provides the best balance of real-time query performance, cost-effectiveness, and scalability for the Terminal49 webhook infrastructure.

---

## Requirements Analysis

### Functional Requirements
1. Store shipments, containers, tracking requests, and events
2. Support real-time queries for operational dashboards
3. Handle 1000-5000 events/day initially, scalable to 10x
4. JSONB support for flexible/nested data (locations, raw payloads)
5. Idempotent writes using unique constraints
6. Foreign key relationships between entities
7. Full-text search capabilities (future requirement)

### Non-Functional Requirements
1. Query latency: <100ms for single record lookups
2. Write throughput: 100+ inserts/second
3. Cost-effective at scale
4. Managed service (minimal operational overhead)
5. Backup and disaster recovery
6. Integration with Cloud Functions

---

## Options Evaluated

### Option 1: BigQuery Only

**Pros**:
- Excellent for analytical queries and large-scale data
- Cost-effective for append-only data (streaming inserts: $0.05/GB)
- Native GCP integration
- Automatic scaling
- SQL queryable with standard syntax
- Partitioning and clustering for performance

**Cons**:
- Not optimized for transactional workloads
- Higher latency for single-row lookups (100-500ms)
- No foreign key constraints
- Limited support for UPDATE operations
- Streaming inserts have 1-2 second latency
- Not ideal for real-time operational queries

**Cost Estimate** (5000 events/day):
- Storage: ~5 GB/month × $0.02/GB = $0.10/month
- Streaming inserts: ~150 MB/month × $0.05/GB = $0.01/month
- Queries: ~10 GB/month × $5/TB = $0.05/month
- **Total: ~$0.16/month** (negligible)

**Use Case Fit**: ⭐⭐⭐ (Good for archival, poor for operational queries)

---

### Option 2: Cloud SQL PostgreSQL

**Pros**:
- Full PostgreSQL feature set
- ACID compliance
- Foreign key constraints
- JSONB support
- Low latency queries (<10ms)
- Familiar SQL interface
- Point-in-time recovery

**Cons**:
- Higher cost (minimum ~$25/month for db-f1-micro)
- Requires capacity planning
- Manual scaling
- Connection management overhead
- Operational maintenance (patches, backups)

**Cost Estimate**:
- Instance: db-custom-1-3840 (1 vCPU, 3.75 GB RAM) = ~$45/month
- Storage: 10 GB SSD = ~$1.70/month
- Backups: 10 GB = ~$0.26/month
- **Total: ~$47/month**

**Use Case Fit**: ⭐⭐⭐⭐ (Good fit, but higher cost)

---

### Option 3: Supabase PostgreSQL

**Pros**:
- Managed PostgreSQL with modern features
- Real-time subscriptions (WebSocket support)
- Built-in authentication and authorization
- RESTful API auto-generated from schema
- JSONB support with indexing
- Row-level security
- Free tier: 500 MB database, 2 GB bandwidth
- Pro tier: $25/month for 8 GB database, 50 GB bandwidth
- Automatic backups and point-in-time recovery
- Connection pooling included (PgBouncer)
- Low latency queries (<10ms)

**Cons**:
- External service (not native GCP)
- Network latency from GCP to Supabase
- Vendor lock-in considerations
- Limited to PostgreSQL (no multi-model support)

**Cost Estimate** (Pro tier):
- Base: $25/month (8 GB database, 50 GB bandwidth)
- Estimated usage: ~1 GB database, ~5 GB bandwidth/month
- **Total: $25/month** (fixed cost)

**Use Case Fit**: ⭐⭐⭐⭐⭐ (Excellent fit for operational data)

---

### Option 4: Firestore

**Pros**:
- Native GCP service
- Real-time synchronization
- Automatic scaling
- Document-based (flexible schema)
- Free tier: 1 GB storage, 50K reads/day

**Cons**:
- NoSQL (no SQL queries, no joins)
- Limited query capabilities
- No foreign key constraints
- Pricing can escalate with reads/writes
- Not ideal for relational data

**Cost Estimate**:
- Storage: 1 GB × $0.18/GB = $0.18/month
- Writes: 150K/month × $0.18/100K = $0.27/month
- Reads: 300K/month × $0.06/100K = $0.18/month
- **Total: ~$0.63/month**

**Use Case Fit**: ⭐⭐ (Poor fit for relational data)

---

## Decision Matrix

| Criteria | Weight | BigQuery | Cloud SQL | Supabase | Firestore |
|----------|--------|----------|-----------|----------|-----------|
| Query Performance | 25% | 2/5 | 5/5 | 5/5 | 3/5 |
| Cost at Scale | 20% | 5/5 | 2/5 | 4/5 | 4/5 |
| Real-time Queries | 20% | 2/5 | 5/5 | 5/5 | 5/5 |
| Integration Complexity | 15% | 5/5 | 4/5 | 4/5 | 5/5 |
| Data Modeling | 10% | 3/5 | 5/5 | 5/5 | 2/5 |
| Operational Overhead | 10% | 5/5 | 3/5 | 5/5 | 5/5 |
| **Weighted Score** | | **3.35** | **4.15** | **4.65** | **3.85** |

---

## Recommended Architecture: Hybrid Approach

### Primary Database: Supabase PostgreSQL
**Purpose**: Operational data storage for real-time queries

**Tables**:
- `shipments` - Current shipment state
- `containers` - Current container state
- `tracking_requests` - Active tracking subscriptions
- `webhook_deliveries` - Webhook processing status
- `container_events` - Recent events (last 90 days)

**Benefits**:
- Fast queries for operational dashboards
- Real-time subscriptions for live updates
- RESTful API for easy integration
- JSONB for flexible data structures
- Connection pooling included
- Automatic backups

**Access Pattern**:
- Cloud Functions → Supabase REST API or PostgreSQL connection
- Direct SQL queries for complex operations
- Real-time subscriptions for live dashboards

---

### Secondary Database: BigQuery
**Purpose**: Raw event archival and analytical queries

**Tables**:
- `raw_events_archive` - All webhook payloads (append-only)
- `events_historical` - Historical events (>90 days)

**Benefits**:
- Cost-effective for large-scale storage
- Excellent for analytical queries
- Partitioning by date for performance
- Reprocessing capability (raw payloads preserved)
- Long-term retention (1+ years)

**Access Pattern**:
- Cloud Functions → BigQuery Streaming API
- Batch queries for analytics and reporting
- Data export for machine learning

---

## Implementation Strategy

### Phase 1: Supabase Setup
1. Create Supabase project (already exists: `srordjhkcvyfyvepzrzp`)
2. Design and implement schema
3. Configure connection pooling
4. Set up row-level security policies
5. Create database indexes
6. Configure automatic backups

### Phase 2: BigQuery Setup
1. Create BigQuery dataset: `terminal49_raw_events`
2. Create table: `raw_events_archive`
3. Configure partitioning by `received_at` (daily)
4. Set up streaming inserts from Cloud Functions
5. Configure retention policy (1 year)

### Phase 3: Data Flow
```
Terminal49 Webhook
    ↓
Cloud Function (Webhook Receiver)
    ↓
Pub/Sub Topic
    ↓
Cloud Function (Event Processor)
    ↓
    ├─→ BigQuery (raw event archival) [async]
    └─→ Supabase (operational data) [sync]
```

---

## Cost Projection

### Current Scale (5000 events/day)
- **Supabase Pro**: $25/month (fixed)
- **BigQuery**: ~$0.20/month (storage + queries)
- **Total**: ~$25.20/month

### 10x Scale (50,000 events/day)
- **Supabase Pro**: $25/month (still within limits)
- **BigQuery**: ~$2/month (storage + queries)
- **Total**: ~$27/month

### 100x Scale (500,000 events/day)
- **Supabase**: May need to upgrade to Team tier ($599/month) or optimize
- **BigQuery**: ~$20/month
- **Total**: ~$620/month (or optimize Supabase usage)

**Conclusion**: Cost-effective for initial scale, with clear upgrade path.

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Supabase outage | BigQuery has all raw events for reprocessing |
| Network latency to Supabase | Use connection pooling, batch writes where possible |
| Supabase cost escalation | Monitor usage, implement data archival strategy |
| Data consistency between systems | BigQuery is source of truth, Supabase can be rebuilt |
| Vendor lock-in (Supabase) | PostgreSQL is standard, migration path exists |

---

## Alternative Considered: Cloud SQL

If Supabase proves problematic, Cloud SQL PostgreSQL is the fallback:
- Similar features (PostgreSQL)
- Native GCP integration
- Higher cost (~$47/month vs $25/month)
- More operational overhead
- Better for high-scale scenarios (100K+ events/day)

---

## Decision Approval

**Decision**: Hybrid approach (Supabase + BigQuery)

**Approved By**: Development Team
**Date**: 2026-01-02
**Review Date**: After 3 months of production usage

---

## Next Steps

1. ✅ Document decision in [`memory-bank/decisionLog.md`](../../memory-bank/decisionLog.md)
2. Proceed to Phase 1.3: Secret Management Solution
3. Design database schema for Supabase (Phase 1.4)
4. Create BigQuery dataset and table (Phase 1.4)
5. Implement connection utilities for both databases

---

## References

- [Supabase Pricing](https://supabase.com/pricing)
- [BigQuery Pricing](https://cloud.google.com/bigquery/pricing)
- [Cloud SQL Pricing](https://cloud.google.com/sql/pricing)
- [PostgreSQL JSONB Performance](https://www.postgresql.org/docs/current/datatype-json.html)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
