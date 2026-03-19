-- T49 vessel ID filter additions — v1.7.1
--
-- Changes:
--   1. get_container_tracking_summary — adds p_t49_vessel_id text DEFAULT NULL
--      Filters shipments via EXISTS on container_events.raw_data vessel relationship ID.
--
--   2. get_shipment_kpis — adds p_t49_vessel_id text DEFAULT NULL
--      Same filter applied to filtered_shipments CTE.
--
-- Backwards-compatible: p_vessel_filter (filters on s.pod_vessel_name) is preserved
-- unchanged. Callers that do not pass p_t49_vessel_id continue to work identically.

-- ============================================================================
-- RPC 1 — get_container_tracking_summary (add p_t49_vessel_id)
-- ============================================================================

-- Drop v1.7.0 signature (10 params) before recreating with 11 params.
DROP FUNCTION IF EXISTS get_container_tracking_summary(text,text,text,text,text,date,date,integer,integer,text);

CREATE FUNCTION get_container_tracking_summary(
    p_search          text    DEFAULT NULL,
    p_status          text    DEFAULT NULL,
    p_scac            text    DEFAULT NULL,
    p_pol_locode      text    DEFAULT NULL,
    p_pod_locode      text    DEFAULT NULL,
    p_etd_from        date    DEFAULT NULL,
    p_etd_to          date    DEFAULT NULL,
    p_limit           integer DEFAULT 50,
    p_offset          integer DEFAULT 0,
    p_vessel_filter   text    DEFAULT NULL,
    p_t49_vessel_id   text    DEFAULT NULL
)
RETURNS TABLE (
    -- Shipment identifiers
    shipment_id            uuid,
    t49_shipment_id        uuid,
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
    pickup_lfd             timestamptz,
    pod_arrived_at         timestamptz,
    pod_discharged_at      timestamptz,
    -- Transshipment ports aggregated from container_events
    transshipment_locodes  text[],
    transshipment_names    text[],
    -- Latest event info
    latest_event_type      text,
    latest_event_at        timestamptz,
    latest_location        text,
    -- Pagination metadata
    total_shipment_count   bigint
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    WITH
    -- Phase 1a: apply all filters over shipments only and paginate.
    -- p_limit means "N shipments per page".
    -- Uses:
    --   idx_containers_shipment_status for EXISTS(p_status)
    --   idx_containers_number_trgm / idx_containers_number for EXISTS(p_search container#)
    --   idx_shipments_bol_trgm / idx_shipments_normalized_trgm for B/L search
    --   idx_shipments_scac_etd for SCAC + ETD range
    shipment_page AS (
        SELECT
            s.id                   AS shipment_id,
            COUNT(*) OVER ()       AS total_shipment_count
        FROM shipments s
        WHERE
            (p_search IS NULL
                OR s.bill_of_lading_number ILIKE '%' || p_search || '%'
                OR s.normalized_number     ILIKE '%' || p_search || '%'
                OR EXISTS (
                    SELECT 1
                    FROM containers c2
                    WHERE c2.shipment_id = s.id
                      AND c2.number ILIKE '%' || p_search || '%'
                ))
            AND (p_status IS NULL OR EXISTS (
                SELECT 1
                FROM containers c2
                WHERE c2.shipment_id   = s.id
                  AND c2.current_status = p_status
            ))
            AND (p_scac          IS NULL OR s.shipping_line_scac        = p_scac)
            AND (p_pol_locode    IS NULL OR s.port_of_lading_locode     = p_pol_locode)
            AND (p_pod_locode    IS NULL OR s.port_of_discharge_locode  = p_pod_locode)
            AND (p_etd_from      IS NULL
                    OR COALESCE(s.pol_etd_at, s.pol_atd_at)::date >= p_etd_from)
            AND (p_etd_to        IS NULL
                    OR COALESCE(s.pol_etd_at, s.pol_atd_at)::date <= p_etd_to)
            AND (p_vessel_filter IS NULL OR s.pod_vessel_name           = p_vessel_filter)
            AND (
                p_t49_vessel_id IS NULL
                OR EXISTS (
                    SELECT 1 FROM container_events ce
                    WHERE ce.shipment_id = s.id
                      AND ce.raw_data->'relationships'->'vessel'->'data'->>'id' = p_t49_vessel_id
                )
            )
        ORDER BY s.updated_at DESC
        LIMIT  p_limit
        OFFSET p_offset
    ),

    -- Phase 1b: expand to ALL containers of the selected shipments.
    -- Uses idx_containers_shipment_id for the JOIN.
    filtered AS (
        SELECT
            sp.shipment_id,
            sp.total_shipment_count,
            c.id AS container_id
        FROM shipment_page sp
        JOIN containers c ON c.shipment_id = sp.shipment_id
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
        le.location_locode::text                                         AS latest_location,
        f.total_shipment_count
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
    'filters, ETD date-range filtering (p_etd_from / p_etd_to, inclusive, falls back '
    'to ATD when ETD is null), vessel filter (p_vessel_filter, matches shipments.pod_vessel_name), '
    'and T49 vessel ID filter (p_t49_vessel_id, matches container_events vessel relationship ID). '
    'BREAKING CHANGE v1.6.0: p_limit now means "N shipments per page" (previously N '
    'containers per page). Result set may exceed p_limit rows when shipments have multiple '
    'containers. New output column total_shipment_count returns the full filtered count.';

-- ============================================================================
-- RPC 2 — get_shipment_kpis (add p_t49_vessel_id)
-- ============================================================================

-- Drop v1.7.0 signature (8 params) before recreating with 9 params.
DROP FUNCTION IF EXISTS get_shipment_kpis(text,text,text,text,text,date,date,text);

CREATE FUNCTION get_shipment_kpis(
    p_search          text DEFAULT NULL,
    p_status          text DEFAULT NULL,
    p_scac            text DEFAULT NULL,
    p_pol_locode      text DEFAULT NULL,
    p_pod_locode      text DEFAULT NULL,
    p_etd_from        date DEFAULT NULL,
    p_etd_to          date DEFAULT NULL,
    p_vessel_filter   text DEFAULT NULL,
    p_t49_vessel_id   text DEFAULT NULL
)
RETURNS TABLE (
    total_shipments  bigint,
    total_containers bigint,
    total_teus       bigint,
    embarking_soon   bigint
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    WITH
    -- Apply all filters over shipments — no LIMIT/OFFSET.
    filtered_shipments AS (
        SELECT s.id AS shipment_id,
               COALESCE(s.pol_etd_at, s.pol_atd_at) AS departure_at
        FROM shipments s
        WHERE
            (p_search IS NULL
                OR s.bill_of_lading_number ILIKE '%' || p_search || '%'
                OR s.normalized_number     ILIKE '%' || p_search || '%'
                OR EXISTS (
                    SELECT 1
                    FROM containers c2
                    WHERE c2.shipment_id = s.id
                      AND c2.number ILIKE '%' || p_search || '%'
                ))
            AND (p_status IS NULL OR EXISTS (
                SELECT 1
                FROM containers c2
                WHERE c2.shipment_id    = s.id
                  AND c2.current_status = p_status
            ))
            AND (p_scac          IS NULL OR s.shipping_line_scac        = p_scac)
            AND (p_pol_locode    IS NULL OR s.port_of_lading_locode     = p_pol_locode)
            AND (p_pod_locode    IS NULL OR s.port_of_discharge_locode  = p_pod_locode)
            AND (p_etd_from      IS NULL
                    OR COALESCE(s.pol_etd_at, s.pol_atd_at)::date >= p_etd_from)
            AND (p_etd_to        IS NULL
                    OR COALESCE(s.pol_etd_at, s.pol_atd_at)::date <= p_etd_to)
            AND (p_vessel_filter IS NULL OR s.pod_vessel_name           = p_vessel_filter)
            AND (
                p_t49_vessel_id IS NULL
                OR EXISTS (
                    SELECT 1 FROM container_events ce
                    WHERE ce.shipment_id = s.id
                      AND ce.raw_data->'relationships'->'vessel'->'data'->>'id' = p_t49_vessel_id
                )
            )
    )
    SELECT
        COUNT(DISTINCT fs.shipment_id)::bigint                          AS total_shipments,
        COUNT(c.id)::bigint                                             AS total_containers,
        COALESCE(SUM(teu_from_equipment_type(c.equipment_type)), 0)::bigint AS total_teus,
        COUNT(DISTINCT fs.shipment_id)
            FILTER (WHERE fs.departure_at >= NOW()
                      AND fs.departure_at <  NOW() + INTERVAL '7 days')::bigint AS embarking_soon
    FROM filtered_shipments fs
    LEFT JOIN containers c ON c.shipment_id = fs.shipment_id;
END;
$$;

COMMENT ON FUNCTION get_shipment_kpis IS
    'Aggregate KPI cards for the operational shipments view. Applies the same filters as '
    'get_container_tracking_summary but with no pagination — always aggregates the full '
    'filtered dataset. Returns: total_shipments, total_containers, total_teus (using '
    'teu_from_equipment_type helper), embarking_soon (departures within the next 7 days). '
    'p_vessel_filter matches shipments.pod_vessel_name (main voyage vessel). '
    'p_t49_vessel_id matches container_events vessel relationship ID in raw_data.';

-- ============================================================================
-- SCHEMA VERSION TRACKING
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('1.7.1', 'Add p_t49_vessel_id filter to get_container_tracking_summary and get_shipment_kpis')
ON CONFLICT (version) DO NOTHING;
