-- Optimize get_container_tracking_summary: filtered CTE pattern
--
-- Problem: ts_ports and latest_event CTEs scan the entire container_events
-- table on every call, then LIMIT/OFFSET is applied at the end. With large
-- datasets this causes timeouts.
--
-- Fix: A 'filtered' CTE applies all WHERE clauses + LIMIT/OFFSET against
-- shipments + containers only, yielding at most p_limit (shipment_id,
-- container_id) pairs. The two container_events CTEs are then scoped to
-- those container IDs only — not the full table.
--
-- Also adds three indexes that were genuinely missing from prior migrations.

-- ============================================================================
-- STEP 1 — New indexes
-- Note: CONCURRENTLY is not used here because Supabase migrations run inside
-- a transaction block. The indexes will lock the table briefly during creation.
-- If you need non-blocking creation on a live high-traffic database, run the
-- three CREATE INDEX CONCURRENTLY statements manually outside a transaction
-- before applying this migration.
-- ============================================================================

-- Composite index to support combined SCAC + ETD-range filter.
CREATE INDEX IF NOT EXISTS idx_shipments_scac_etd
    ON shipments (shipping_line_scac, pol_etd_at DESC NULLS LAST);

-- Supports the COALESCE(pol_etd_at, pol_atd_at) ATD fallback in the ETD filter.
CREATE INDEX IF NOT EXISTS idx_shipments_atd
    ON shipments (pol_atd_at DESC NULLS LAST);

-- Covering partial index for the ts_ports CTE.
-- The existing idx_events_transshipment covers (container_id, event_timestamp)
-- which does not include location_locode / location_name, forcing a heap fetch
-- for every transshipment row. This index eliminates that fetch.
CREATE INDEX IF NOT EXISTS idx_events_transshipment_covering
    ON container_events (container_id, location_locode, location_name)
    WHERE event_type LIKE 'container.transport.transshipment%';

-- ============================================================================
-- STEP 2 — Drop previous overload (9-param with VARCHAR types) to avoid
--          function signature ambiguity (PG error 42725).
-- ============================================================================

DROP FUNCTION IF EXISTS get_container_tracking_summary(
    TEXT, TEXT, VARCHAR, VARCHAR, VARCHAR, INT, INT, DATE, DATE
);

-- ============================================================================
-- STEP 3 — Rewritten RPC
-- ============================================================================

