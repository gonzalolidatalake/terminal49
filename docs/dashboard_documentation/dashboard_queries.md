# Dashboard Queries for Terminal49 Tracking System

## Overview

This document provides specific SQL queries for the Terminal49 dashboard application, covering TEU analytics, vessel positioning, and operational summaries.

## TEU Calculation Logic

```sql
-- TEU Calculation Function
-- 20' container = 1 TEU
-- 40' container = 2 TEU
-- Default = 1 TEU (for unknown sizes)

CASE 
    WHEN equipment_length = 20 THEN 1
    WHEN equipment_length = 40 THEN 2
    ELSE 1
END AS teu_count
```

## 1. TEU Analytics by ISO Week and Carrier

### 1.1 Current Period TEU Summary (Supabase)

```sql
-- TEU aggregation by ISO week and carrier for current period (last 90 days)
SELECT 
    EXTRACT(WEEK FROM c.created_at) AS iso_week,
    EXTRACT(YEAR FROM c.created_at) AS year,
    s.shipping_line_scac AS carrier,
    COUNT(c.id) AS container_count,
    SUM(
        CASE 
            WHEN c.equipment_length = 20 THEN 1
            WHEN c.equipment_length = 40 THEN 2
            ELSE 1
        END
    ) AS total_teus,
    AVG(
        CASE 
            WHEN c.equipment_length = 20 THEN 1
            WHEN c.equipment_length = 40 THEN 2
            ELSE 1
        END
    ) AS avg_teus_per_container
FROM containers c
JOIN shipments s ON c.shipment_id = s.id
WHERE c.created_at >= CURRENT_DATE - INTERVAL '90 days'
    AND s.shipping_line_scac IS NOT NULL
GROUP BY 
    EXTRACT(WEEK FROM c.created_at),
    EXTRACT(YEAR FROM c.created_at),
    s.shipping_line_scac
ORDER BY year DESC, iso_week DESC, total_teus DESC;
```

### 1.2 TEU Breakdown by Container Size and Carrier

```sql
-- Detailed TEU breakdown showing container size distribution
SELECT 
    EXTRACT(WEEK FROM c.created_at) AS iso_week,
    EXTRACT(YEAR FROM c.created_at) AS year,
    s.shipping_line_scac AS carrier,
    c.equipment_length AS container_size,
    COUNT(c.id) AS container_count,
    SUM(
        CASE 
            WHEN c.equipment_length = 20 THEN 1
            WHEN c.equipment_length = 40 THEN 2
            ELSE 1
        END
    ) AS total_teus
FROM containers c
JOIN shipments s ON c.shipment_id = s.id
WHERE c.created_at >= CURRENT_DATE - INTERVAL '90 days'
    AND s.shipping_line_scac IS NOT NULL
    AND c.equipment_length IS NOT NULL
GROUP BY 
    EXTRACT(WEEK FROM c.created_at),
    EXTRACT(YEAR FROM c.created_at),
    s.shipping_line_scac,
    c.equipment_length
ORDER BY year DESC, iso_week DESC, carrier, container_size;
```

### 1.3 Weekly TEU Trends (Chart Data)

```sql
-- Weekly TEU trends for bar chart visualization
WITH weekly_teus AS (
    SELECT 
        EXTRACT(WEEK FROM c.created_at) AS iso_week,
        EXTRACT(YEAR FROM c.created_at) AS year,
        DATE_TRUNC('week', c.created_at) AS week_start,
        s.shipping_line_scac AS carrier,
        SUM(
            CASE 
                WHEN c.equipment_length = 20 THEN 1
                WHEN c.equipment_length = 40 THEN 2
                ELSE 1
            END
        ) AS total_teus
    FROM containers c
    JOIN shipments s ON c.shipment_id = s.id
    WHERE c.created_at >= CURRENT_DATE - INTERVAL '12 weeks'
        AND s.shipping_line_scac IS NOT NULL
    GROUP BY 
        EXTRACT(WEEK FROM c.created_at),
        EXTRACT(YEAR FROM c.created_at),
        DATE_TRUNC('week', c.created_at),
        s.shipping_line_scac
)
SELECT 
    iso_week,
    year,
    week_start,
    carrier,
    total_teus,
    SUM(total_teus) OVER (PARTITION BY iso_week, year) AS week_total_teus,
    ROUND(
        (total_teus * 100.0 / SUM(total_teus) OVER (PARTITION BY iso_week, year)), 2
    ) AS carrier_percentage
FROM weekly_teus
ORDER BY year DESC, iso_week DESC, total_teus DESC;
```

