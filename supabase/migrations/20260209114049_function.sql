CREATE OR REPLACE FUNCTION get_active_vessel_summary(
  p_event_window_days INTEGER DEFAULT 30,
  p_activity_window_days INTEGER DEFAULT 7
)
RETURNS TABLE (
  vessel_id TEXT,
  container_id UUID,
  shipment_id UUID,
  equipment_length INTEGER,
  shipping_line_scac TEXT
)
LANGUAGE sql STABLE
AS $$
  WITH active_vessel_events AS (
    SELECT
      raw_data->'relationships'->'vessel'->'data'->>'id' AS vessel_id,
      container_id,
      shipment_id,
      event_timestamp
    FROM container_events
    WHERE created_at >= CURRENT_DATE - (p_event_window_days || ' days')::INTERVAL
      AND raw_data->'relationships'->'vessel'->'data'->>'id' IS NOT NULL
  ),
  vessels_with_recent_activity AS (
    SELECT vessel_id
    FROM active_vessel_events
    GROUP BY vessel_id
    HAVING MAX(event_timestamp) >= CURRENT_DATE - (p_activity_window_days || ' days')::INTERVAL
  ),
  vessel_container_data AS (
    SELECT DISTINCT
      ave.vessel_id,
      ave.container_id,
      ave.shipment_id,
      c.equipment_length,
      s.shipping_line_scac
    FROM active_vessel_events ave
    INNER JOIN vessels_with_recent_activity vra ON ave.vessel_id = vra.vessel_id
    LEFT JOIN containers c ON ave.container_id = c.id
    LEFT JOIN shipments s ON ave.shipment_id = s.id
  )
  SELECT * FROM vessel_container_data;
$$;