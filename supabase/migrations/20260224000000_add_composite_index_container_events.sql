-- Adds a composite partial index on (created_at, vessel_id expression) to support
-- the get_active_vessel_summary function, which filters on both columns simultaneously.
-- The previous index only covered the vessel_id expression, leaving the created_at
-- range filter to cause a full table scan.
CREATE INDEX IF NOT EXISTS idx_events_created_at_vessel_id
ON container_events (
  created_at,
  (raw_data->'relationships'->'vessel'->'data'->>'id')
)
WHERE raw_data->'relationships'->'vessel'->'data'->>'id' IS NOT NULL;

ANALYZE container_events;