## 2. Vessel Position Data for Active Vessels

### 2.1 Active Vessels with Recent Activity

```sql
-- Get active vessels from recent container events (last 30 days)
-- This provides vessel IMO numbers for Terminal49 API calls
SELECT DISTINCT
    ce.vessel_imo,
    ce.vessel_name,
    COUNT(DISTINCT ce.container_id) AS active_containers,
    COUNT(DISTINCT ce.shipment_id) AS active_shipments,
    MAX(ce.event_timestamp) AS last_event_timestamp,
    MAX(ce.created_at) AS last_received_at,
    ARRAY_AGG(DISTINCT s.shipping_line_scac) FILTER (WHERE s.shipping_line_scac IS NOT NULL) AS carriers
FROM container_events ce
JOIN containers c ON ce.container_id = c.id
JOIN shipments s ON ce.shipment_id = s.id
WHERE ce.created_at >= CURRENT_DATE - INTERVAL '30 days'
    AND ce.vessel_imo IS NOT NULL
    AND ce.vessel_name IS NOT NULL
GROUP BY ce.vessel_imo, ce.vessel_name
HAVING MAX(ce.event_timestamp) >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY last_event_timestamp DESC;
```

### 2.2 Vessel Movement Summary

```sql
-- Vessel movement summary with latest locations
SELECT 
    ce.vessel_imo,
    ce.vessel_name,
    ce.location_locode AS current_location,
    ce.location_name AS current_location_name,
    ce.event_timestamp AS position_timestamp,
    ce.event_type AS latest_event,
    COUNT(DISTINCT ce.container_id) AS containers_on_vessel,
    ARRAY_AGG(DISTINCT s.shipping_line_scac) FILTER (WHERE s.shipping_line_scac IS NOT NULL) AS carriers
FROM container_events ce
JOIN containers c ON ce.container_id = c.id
JOIN shipments s ON ce.shipment_id = s.id
WHERE ce.vessel_imo IS NOT NULL
    AND ce.created_at >= CURRENT_DATE - INTERVAL '30 days'
    AND ce.event_timestamp = (
        SELECT MAX(ce2.event_timestamp)
        FROM container_events ce2
        WHERE ce2.vessel_imo = ce.vessel_imo
            AND ce2.created_at >= CURRENT_DATE - INTERVAL '30 days'
    )
GROUP BY 
    ce.vessel_imo, 
    ce.vessel_name, 
    ce.location_locode, 
    ce.location_name, 
    ce.event_timestamp, 
    ce.event_type
ORDER BY ce.event_timestamp DESC;
```

### 2.3 Vessels by Route (Port Pairs)

```sql
-- Vessels grouped by common routes for map visualization
SELECT 
    s.port_of_lading_locode AS origin_port,
    s.port_of_discharge_locode AS destination_port,
    COUNT(DISTINCT ce.vessel_imo) AS vessel_count,
    ARRAY_AGG(DISTINCT ce.vessel_name) AS vessel_names,
    ARRAY_AGG(DISTINCT ce.vessel_imo) AS vessel_imos,
    COUNT(DISTINCT c.id) AS total_containers,
    SUM(
        CASE 
            WHEN c.equipment_length = 20 THEN 1
            WHEN c.equipment_length = 40 THEN 2
            ELSE 1
        END
    ) AS total_teus
FROM container_events ce
JOIN containers c ON ce.container_id = c.id
JOIN shipments s ON ce.shipment_id = s.id
WHERE ce.created_at >= CURRENT_DATE - INTERVAL '30 days'
    AND ce.vessel_imo IS NOT NULL
    AND s.port_of_lading_locode IS NOT NULL
    AND s.port_of_discharge_locode IS NOT NULL
GROUP BY s.port_of_lading_locode, s.port_of_discharge_locode
HAVING COUNT(DISTINCT ce.vessel_imo) > 0
ORDER BY total_teus DESC;
```

