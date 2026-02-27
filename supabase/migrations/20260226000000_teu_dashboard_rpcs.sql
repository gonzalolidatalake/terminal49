-- Terminal49 Webhook Infrastructure - TEU Dashboard RPCs
-- Version: 1.3.0
-- Date: 2026-02-26
-- Description: Three RPCs to power the TEU dashboard: stacked bar chart series,
--              carrier breakdown table, and filter dropdown options.
--              Includes a shared TEU helper function and the pol_etd_at index.
--
-- Run this in the Supabase SQL Editor (or via psql) once.
-- Prerequisites: supabase_schema.sql (001) and tracking_summary_rpc (1.2.0) must
--               already be applied.

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Date range filtering on pol_etd_at is the primary predicate for all three RPCs.
-- idx_shipments_scac and idx_containers_shipment_id already exist in the base schema.
CREATE INDEX IF NOT EXISTS idx_shipments_pol_etd_at
    ON shipments(pol_etd_at);

-- ============================================================================
-- HELPER FUNCTION: teu_from_equipment_type
-- ============================================================================
-- Converts equipment_type to TEU count using standard ISO rules:
--   20-foot types (20GP, 20DRY, …) → 1 TEU
--   40-foot types (40HC, 40GP, 40DRY, 40NOR, …) → 2 TEUs
--   Unknown / NULL → 1 TEU (safe default)
--
-- Declared IMMUTABLE + PARALLEL SAFE so the planner can inline it freely
-- and parallelize queries that call it.
CREATE OR REPLACE FUNCTION teu_from_equipment_type(p_equipment_type TEXT)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT CASE
        WHEN p_equipment_type LIKE '40%' THEN 2
        ELSE 1
    END::NUMERIC;
$$;

COMMENT ON FUNCTION teu_from_equipment_type(TEXT) IS
    'Converts equipment_type to TEU count. 40-foot types → 2 TEU; all others (20-foot, '
    'unknown, NULL) → 1 TEU. Used as shared logic across all TEU dashboard RPCs.';

-- ============================================================================
-- RPC 1: get_teu_series_by_carrier
-- ============================================================================
-- Returns actual TEU data bucketed by time period and carrier.
-- Powers the stacked bar chart on the TEU dashboard.
--
-- Parameters:
--   p_start      - start of date range, inclusive, matched against pol_etd_at
--   p_end        - end of date range, inclusive
--   p_period     - aggregation granularity: 'week' | 'month' | 'quarter' (default 'week')
--                  'week' truncates to Monday (standard PostgreSQL DATE_TRUNC behaviour)
--   p_carrier    - array of shipping_line_scac values to include; NULL = all carriers
--   p_pol_locode - port-of-lading LOCODE filter; NULL = all
--   p_pod_locode - port-of-discharge LOCODE filter; NULL = all
--
-- Usage (Supabase JS):
--   const { data } = await supabase.rpc('get_teu_series_by_carrier', {
--     p_start: '2025-01-01', p_end: '2025-12-31', p_period: 'month'
--   })
-- ============================================================================