CREATE OR REPLACE FUNCTION get_container_tracking_summary(
    p_search      text    DEFAULT NULL,
    p_status      text    DEFAULT NULL,
    p_scac        text    DEFAULT NULL,
    p_pol_locode  text    DEFAULT NULL,
    p_pod_locode  text    DEFAULT NULL,
    p_etd_from    date    DEFAULT NULL,
    p_etd_to      date    DEFAULT NULL,
    p_limit       integer DEFAULT 50,
    p_offset      integer DEFAULT 0
)
RETURNS TABLE (
    -- Shipment identifiers
    shipment_id            uuid,
    t49_shipment_id        uuid,          -- kept as uuid (not text) — no breaking change
    bill_of_lading         text,
    -- Shipping line
    shipping_line_scac     text,
    shipping_line_name     text,
    -- Voyage
    pod_voyage_number      text,
    -- Ports
    pol_locode             text,
    pol_name               text,
    pod_locode             text,
    pod_name               text,
    destination_locode     text,
    -- POD vessel
    vessel_name            text,
    vessel_imo             text,
    -- Timeline
    pol_etd_at             timestamptz,
    pol_atd_at             timestamptz,
    pod_eta_at             timestamptz,
    pod_ata_at             timestamptz,
    destination_eta_at     timestamptz,
    -- Container identifiers
    container_id           uuid,
    container_number       text,
    equipment_type         text,
    seal_number            text,
    -- Container status and dates
    current_status         text,
    available_for_pickup   boolean,
    pickup_lfd             timestamptz,   -- kept as timestamptz — no breaking change
    pod_arrived_at         timestamptz,
    pod_discharged_at      timestamptz,
    -- Transshipment ports aggregated from container_events
    transshipment_locodes  text[],
    transshipment_names    text[],
    -- Latest event info
    latest_event_type      text,
    latest_event_at        timestamptz,
    latest_location        text
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    WITH
    -- Phase 1: apply all filters + pagination against shipments + containers only.
    -- Produces at most p_limit rows — the two container_events CTEs below are
    -- scoped to exactly these container IDs.
    filtered AS (
        SELECT
            s.id AS shipment_id,
            c.id AS container_id
        FROM shipments s
        JOIN containers c ON c.shipment_id = s.id
        WHERE
            (p_search IS NULL
                OR s.bill_of_lading_number ILIKE '%' || p_search || '%'
                OR s.normalized_number     ILIKE '%' || p_search || '%'
                OR c.number                ILIKE '%' || p_search || '%')
            AND (p_status     IS NULL OR c.current_status           = p_status)
            AND (p_scac       IS NULL OR s.shipping_line_scac        = p_scac)
            AND (p_pol_locode IS NULL OR s.port_of_lading_locode     = p_pol_locode)
            AND (p_pod_locode IS NULL OR s.port_of_discharge_locode  = p_pod_locode)
            AND (p_etd_from   IS NULL
                    OR COALESCE(s.pol_etd_at, s.pol_atd_at)::date >= p_etd_from)
            AND (p_etd_to     IS NULL
                    OR COALESCE(s.pol_etd_at, s.pol_atd_at)::date <= p_etd_to)
        ORDER BY s.updated_at DESC, c.number
        LIMIT  p_limit
        OFFSET p_offset
    ),

    -- Phase 2a: transshipment ports — scoped to filtered containers only.
    -- Uses idx_events_transshipment_covering (covering partial index).
    ts_ports AS (
        SELECT
            ce.container_id,
            array_agg(DISTINCT ce.location_locode ORDER BY ce.location_locode)
                FILTER (WHERE ce.location_locode IS NOT NULL) AS locodes,
            array_agg(DISTINCT ce.location_name  ORDER BY ce.location_name)
                FILTER (WHERE ce.location_name IS NOT NULL)   AS names
        FROM container_events ce
        WHERE ce.event_type LIKE 'container.transport.transshipment%'
          AND ce.container_id IN (SELECT f.container_id FROM filtered f)
        GROUP BY ce.container_id
    ),

    -- Phase 2b: latest event — scoped to filtered containers only.
    -- Uses idx_events_container_timestamp (container_id, event_timestamp DESC).
    latest_event AS (
        SELECT DISTINCT ON (ce.container_id)
            ce.container_id,
            ce.event_type,
            ce.event_timestamp,
            ce.location_locode
        FROM container_events ce
        WHERE ce.container_id IN (SELECT f.container_id FROM filtered f)
        ORDER BY ce.container_id, ce.event_timestamp DESC NULLS LAST
    )

    -- Phase 3: column projection only — no additional filtering.
    SELECT
        s.id                                                             AS shipment_id,
        s.t49_shipment_id,
        s.bill_of_lading_number::text                                    AS bill_of_lading,
        s.shipping_line_scac::text,
        (s.raw_data -> 'attributes' ->> 'shipping_line_name')::text      AS shipping_line_name,
        (s.raw_data -> 'attributes' ->> 'pod_voyage_number')::text       AS pod_voyage_number,
        s.port_of_lading_locode::text                                    AS pol_locode,
        (s.raw_data -> 'attributes' ->> 'port_of_lading_name')::text     AS pol_name,
        s.port_of_discharge_locode::text                                 AS pod_locode,
        (s.raw_data -> 'attributes' ->> 'port_of_discharge_name')::text  AS pod_name,
        s.destination_locode::text,
        s.pod_vessel_name::text                                          AS vessel_name,
        s.pod_vessel_imo::text                                           AS vessel_imo,
        s.pol_etd_at,
        s.pol_atd_at,
        s.pod_eta_at,
        s.pod_ata_at,
        s.destination_eta_at,
        c.id                                                             AS container_id,
        c.number::text                                                   AS container_number,
        c.equipment_type::text,
        c.seal_number::text,
        c.current_status::text,
        c.available_for_pickup,
        c.pickup_lfd,
        c.pod_arrived_at,
        c.pod_discharged_at,
        tp.locodes::text[]                                               AS transshipment_locodes,
        tp.names::text[]                                                 AS transshipment_names,
        le.event_type::text                                              AS latest_event_type,
        le.event_timestamp                                               AS latest_event_at,
        le.location_locode::text                                         AS latest_location
    FROM filtered f
    JOIN shipments  s  ON s.id = f.shipment_id
    JOIN containers c  ON c.id = f.container_id
    LEFT JOIN ts_ports    tp ON tp.container_id = f.container_id
    LEFT JOIN latest_event le ON le.container_id = f.container_id
    ORDER BY s.updated_at DESC, c.number;
END;
$$;

COMMENT ON FUNCTION get_container_tracking_summary IS
    'Paginated container tracking summary for the web app. Returns one row per container '
    'with vessel, voyage, ports, timeline, status, and aggregated transshipment ports. '
    'Supports free-text search (B/L, normalized number, container #), status/SCAC/port '
    'filters, and ETD date-range filtering (p_etd_from / p_etd_to, inclusive, falls back '
    'to ATD when ETD is null). '
    'Performance: filtered CTE applies LIMIT/OFFSET before touching container_events, '
    'keeping both event CTEs scoped to at most p_limit containers.';

-- ============================================================================
-- SCHEMA VERSION TRACKING
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('1.5.0', 'Optimize tracking summary RPC with filtered CTE pattern; add scac_etd, atd, and transshipment covering indexes')
ON CONFLICT (version) DO NOTHING;