## 3. Container and Shipment Summaries

### 3.1 Container Summary by Carrier and Vessel

```sql
-- Container count and status summary by carrier and vessel
SELECT 
    s.shipping_line_scac AS carrier,
    ce.vessel_name,
    ce.vessel_imo,
    COUNT(DISTINCT c.id) AS total_containers,
    SUM(
        CASE 
            WHEN c.equipment_length = 20 THEN 1
            WHEN c.equipment_length = 40 THEN 2
            ELSE 1
        END
    ) AS total_teus,
    COUNT(DISTINCT CASE WHEN c.current_status = 'available_for_pickup' THEN c.id END) AS available_containers,
    COUNT(DISTINCT CASE WHEN c.current_status = 'discharged' THEN c.id END) AS discharged_containers,
    COUNT(DISTINCT CASE WHEN c.current_status = 'in_transit' THEN c.id END) AS in_transit_containers,
    COUNT(DISTINCT CASE WHEN c.available_for_pickup = true THEN c.id END) AS pickup_ready,
    AVG(c.weight_in_lbs) AS avg_weight_lbs,
    MIN(c.pickup_lfd) AS earliest_lfd,
    MAX(c.pickup_lfd) AS latest_lfd
FROM containers c
JOIN shipments s ON c.shipment_id = s.id
LEFT JOIN container_events ce ON c.id = ce.container_id 
    AND ce.event_timestamp = (
        SELECT MAX(ce2.event_timestamp)
        FROM container_events ce2
        WHERE ce2.container_id = c.id
    )
WHERE c.created_at >= CURRENT_DATE - INTERVAL '90 days'
    AND s.shipping_line_scac IS NOT NULL
GROUP BY s.shipping_line_scac, ce.vessel_name, ce.vessel_imo
ORDER BY total_teus DESC;
```

### 3.2 Shipment Summary by Carrier and Vessel

```sql
-- Shipment count and performance summary by carrier and vessel
SELECT 
    s.shipping_line_scac AS carrier,
    s.pod_vessel_name AS vessel_name,
    s.pod_vessel_imo AS vessel_imo,
    COUNT(DISTINCT s.id) AS total_shipments,
    COUNT(DISTINCT c.id) AS total_containers,
    SUM(
        CASE 
            WHEN c.equipment_length = 20 THEN 1
            WHEN c.equipment_length = 40 THEN 2
            ELSE 1
        END
    ) AS total_teus,
    COUNT(DISTINCT CASE WHEN s.pod_ata_at IS NOT NULL THEN s.id END) AS arrived_shipments,
    COUNT(DISTINCT CASE WHEN s.pod_ata_at IS NULL AND s.pod_eta_at < CURRENT_TIMESTAMP THEN s.id END) AS delayed_shipments,
    AVG(EXTRACT(EPOCH FROM (s.pod_ata_at - s.pod_eta_at))/3600) AS avg_delay_hours,
    MIN(s.pod_eta_at) AS earliest_eta,
    MAX(s.pod_eta_at) AS latest_eta,
    COUNT(DISTINCT s.port_of_lading_locode) AS origin_ports,
    COUNT(DISTINCT s.port_of_discharge_locode) AS destination_ports
FROM shipments s
LEFT JOIN containers c ON s.id = c.shipment_id
WHERE s.created_at >= CURRENT_DATE - INTERVAL '90 days'
    AND s.shipping_line_scac IS NOT NULL
GROUP BY s.shipping_line_scac, s.pod_vessel_name, s.pod_vessel_imo
ORDER BY total_teus DESC;
```

