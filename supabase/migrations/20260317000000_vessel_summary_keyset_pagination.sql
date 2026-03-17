DROP FUNCTION IF EXISTS get_active_vessel_summary(integer, integer);

CREATE OR REPLACE FUNCTION get_active_vessel_summary(
  p_event_window_days    integer DEFAULT 30,
  p_activity_window_days integer DEFAULT 7,
  p_limit                integer DEFAULT 100,
  p_cursor_vessel_id     text    DEFAULT NULL,
  p_cursor_container_id  uuid    DEFAULT NULL
)
RETURNS TABLE(
  vessel_id          text,
  container_id       uuid,
  shipment_id        uuid,
  equipment_length   integer,
  shipping_line_scac text
)
LANGUAGE sql
STABLE
AS $$
  WITH active_vessel_events AS (
    SELECT
      raw_data->'relationships'->'vessel'->'data'->>'id' AS vessel_id,
      ce.container_id,
      ce.shipment_id,
      ce.event_timestamp
    FROM container_events ce
    WHERE ce.created_at >= CURRENT_DATE - make_interval(days => p_event_window_days)
      AND raw_data->'relationships'->'vessel'->'data'->>'id' IS NOT NULL
  ),
  vessels_with_recent_activity AS (
    SELECT ave.vessel_id
    FROM active_vessel_events ave
    GROUP BY ave.vessel_id
    HAVING MAX(ave.event_timestamp) >= CURRENT_DATE - make_interval(days => p_activity_window_days)
  ),
  vessel_container_data AS (
    SELECT DISTINCT ON (ave.vessel_id, ave.container_id)
      ave.vessel_id,
      ave.container_id,
      ave.shipment_id,
      c.equipment_length,
      s.shipping_line_scac
    FROM active_vessel_events ave
    INNER JOIN vessels_with_recent_activity vra ON ave.vessel_id = vra.vessel_id
    LEFT JOIN containers c ON ave.container_id = c.id
    LEFT JOIN shipments s ON ave.shipment_id = s.id
    ORDER BY ave.vessel_id, ave.container_id, ave.event_timestamp DESC
  )
  SELECT *
  FROM vessel_container_data
  WHERE
    p_cursor_vessel_id IS NULL
    OR (vessel_id, container_id) > (p_cursor_vessel_id, p_cursor_container_id)
  ORDER BY vessel_id, container_id
  LIMIT p_limit;
$$;
