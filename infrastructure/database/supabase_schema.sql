-- Terminal49 Webhook Infrastructure - Supabase PostgreSQL Schema
-- Version: 1.0.0
-- Date: 2026-01-02
-- Description: Database schema for operational tracking data

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for additional UUID functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABLE: shipments
-- Description: Stores shipment-level information from Terminal49
-- ============================================================================
CREATE TABLE shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_shipment_id UUID NOT NULL UNIQUE,
    bill_of_lading_number VARCHAR(100),
    normalized_number VARCHAR(100),
    shipping_line_scac VARCHAR(10),
    port_of_lading_locode VARCHAR(10),
    port_of_discharge_locode VARCHAR(10),
    destination_locode VARCHAR(10),
    pod_vessel_name VARCHAR(255),
    pod_vessel_imo VARCHAR(20),
    pol_etd_at TIMESTAMPTZ,
    pol_atd_at TIMESTAMPTZ,
    pod_eta_at TIMESTAMPTZ,
    pod_ata_at TIMESTAMPTZ,
    destination_eta_at TIMESTAMPTZ,
    destination_ata_at TIMESTAMPTZ,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for shipments
CREATE INDEX idx_shipments_bol ON shipments(bill_of_lading_number);
CREATE INDEX idx_shipments_normalized ON shipments(normalized_number);
CREATE INDEX idx_shipments_scac ON shipments(shipping_line_scac);
CREATE INDEX idx_shipments_pol ON shipments(port_of_lading_locode);
CREATE INDEX idx_shipments_pod ON shipments(port_of_discharge_locode);
CREATE INDEX idx_shipments_created_at ON shipments(created_at DESC);
CREATE INDEX idx_shipments_updated_at ON shipments(updated_at DESC);

-- GIN index for JSONB queries
CREATE INDEX idx_shipments_raw_data ON shipments USING GIN(raw_data);

-- Comments
COMMENT ON TABLE shipments IS 'Stores shipment-level tracking information from Terminal49';
COMMENT ON COLUMN shipments.t49_shipment_id IS 'Terminal49 unique shipment identifier';
COMMENT ON COLUMN shipments.raw_data IS 'Complete raw JSON payload from Terminal49';

-- ============================================================================
-- TABLE: containers
-- Description: Stores container-level information linked to shipments
-- ============================================================================
CREATE TABLE containers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_container_id UUID NOT NULL UNIQUE,
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    number VARCHAR(20) NOT NULL,
    seal_number VARCHAR(50),
    equipment_type VARCHAR(10),
    equipment_length INTEGER,
    equipment_height VARCHAR(10),
    weight_in_lbs INTEGER,
    pod_arrived_at TIMESTAMPTZ,
    pod_discharged_at TIMESTAMPTZ,
    empty_terminated_at TIMESTAMPTZ,
    pickup_lfd TIMESTAMPTZ,
    pickup_appointment_at TIMESTAMPTZ,
    available_for_pickup BOOLEAN,
    holds_at_pod_terminal JSONB,
    fees_at_pod_terminal JSONB,
    current_status VARCHAR(100),
    location_locode VARCHAR(10),
    raw_data JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for containers
CREATE INDEX idx_containers_number ON containers(number);
CREATE INDEX idx_containers_t49_id ON containers(t49_container_id);
CREATE INDEX idx_containers_shipment_id ON containers(shipment_id);
CREATE INDEX idx_containers_status ON containers(current_status);
CREATE INDEX idx_containers_lfd ON containers(pickup_lfd);
CREATE INDEX idx_containers_available ON containers(available_for_pickup);
CREATE INDEX idx_containers_created_at ON containers(created_at DESC);
CREATE INDEX idx_containers_updated_at ON containers(updated_at DESC);

-- GIN index for JSONB queries
CREATE INDEX idx_containers_raw_data ON containers USING GIN(raw_data);
CREATE INDEX idx_containers_holds ON containers USING GIN(holds_at_pod_terminal);
CREATE INDEX idx_containers_fees ON containers USING GIN(fees_at_pod_terminal);

-- Comments
COMMENT ON TABLE containers IS 'Stores container-level tracking information from Terminal49';
COMMENT ON COLUMN containers.t49_container_id IS 'Terminal49 unique container identifier';
COMMENT ON COLUMN containers.pickup_lfd IS 'Last Free Day for pickup';
COMMENT ON COLUMN containers.holds_at_pod_terminal IS 'Array of holds preventing pickup';
COMMENT ON COLUMN containers.fees_at_pod_terminal IS 'Array of fees at terminal';