CREATE OR REPLACE FUNCTION get_teu_series_by_carrier(
    p_start      DATE,
    p_end        DATE,
    p_period     TEXT   DEFAULT 'week',
    p_carrier    TEXT[] DEFAULT NULL,
    p_pol_locode TEXT   DEFAULT NULL,
    p_pod_locode TEXT   DEFAULT NULL
)
RETURNS TABLE (
    bucket_date DATE,
    carrier     TEXT,
    teus        NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE_TRUNC(p_period, s.pol_etd_at)::DATE         AS bucket_date,
        s.shipping_line_scac::TEXT                        AS carrier,
        SUM(c.equipment_length/20)    AS teus
    FROM shipments s
    JOIN containers c ON c.shipment_id = s.id
    WHERE
        s.pol_etd_at::DATE BETWEEN p_start AND p_end
        AND (p_carrier    IS NULL OR s.shipping_line_scac       = ANY(p_carrier))
        AND (p_pol_locode IS NULL OR s.port_of_lading_locode    = p_pol_locode)
        AND (p_pod_locode IS NULL OR s.port_of_discharge_locode = p_pod_locode)
    GROUP BY
        DATE_TRUNC(p_period, s.pol_etd_at)::DATE,
        s.shipping_line_scac
    ORDER BY
        bucket_date ASC,
        teus DESC;
END;
$$;

COMMENT ON FUNCTION get_teu_series_by_carrier IS
    'Aggregates TEU data by time bucket and carrier for the stacked bar chart. '
    'TEUs are derived from equipment_length / 20. '
    'Supports week, month, and quarter bucketing; all filters are optional.';

-- ============================================================================
-- RPC 2: get_teu_breakdown
-- ============================================================================
-- Returns TEU totals, container count, and shipment count grouped by carrier.
-- Powers the breakdown table and pie chart on the TEU dashboard.
--
-- Parameters:
--   p_start      - start of date range (matched against pol_etd_at)
--   p_end        - end of date range
--   p_carrier    - array of SCACs to filter on; NULL = all
--   p_pol_locode - POL LOCODE filter; NULL = all
--   p_pod_locode - POD LOCODE filter; NULL = all
--
-- Usage (Supabase JS):
--   const { data } = await supabase.rpc('get_teu_breakdown', {
--     p_start: '2025-01-01', p_end: '2025-12-31'
--   })
-- ============================================================================

CREATE OR REPLACE FUNCTION get_teu_breakdown(
    p_start      DATE,
    p_end        DATE,
    p_carrier    TEXT[] DEFAULT NULL,
    p_pol_locode TEXT   DEFAULT NULL,
    p_pod_locode TEXT   DEFAULT NULL
)
RETURNS TABLE (
    carrier         TEXT,
    carrier_name    TEXT,
    teus            NUMERIC,
    container_count INTEGER,
    shipment_count  INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.shipping_line_scac::TEXT                                       AS carrier,
        -- MAX picks an arbitrary non-null carrier name from the group; all rows
        -- for the same SCAC should share the same shipping_line_name in practice.
        MAX(s.raw_data -> 'attributes' ->> 'shipping_line_name')::TEXT   AS carrier_name,
        SUM(c.equipment_length/20)                   AS teus,
        COUNT(DISTINCT c.id)::INTEGER                                    AS container_count,
        COUNT(DISTINCT s.id)::INTEGER                                    AS shipment_count
    FROM shipments s
    JOIN containers c ON c.shipment_id = s.id
    WHERE
        s.pol_etd_at::DATE BETWEEN p_start AND p_end
        AND (p_carrier    IS NULL OR s.shipping_line_scac       = ANY(p_carrier))
        AND (p_pol_locode IS NULL OR s.port_of_lading_locode    = p_pol_locode)
        AND (p_pod_locode IS NULL OR s.port_of_discharge_locode = p_pod_locode)
    GROUP BY s.shipping_line_scac
    ORDER BY teus DESC;
END;
$$;

COMMENT ON FUNCTION get_teu_breakdown IS
    'Aggregates TEU totals, container count, and shipment count per carrier '
    'for the dashboard breakdown table and pie chart. '
    'carrier_name is extracted from raw_data->attributes->shipping_line_name.';

-- ============================================================================
-- RPC 3: get_teu_filter_options
-- ============================================================================
-- Returns available distinct values for each dashboard filter dropdown,
-- scoped to the given date range so only relevant options are shown.
--
-- Uses a single base CTE scan (one join pass) and fans out per dimension
-- with UNION ALL — avoids 5× repeated table scans.
--
-- Parameters:
--   p_start - start of date range (matched against pol_etd_at)
--   p_end   - end of date range
--
-- Returns one row per dimension with a sorted array of non-null distinct values:
--   carrier          → distinct shipping_line_scac values
--   pol_locode       → distinct port_of_lading_locode values
--   pod_locode       → distinct port_of_discharge_locode values
--   equipment_type   → distinct containers.equipment_type values
--   container_status → distinct containers.current_status values
--
-- Usage (Supabase JS):
--   const { data } = await supabase.rpc('get_teu_filter_options', {
--     p_start: '2025-01-01', p_end: '2025-12-31'
--   })
-- ============================================================================

CREATE OR REPLACE FUNCTION get_teu_filter_options(
    p_start DATE,
    p_end   DATE
)
RETURNS TABLE (
    dimension      TEXT,
    filter_values  TEXT[]
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    RETURN QUERY
    WITH base AS (
        SELECT
            s.shipping_line_scac::TEXT       AS carrier,
            s.port_of_lading_locode::TEXT    AS pol_locode,
            s.port_of_discharge_locode::TEXT AS pod_locode,
            c.equipment_type::TEXT           AS equipment_type,
            c.current_status::TEXT           AS container_status
        FROM shipments s
        JOIN containers c ON c.shipment_id = s.id
        WHERE s.pol_etd_at::DATE BETWEEN p_start AND p_end
    )
    SELECT 'carrier'::TEXT,
           array_agg(DISTINCT carrier ORDER BY carrier)
               FILTER (WHERE carrier IS NOT NULL)
    FROM base

    UNION ALL

    SELECT 'pol_locode'::TEXT,
           array_agg(DISTINCT pol_locode ORDER BY pol_locode)
               FILTER (WHERE pol_locode IS NOT NULL)
    FROM base

    UNION ALL

    SELECT 'pod_locode'::TEXT,
           array_agg(DISTINCT pod_locode ORDER BY pod_locode)
               FILTER (WHERE pod_locode IS NOT NULL)
    FROM base

    UNION ALL

    SELECT 'equipment_type'::TEXT,
           array_agg(DISTINCT equipment_type ORDER BY equipment_type)
               FILTER (WHERE equipment_type IS NOT NULL)
    FROM base

    UNION ALL

    SELECT 'container_status'::TEXT,
           array_agg(DISTINCT container_status ORDER BY container_status)
               FILTER (WHERE container_status IS NOT NULL)
    FROM base;
END;
$$;

COMMENT ON FUNCTION get_teu_filter_options IS
    'Returns sorted distinct filter values per dimension (carrier, pol_locode, pod_locode, '
    'equipment_type, container_status) within the given date range. '
    'Uses a single base CTE scan for efficiency. Powers dashboard filter dropdowns.';

-- ============================================================================
-- SCHEMA VERSION TRACKING
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('1.3.0', 'Add TEU dashboard RPCs: teu_from_equipment_type helper, get_teu_series_by_carrier, get_teu_breakdown, get_teu_filter_options')
ON CONFLICT (version) DO NOTHING;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
