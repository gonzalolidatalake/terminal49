CREATE INDEX IF NOT EXISTS idx_events_vessel_id 
ON container_events (
  (raw_data->'relationships'->'vessel'->'data'->>'id')
) 
WHERE raw_data->'relationships'->'vessel'->'data'->>'id' IS NOT NULL;

ANALYZE container_events;

-- This index will improve the performance of queries that filter or join on the vessel ID extracted from the raw_data JSONB column. By indexing this specific path, we can speed up lookups for active vessels in the container_events table.

DROP FUNCTION get_active_vessel_summary(integer, integer);

CREATE OR REPLACE FUNCTION get_active_vessel_summary(
  p_event_window_days integer DEFAULT 30,
  p_activity_window_days integer DEFAULT 7
)
RETURNS TABLE(
  vessel_id text,
  container_id uuid,
  shipment_id uuid,
  equipment_length integer,
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
  SELECT * FROM vessel_container_data;
$$;

-- This function retrieves a summary of active vessels based on events within a specified time window. It identifies vessels that have had events in the last 'p_event_window_days' and checks for recent activity within 'p_activity_window_days'. The result includes vessel ID, container ID, shipment ID, equipment length, and shipping line SCAC.