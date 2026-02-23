-- Terminal49 Webhook Infrastructure - Container Tracking Summary RPC
-- Version: 1.0.0
-- Date: 2026-02-23
-- Description: RPC function and indexes for the web app container tracking summary table.
--
-- Run this in the Supabase SQL Editor (or via psql) once.
-- Prerequisites: supabase_schema.sql (001) must already be applied.

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

-- Trigram extension enables fast ILIKE search on text columns
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- GIN trigram indexes for fast B/L and container number search
CREATE INDEX IF NOT EXISTS idx_shipments_bol_trgm
    ON shipments USING GIN(bill_of_lading_number gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_shipments_normalized_trgm
    ON shipments USING GIN(normalized_number gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_containers_number_trgm
    ON containers USING GIN(number gin_trgm_ops);

-- Partial index for transshipment aggregation CTE.
-- Filters ~90% of events upfront, making the GROUP BY dramatically cheaper.
CREATE INDEX IF NOT EXISTS idx_events_transshipment
    ON container_events(container_id, event_timestamp)
    WHERE event_type LIKE 'container.transport.transshipment%';

-- ============================================================================
-- RPC FUNCTION: get_container_tracking_summary
-- ============================================================================
-- Returns one row per container with all tracking fields needed for the
-- summary table. Supports filtered search and cursor-based pagination.
--
-- Parameters:
--   p_search     - free-text search against B/L, normalized number, container #
--   p_status     - exact match on containers.current_status
--   p_scac       - exact match on shipments.shipping_line_scac
--   p_pol_locode - exact match on shipments.port_of_lading_locode
--   p_pod_locode - exact match on shipments.port_of_discharge_locode
--   p_limit      - page size (default 50)
--   p_offset     - row offset for pagination (default 0)
--
-- Usage (Supabase JS):
--   const { data } = await supabase.rpc('get_container_tracking_summary', {
--     p_search: 'TJN0858279', p_limit: 50, p_offset: 0
--   })
-- ============================================================================

CREATE OR REPLACE FUNCTION get_container_tracking_summary(
    p_search       TEXT    DEFAULT NULL,
    p_status       TEXT    DEFAULT NULL,
    p_scac         VARCHAR DEFAULT NULL,
    p_pol_locode   VARCHAR DEFAULT NULL,
    p_pod_locode   VARCHAR DEFAULT NULL,
    p_limit        INT     DEFAULT 50,
    p_offset       INT     DEFAULT 0
)
RETURNS TABLE (
    -- Shipment identifiers
    shipment_id            UUID,
    t49_shipment_id        UUID,
    bill_of_lading         TEXT,
    -- Shipping line
    shipping_line_scac     TEXT,
    shipping_line_name     TEXT,
    -- Voyage (from shipment attributes)
    pod_voyage_number      TEXT,
    -- Ports with LOCODE and human-readable name
    pol_locode             TEXT,
    pol_name               TEXT,
    pod_locode             TEXT,
    pod_name               TEXT,
    destination_locode     TEXT,
    -- POD vessel
    vessel_name            TEXT,
    vessel_imo             TEXT,
    -- Timeline
    pol_etd_at             TIMESTAMPTZ,
    pol_atd_at             TIMESTAMPTZ,
    pod_eta_at             TIMESTAMPTZ,
    pod_ata_at             TIMESTAMPTZ,
    destination_eta_at     TIMESTAMPTZ,
    -- Container identifiers
    container_id           UUID,
    container_number       TEXT,
    equipment_type         TEXT,
    seal_number            TEXT,
    -- Container status and dates
    current_status         TEXT,
    available_for_pickup   BOOLEAN,
    pickup_lfd             TIMESTAMPTZ,
    pod_arrived_at         TIMESTAMPTZ,
    pod_discharged_at      TIMESTAMPTZ,
    -- Transshipment ports aggregated from container_events
    transshipment_locodes  TEXT[],
    transshipment_names    TEXT[],
    -- Latest event info
    latest_event_type      TEXT,
    latest_event_at        TIMESTAMPTZ,
    latest_location        TEXT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    WITH
    -- Aggregate transshipment ports per container.
    -- Uses partial index idx_events_transshipment for efficiency.
    ts_ports AS (
        SELECT
            ce.container_id,
            array_agg(DISTINCT ce.location_locode ORDER BY ce.location_locode)
                FILTER (WHERE ce.location_locode IS NOT NULL) AS locodes,
            array_agg(DISTINCT ce.location_name  ORDER BY ce.location_name)
                FILTER (WHERE ce.location_name IS NOT NULL)   AS names
        FROM container_events ce
        WHERE ce.event_type LIKE 'container.transport.transshipment%'
        GROUP BY ce.container_id
    ),
    -- Most recent event per container.
    -- Uses idx_events_container_timestamp (container_id, event_timestamp DESC).
    latest_event AS (
        SELECT DISTINCT ON (ce.container_id)
            ce.container_id,
            ce.event_type,
            ce.event_timestamp,
            ce.location_locode
        FROM container_events ce
        ORDER BY ce.container_id, ce.event_timestamp DESC NULLS LAST
    )
    SELECT
        s.id                                                            AS shipment_id,
        s.t49_shipment_id,
        s.bill_of_lading_number::TEXT                                   AS bill_of_lading,
        s.shipping_line_scac::TEXT,
        (s.raw_data -> 'attributes' ->> 'shipping_line_name')::TEXT    AS shipping_line_name,
        (s.raw_data -> 'attributes' ->> 'pod_voyage_number')::TEXT     AS pod_voyage_number,
        s.port_of_lading_locode::TEXT                                  AS pol_locode,
        (s.raw_data -> 'attributes' ->> 'port_of_lading_name')::TEXT  AS pol_name,
        s.port_of_discharge_locode::TEXT                               AS pod_locode,
        (s.raw_data -> 'attributes' ->> 'port_of_discharge_name')::TEXT AS pod_name,
        s.destination_locode::TEXT,
        s.pod_vessel_name::TEXT                                        AS vessel_name,
        s.pod_vessel_imo::TEXT                                         AS vessel_imo,
        s.pol_etd_at,
        s.pol_atd_at,
        s.pod_eta_at,
        s.pod_ata_at,
        s.destination_eta_at,
        c.id                                                           AS container_id,
        c.number::TEXT                                                 AS container_number,
        c.equipment_type::TEXT,
        c.seal_number::TEXT,
        c.current_status::TEXT,
        c.available_for_pickup,
        c.pickup_lfd,
        c.pod_arrived_at,
        c.pod_discharged_at,
        tp.locodes                                                     AS transshipment_locodes,
        tp.names                                                       AS transshipment_names,
        le.event_type::TEXT                                            AS latest_event_type,
        le.event_timestamp                                             AS latest_event_at,
        le.location_locode::TEXT                                       AS latest_location
    FROM shipments s
    JOIN containers c   ON c.shipment_id = s.id
    LEFT JOIN ts_ports   tp ON tp.container_id = c.id
    LEFT JOIN latest_event le ON le.container_id = c.id
    WHERE
        (p_search     IS NULL
            OR s.bill_of_lading_number ILIKE '%' || p_search || '%'
            OR s.normalized_number     ILIKE '%' || p_search || '%'
            OR c.number                ILIKE '%' || p_search || '%')
        AND (p_status     IS NULL OR c.current_status           = p_status)
        AND (p_scac       IS NULL OR s.shipping_line_scac        = p_scac)
        AND (p_pol_locode IS NULL OR s.port_of_lading_locode     = p_pol_locode)
        AND (p_pod_locode IS NULL OR s.port_of_discharge_locode  = p_pod_locode)
    ORDER BY s.updated_at DESC, c.number
    LIMIT  p_limit
    OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_container_tracking_summary IS
    'Paginated container tracking summary for the web app. Returns one row per container '
    'with vessel, voyage, ports, timeline, status, and aggregated transshipment ports.';

-- ============================================================================
-- SCHEMA VERSION TRACKING
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('1.2.0', 'Add tracking summary RPC and trigram/transshipment indexes')
ON CONFLICT (version) DO NOTHING;

-- ============================================================================
-- OPTIONAL: Backfill voyage_number / vessel fields from raw_data
-- (only needed for events inserted before the database_operations.py fix)
-- Uncomment and run once after deploying the backend fix.
-- ============================================================================

-- UPDATE container_events
-- SET
--     vessel_name   = COALESCE(vessel_name,   raw_data -> 'attributes' ->> 'vessel_name'),
--     vessel_imo    = COALESCE(vessel_imo,     raw_data -> 'attributes' ->> 'vessel_imo'),
--     voyage_number = COALESCE(voyage_number,  raw_data -> 'attributes' ->> 'voyage_number'),
--     location_name = COALESCE(location_name,  raw_data -> 'attributes' ->> 'location_name')
-- WHERE vessel_name IS NULL
--    OR vessel_imo IS NULL
--    OR voyage_number IS NULL
--    OR location_name IS NULL;