-- ============================================================================
-- TABLE: container_events
-- Description: Stores transport and status events for containers
-- ============================================================================
CREATE TABLE container_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_event_id UUID NOT NULL UNIQUE,
    container_id UUID NOT NULL REFERENCES containers(id) ON DELETE CASCADE,
    shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    event_timestamp TIMESTAMPTZ,
    location_locode VARCHAR(10),
    location_name VARCHAR(255),
    vessel_name VARCHAR(255),
    vessel_imo VARCHAR(20),
    voyage_number VARCHAR(50),
    data_source VARCHAR(50),
    raw_data JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for container_events
CREATE INDEX idx_events_t49_id ON container_events(t49_event_id);
CREATE INDEX idx_events_container_id ON container_events(container_id);
CREATE INDEX idx_events_shipment_id ON container_events(shipment_id);
CREATE INDEX idx_events_type ON container_events(event_type);
CREATE INDEX idx_events_timestamp ON container_events(event_timestamp DESC);
CREATE INDEX idx_events_location ON container_events(location_locode);
CREATE INDEX idx_events_created_at ON container_events(created_at DESC);

-- Composite index for common queries
CREATE INDEX idx_events_container_type_time ON container_events(container_id, event_type, event_timestamp DESC);

-- GIN index for JSONB queries
CREATE INDEX idx_events_raw_data ON container_events USING GIN(raw_data);

-- Comments
COMMENT ON TABLE container_events IS 'Stores transport and status events for containers (append-only)';
COMMENT ON COLUMN container_events.t49_event_id IS 'Terminal49 unique event identifier for idempotency';
COMMENT ON COLUMN container_events.data_source IS 'Source of event data: shipping_line, terminal, ais, etc.';

-- ============================================================================
-- TABLE: tracking_requests
-- Description: Stores tracking request information and status
-- ============================================================================
CREATE TABLE tracking_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_tracking_request_id UUID NOT NULL UNIQUE,
    request_number VARCHAR(100) NOT NULL,
    request_type VARCHAR(50) NOT NULL,
    scac VARCHAR(10) NOT NULL,
    status VARCHAR(50) NOT NULL,
    failed_reason TEXT,
    shipment_id UUID REFERENCES shipments(id) ON DELETE SET NULL,
    ref_numbers JSONB,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for tracking_requests
CREATE INDEX idx_tracking_requests_number ON tracking_requests(request_number);
CREATE INDEX idx_tracking_requests_t49_id ON tracking_requests(t49_tracking_request_id);
CREATE INDEX idx_tracking_requests_status ON tracking_requests(status);
CREATE INDEX idx_tracking_requests_scac ON tracking_requests(scac);
CREATE INDEX idx_tracking_requests_shipment_id ON tracking_requests(shipment_id);
CREATE INDEX idx_tracking_requests_created_at ON tracking_requests(created_at DESC);

-- GIN index for JSONB queries
CREATE INDEX idx_tracking_requests_raw_data ON tracking_requests USING GIN(raw_data);
CREATE INDEX idx_tracking_requests_ref_numbers ON tracking_requests USING GIN(ref_numbers);

-- Comments
COMMENT ON TABLE tracking_requests IS 'Stores tracking request lifecycle and status';
COMMENT ON COLUMN tracking_requests.request_type IS 'Type: bill_of_lading, booking_number, container';
COMMENT ON COLUMN tracking_requests.status IS 'Status: pending, created, failed, tracking_stopped';

-- ============================================================================
-- TABLE: webhook_deliveries
-- Description: Tracks webhook delivery and processing status
-- ============================================================================
CREATE TABLE webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    t49_notification_id UUID NOT NULL UNIQUE,
    event_type VARCHAR(100) NOT NULL,
    delivery_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    processing_status VARCHAR(50) NOT NULL DEFAULT 'received',
    processing_error TEXT,
    processing_duration_ms INTEGER,
    signature_valid BOOLEAN NOT NULL DEFAULT false,
    raw_payload JSONB NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- Indexes for webhook_deliveries
CREATE INDEX idx_webhook_deliveries_t49_id ON webhook_deliveries(t49_notification_id);
CREATE INDEX idx_webhook_deliveries_event_type ON webhook_deliveries(event_type);
CREATE INDEX idx_webhook_deliveries_delivery_status ON webhook_deliveries(delivery_status);
CREATE INDEX idx_webhook_deliveries_processing_status ON webhook_deliveries(processing_status);
CREATE INDEX idx_webhook_deliveries_received_at ON webhook_deliveries(received_at DESC);
CREATE INDEX idx_webhook_deliveries_processed_at ON webhook_deliveries(processed_at DESC);

-- Composite index for monitoring queries
CREATE INDEX idx_webhook_deliveries_status_received ON webhook_deliveries(processing_status, received_at DESC);