### 3.3 Operational KPIs by Carrier

```sql
-- Key performance indicators by carrier
SELECT 
    s.shipping_line_scac AS carrier,
    COUNT(DISTINCT s.id) AS total_shipments,
    COUNT(DISTINCT c.id) AS total_containers,
    SUM(
        CASE 
            WHEN c.equipment_length = 20 THEN 1
            WHEN c.equipment_length = 40 THEN 2
            ELSE 1
        END
    ) AS total_teus,
    
    -- Performance Metrics
    ROUND(
        COUNT(DISTINCT CASE WHEN s.pod_ata_at <= s.pod_eta_at THEN s.id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT CASE WHEN s.pod_ata_at IS NOT NULL THEN s.id END), 0), 2
    ) AS on_time_percentage,
    
    ROUND(
        AVG(EXTRACT(EPOCH FROM (s.pod_ata_at - s.pod_eta_at))/3600), 2
    ) AS avg_delay_hours,
    
    -- Container Status Distribution
    ROUND(
        COUNT(DISTINCT CASE WHEN c.available_for_pickup = true THEN c.id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT c.id), 0), 2
    ) AS pickup_ready_percentage,
    
    -- LFD Analysis
    COUNT(DISTINCT CASE WHEN c.pickup_lfd < CURRENT_DATE THEN c.id END) AS containers_past_lfd,
    
    -- Port Coverage
    COUNT(DISTINCT s.port_of_lading_locode) AS origin_ports_served,
    COUNT(DISTINCT s.port_of_discharge_locode) AS destination_ports_served,
    
    -- Recent Activity
    MAX(s.created_at) AS last_shipment_created,
    MAX(c.updated_at) AS last_container_updated
    
FROM shipments s
LEFT JOIN containers c ON s.id = c.shipment_id
WHERE s.created_at >= CURRENT_DATE - INTERVAL '90 days'
    AND s.shipping_line_scac IS NOT NULL
GROUP BY s.shipping_line_scac
ORDER BY total_teus DESC;
```

## 4. BigQuery Historical Analysis Queries

### 4.1 Historical TEU Trends (BigQuery)

```sql
-- Historical TEU analysis from BigQuery for long-term trends
WITH container_teus AS (
    SELECT 
        DATE_TRUNC(DATE(created_at), WEEK) AS week_start,
        EXTRACT(WEEK FROM created_at) AS iso_week,
        EXTRACT(YEAR FROM created_at) AS year,
        JSON_EXTRACT_SCALAR(raw_data, '$.attributes.shipping_line_scac') AS carrier,
        CASE 
            WHEN CAST(JSON_EXTRACT_SCALAR(raw_data, '$.attributes.equipment_length') AS INT64) = 20 THEN 1
            WHEN CAST(JSON_EXTRACT_SCALAR(raw_data, '$.attributes.equipment_length') AS INT64) = 40 THEN 2
            ELSE 1
        END AS teu_count
    FROM `li-customer-datalake.terminal49_raw_events.events_historical`
    WHERE event_type LIKE 'container.%'
        AND DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 52 WEEK)
        AND JSON_EXTRACT_SCALAR(raw_data, '$.attributes.shipping_line_scac') IS NOT NULL
)
SELECT 
    week_start,
    iso_week,
    year,
    carrier,
    COUNT(*) AS container_count,
    SUM(teu_count) AS total_teus,
    AVG(teu_count) AS avg_teus_per_container
FROM container_teus
GROUP BY week_start, iso_week, year, carrier
ORDER BY week_start DESC, total_teus DESC;
```

### 4.2 Vessel Performance Analysis (BigQuery)

```sql
-- Historical vessel performance analysis
SELECT 
    JSON_EXTRACT_SCALAR(payload, '$.included[0].attributes.vessel_name') AS vessel_name,
    JSON_EXTRACT_SCALAR(payload, '$.included[0].attributes.vessel_imo') AS vessel_imo,
    DATE_TRUNC(DATE(event_timestamp), MONTH) AS month,
    COUNT(DISTINCT container_id) AS containers_handled,
    COUNT(DISTINCT shipment_id) AS shipments_handled,
    COUNT(DISTINCT JSON_EXTRACT_SCALAR(payload, '$.included[0].attributes.location_locode')) AS ports_visited,
    AVG(processing_duration_ms) AS avg_processing_time_ms
FROM `li-customer-datalake.terminal49_raw_events.raw_events_archive`
WHERE DATE(received_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
    AND event_category = 'container'
    AND vessel_imo IS NOT NULL
GROUP BY vessel_name, vessel_imo, month
ORDER BY month DESC, containers_handled DESC;
```

## 5. Performance Optimization Queries

### 5.1 Query Performance Analysis

```sql
-- Analyze query performance for dashboard optimization
SELECT 
    schemaname,
    tablename,
    attname AS column_name,
    n_distinct,
    correlation,
    most_common_vals,
    most_common_freqs
FROM pg_stats 
WHERE schemaname = 'public' 
    AND tablename IN ('containers', 'shipments', 'container_events')
    AND attname IN ('shipping_line_scac', 'equipment_length', 'event_type', 'created_at')
ORDER BY tablename, attname;
```

### 5.2 Index Usage Analysis

```sql
-- Check index usage for optimization
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

## 6. Real-time Dashboard Queries (Optimized)

### 6.1 Dashboard Summary Stats

```sql
-- Real-time dashboard summary (optimized for speed)
WITH stats AS (
    SELECT 
        COUNT(DISTINCT s.id) AS total_shipments,
        COUNT(DISTINCT c.id) AS total_containers,
        SUM(
            CASE 
                WHEN c.equipment_length = 20 THEN 1
                WHEN c.equipment_length = 40 THEN 2
                ELSE 1
            END
        ) AS total_teus,
        COUNT(DISTINCT s.shipping_line_scac) AS active_carriers,
        COUNT(DISTINCT CASE WHEN ce.vessel_imo IS NOT NULL THEN ce.vessel_imo END) AS active_vessels
    FROM shipments s
    LEFT JOIN containers c ON s.id = c.shipment_id
    LEFT JOIN container_events ce ON c.id = ce.container_id
    WHERE s.created_at >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT * FROM stats;
```

### 6.2 Recent Activity Feed

```sql
-- Recent activity for dashboard feed (last 24 hours)
SELECT 
    'container_event' AS activity_type,
    ce.event_type AS event_name,
    ce.event_timestamp,
    c.number AS container_number,
    s.bill_of_lading_number,
    s.shipping_line_scac AS carrier,
    ce.vessel_name,
    ce.location_name,
    ce.created_at
FROM container_events ce
JOIN containers c ON ce.container_id = c.id
JOIN shipments s ON ce.shipment_id = s.id
WHERE ce.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY ce.created_at DESC
LIMIT 50;
```

## Query Performance Notes

### Indexing Recommendations
1. **Composite indexes** on frequently joined columns
2. **Partial indexes** on filtered queries (e.g., WHERE created_at >= CURRENT_DATE - INTERVAL '90 days')
3. **GIN indexes** on JSONB columns for flexible queries

### Caching Strategy
1. **Application-level caching** for summary statistics (5-minute TTL)
2. **Materialized views** for complex aggregations
3. **Connection pooling** for database efficiency

### Real-time Updates
1. **Supabase real-time subscriptions** for live dashboard updates
2. **Webhook notifications** for critical events
3. **Polling intervals** optimized by data freshness requirements

---

*These queries provide the foundation for a comprehensive Terminal49 tracking dashboard with optimal performance and real-time capabilities.*