-- GIN index for JSONB queries
CREATE INDEX idx_webhook_deliveries_raw_payload ON webhook_deliveries USING GIN(raw_payload);

-- Comments
COMMENT ON TABLE webhook_deliveries IS 'Tracks webhook delivery and processing status for monitoring';
COMMENT ON COLUMN webhook_deliveries.delivery_status IS 'Status: pending, succeeded, failed';
COMMENT ON COLUMN webhook_deliveries.processing_status IS 'Status: received, processing, completed, failed';

-- ============================================================================
-- FUNCTIONS: Automatic timestamp updates
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic updated_at
CREATE TRIGGER update_shipments_updated_at
    BEFORE UPDATE ON shipments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_containers_updated_at
    BEFORE UPDATE ON containers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tracking_requests_updated_at
    BEFORE UPDATE ON tracking_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS: Useful queries for common operations
-- ============================================================================

-- View: Active shipments with container count
CREATE VIEW active_shipments_summary AS
SELECT 
    s.id,
    s.t49_shipment_id,
    s.bill_of_lading_number,
    s.shipping_line_scac,
    s.port_of_lading_locode,
    s.port_of_discharge_locode,
    s.pod_eta_at,
    s.pod_ata_at,
    COUNT(c.id) as container_count,
    s.created_at,
    s.updated_at
FROM shipments s
LEFT JOIN containers c ON c.shipment_id = s.id
GROUP BY s.id;

COMMENT ON VIEW active_shipments_summary IS 'Summary view of shipments with container counts';

-- View: Containers with latest event
CREATE VIEW containers_with_latest_event AS
SELECT 
    c.*,
    le.event_type as latest_event_type,
    le.event_timestamp as latest_event_timestamp,
    le.location_locode as latest_location
FROM containers c
LEFT JOIN LATERAL (
    SELECT event_type, event_timestamp, location_locode
    FROM container_events
    WHERE container_id = c.id
    ORDER BY event_timestamp DESC NULLS LAST
    LIMIT 1
) le ON true;

COMMENT ON VIEW containers_with_latest_event IS 'Containers with their most recent event information';

-- View: Webhook processing statistics
CREATE VIEW webhook_processing_stats AS
SELECT 
    event_type,
    processing_status,
    COUNT(*) as count,
    AVG(processing_duration_ms) as avg_duration_ms,
    MAX(processing_duration_ms) as max_duration_ms,
    DATE_TRUNC('hour', received_at) as hour
FROM webhook_deliveries
WHERE received_at > NOW() - INTERVAL '24 hours'
GROUP BY event_type, processing_status, DATE_TRUNC('hour', received_at)
ORDER BY hour DESC, event_type;

COMMENT ON VIEW webhook_processing_stats IS 'Webhook processing statistics for last 24 hours';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - Optional, configure based on requirements
-- ============================================================================

-- Enable RLS on tables (uncomment if needed)
-- ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE containers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE container_events ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE tracking_requests ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE webhook_deliveries ENABLE ROW LEVEL SECURITY;

-- Example policy: Allow service role full access
-- CREATE POLICY "Service role has full access" ON shipments
--     FOR ALL
--     TO service_role
--     USING (true)
--     WITH CHECK (true);

-- ============================================================================
-- GRANTS: Set appropriate permissions
-- ============================================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;

-- Grant table permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;

-- Grant sequence permissions
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;

-- Grant function permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Additional composite indexes for common query patterns
CREATE INDEX idx_containers_shipment_status ON containers(shipment_id, current_status);
CREATE INDEX idx_events_container_timestamp ON container_events(container_id, event_timestamp DESC);

-- ============================================================================
-- DATA RETENTION POLICY (Optional - implement via cron job or pg_cron)
-- ============================================================================

-- Example: Archive old events to BigQuery and delete from Supabase
-- This would be implemented as a scheduled job, not in schema

-- Function to identify old events for archival
CREATE OR REPLACE FUNCTION get_events_for_archival(days_old INTEGER DEFAULT 90)
RETURNS TABLE (
    id UUID,
    t49_event_id UUID,
    event_type VARCHAR,
    event_timestamp TIMESTAMPTZ,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ce.id,
        ce.t49_event_id,
        ce.event_type,
        ce.event_timestamp,
        ce.created_at
    FROM container_events ce
    WHERE ce.created_at < NOW() - (days_old || ' days')::INTERVAL
    ORDER BY ce.created_at ASC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_events_for_archival IS 'Returns events older than specified days for archival';

-- ============================================================================
-- SCHEMA VERSION TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description TEXT,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO schema_migrations (version, description) 
VALUES ('1.0.0', 'Initial schema creation with all core tables');

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
