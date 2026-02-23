"""
Database Operations Module

Implements upsert and insert operations for Terminal49 entities.
All operations are idempotent using Terminal49 IDs.
"""

import logging
from typing import Dict, Any, Optional
from datetime import datetime
import json
import uuid

logger = logging.getLogger(__name__)


def upsert_shipment(shipment_data: Dict[str, Any], conn) -> str:
    """
    Upserts shipment data using Terminal49 shipment ID as unique key.
    
    Updates existing shipment if t49_shipment_id exists, otherwise inserts new.
    
    Args:
        shipment_data: Shipment attributes from Terminal49 payload
        conn: Database connection
        
    Returns:
        Shipment UUID (database primary key)
        
    Raises:
        psycopg2.Error: On database errors
    """
    cursor = conn.cursor()
    
    # Extract shipment attributes
    attrs = shipment_data.get('attributes', {})
    t49_id = shipment_data.get('id')
    
    if not t49_id:
        raise ValueError("Shipment data missing 'id' field")
    
    query = """
        INSERT INTO shipments (
            t49_shipment_id,
            bill_of_lading_number,
            normalized_number,
            shipping_line_scac,
            port_of_lading_locode,
            port_of_discharge_locode,
            destination_locode,
            pod_vessel_name,
            pod_vessel_imo,
            pol_etd_at,
            pol_atd_at,
            pod_eta_at,
            pod_ata_at,
            raw_data,
            created_at,
            updated_at
        ) VALUES (
            %(t49_id)s,
            %(bol)s,
            %(normalized)s,
            %(scac)s,
            %(pol)s,
            %(pod)s,
            %(destination)s,
            %(vessel_name)s,
            %(vessel_imo)s,
            %(pol_etd)s,
            %(pol_atd)s,
            %(pod_eta)s,
            %(pod_ata)s,
            %(raw_data)s,
            NOW(),
            NOW()
        )
        ON CONFLICT (t49_shipment_id) DO UPDATE SET
            bill_of_lading_number = EXCLUDED.bill_of_lading_number,
            normalized_number = EXCLUDED.normalized_number,
            shipping_line_scac = EXCLUDED.shipping_line_scac,
            port_of_lading_locode = EXCLUDED.port_of_lading_locode,
            port_of_discharge_locode = EXCLUDED.port_of_discharge_locode,
            destination_locode = EXCLUDED.destination_locode,
            pod_vessel_name = EXCLUDED.pod_vessel_name,
            pod_vessel_imo = EXCLUDED.pod_vessel_imo,
            pol_etd_at = EXCLUDED.pol_etd_at,
            pol_atd_at = EXCLUDED.pol_atd_at,
            pod_eta_at = EXCLUDED.pod_eta_at,
            pod_ata_at = EXCLUDED.pod_ata_at,
            raw_data = EXCLUDED.raw_data,
            updated_at = NOW()
        RETURNING id
    """
    
    params = {
        't49_id': t49_id,
        'bol': attrs.get('bill_of_lading_number'),
        'normalized': attrs.get('normalized_number'),
        'scac': attrs.get('shipping_line_scac'),
        'pol': attrs.get('port_of_lading_locode'),
        'pod': attrs.get('port_of_discharge_locode'),
        'destination': attrs.get('destination_locode'),
        'vessel_name': attrs.get('pod_vessel_name'),
        'vessel_imo': attrs.get('pod_vessel_imo'),
        'pol_etd': _parse_timestamp(attrs.get('pol_etd_at')),
        'pol_atd': _parse_timestamp(attrs.get('pol_atd_at')),
        'pod_eta': _parse_timestamp(attrs.get('pod_eta_at')),
        'pod_ata': _parse_timestamp(attrs.get('pod_ata_at')),
        'raw_data': json.dumps(shipment_data)
    }
    
    try:
        cursor.execute(query, params)
        result = cursor.fetchone()
        shipment_id = result[0]
        
        logger.debug(
            "Shipment upserted",
            extra={
                't49_shipment_id': t49_id,
                'shipment_id': str(shipment_id),
                'bol': params['bol']
            }
        )
        
        return str(shipment_id)
        
    except Exception as e:
        logger.error(
            "Failed to upsert shipment",
            extra={
                't49_shipment_id': t49_id,
                'error': str(e),
                'error_type': type(e).__name__
            },
            exc_info=True
        )
        raise


def upsert_container(
    container_data: Dict[str, Any],
    shipment_id: Optional[str],
    conn
) -> str:
    """
    Upserts container data using Terminal49 container ID as unique key.
    
    Args:
        container_data: Container attributes from Terminal49 payload
        shipment_id: Database shipment UUID (foreign key)
        conn: Database connection
        
    Returns:
        Container UUID (database primary key)
    """
    cursor = conn.cursor()
    
    attrs = container_data.get('attributes', {})
    t49_id = container_data.get('id')
    
    if not t49_id:
        raise ValueError("Container data missing 'id' field")
    
    query = """
        INSERT INTO containers (
            t49_container_id,
            shipment_id,
            number,
            seal_number,
            equipment_type,
            equipment_length,
            equipment_height,
            pod_arrived_at,
            pod_discharged_at,
            pickup_lfd,
            available_for_pickup,
            current_status,
            raw_data,
            created_at,
            updated_at
        ) VALUES (
            %(t49_id)s,
            %(shipment_id)s,
            %(number)s,
            %(seal_number)s,
            %(equipment_type)s,
            %(equipment_length)s,
            %(equipment_height)s,
            %(pod_arrived_at)s,
            %(pod_discharged_at)s,
            %(pickup_lfd)s,
            %(available_for_pickup)s,
            %(current_status)s,
            %(raw_data)s,
            NOW(),
            NOW()
        )
        ON CONFLICT (t49_container_id) DO UPDATE SET
            shipment_id = EXCLUDED.shipment_id,
            number = EXCLUDED.number,
            seal_number = EXCLUDED.seal_number,
            equipment_type = EXCLUDED.equipment_type,
            equipment_length = EXCLUDED.equipment_length,
            equipment_height = EXCLUDED.equipment_height,
            pod_arrived_at = EXCLUDED.pod_arrived_at,
            pod_discharged_at = EXCLUDED.pod_discharged_at,
            pickup_lfd = EXCLUDED.pickup_lfd,
            available_for_pickup = EXCLUDED.available_for_pickup,
            current_status = EXCLUDED.current_status,
            raw_data = EXCLUDED.raw_data,
            updated_at = NOW()
        RETURNING id
    """
    
    params = {
        't49_id': t49_id,
        'shipment_id': shipment_id,
        'number': attrs.get('number'),
        'seal_number': attrs.get('seal_number'),
        'equipment_type': attrs.get('equipment_type'),
        'equipment_length': attrs.get('equipment_length'),
        'equipment_height': attrs.get('equipment_height'),
        'pod_arrived_at': _parse_timestamp(attrs.get('pod_arrived_at')),
        'pod_discharged_at': _parse_timestamp(attrs.get('pod_discharged_at')),
        'pickup_lfd': _parse_timestamp(attrs.get('pickup_lfd')),
        'available_for_pickup': attrs.get('available_for_pickup'),
        'current_status': attrs.get('current_status', 'unknown'),
        'raw_data': json.dumps(container_data)
    }
    
    try:
        cursor.execute(query, params)
        result = cursor.fetchone()
        container_id = result[0]
        
        logger.debug(
            "Container upserted",
            extra={
                't49_container_id': t49_id,
                'container_id': str(container_id),
                'number': params['number']
            }
        )
        
        return str(container_id)
        
    except Exception as e:
        logger.error(
            "Failed to upsert container",
            extra={
                't49_container_id': t49_id,
                'error': str(e),
                'error_type': type(e).__name__
            },
            exc_info=True
        )
        raise


def insert_container_event(
    event_data: Dict[str, Any],
    container_id: str,
    shipment_id: Optional[str],
    conn
) -> Optional[str]:
    """
    Inserts container transport event (append-only, idempotent).
    
    Uses ON CONFLICT DO NOTHING for idempotency based on t49_event_id.
    
    Args:
        event_data: Transport event attributes from Terminal49 payload
        container_id: Database container UUID
        shipment_id: Database shipment UUID
        conn: Database connection
        
    Returns:
        Event UUID if inserted, None if duplicate
    """
    cursor = conn.cursor()
    
    attrs = event_data.get('attributes', {})
    t49_event_id = event_data.get('id')
    
    if not t49_event_id:
        raise ValueError("Event data missing 'id' field")
    
    query = """
        INSERT INTO container_events (
            t49_event_id,
            container_id,
            shipment_id,
            event_type,
            event_timestamp,
            location_locode,
            location_name,
            vessel_name,
            vessel_imo,
            voyage_number,
            data_source,
            raw_data,
            created_at
        ) VALUES (
            %(t49_event_id)s,
            %(container_id)s,
            %(shipment_id)s,
            %(event_type)s,
            %(event_timestamp)s,
            %(location_locode)s,
            %(location_name)s,
            %(vessel_name)s,
            %(vessel_imo)s,
            %(voyage_number)s,
            %(data_source)s,
            %(raw_data)s,
            NOW()
        )
        ON CONFLICT (t49_event_id) DO NOTHING
        RETURNING id
    """
    
    params = {
        't49_event_id': t49_event_id,
        'container_id': container_id,
        'shipment_id': shipment_id,
        'event_type': attrs.get('event'),
        'event_timestamp': _parse_timestamp(attrs.get('timestamp')),
        'location_locode': attrs.get('location_locode'),
        'location_name': attrs.get('location_name'),
        'vessel_name': attrs.get('vessel_name'),
        'vessel_imo': attrs.get('vessel_imo'),
        'voyage_number': attrs.get('voyage_number'),
        'data_source': attrs.get('data_source', 'unknown'),
        'raw_data': json.dumps(event_data)
    }
    
    try:
        cursor.execute(query, params)
        result = cursor.fetchone()
        
        if result:
            event_id = result[0]
            logger.debug(
                "Container event inserted",
                extra={
                    't49_event_id': t49_event_id,
                    'event_id': str(event_id),
                    'event_type': params['event_type']
                }
            )
            return str(event_id)
        else:
            logger.debug(
                "Container event already exists (duplicate)",
                extra={'t49_event_id': t49_event_id}
            )
            return None
            
    except Exception as e:
        logger.error(
            "Failed to insert container event",
            extra={
                't49_event_id': t49_event_id,
                'error': str(e),
                'error_type': type(e).__name__
            },
            exc_info=True
        )
        raise


def upsert_tracking_request(
    tracking_request_data: Dict[str, Any],
    conn
) -> str:
    """
    Upserts tracking request data.
    
    Args:
        tracking_request_data: Tracking request attributes from Terminal49
        conn: Database connection
        
    Returns:
        Tracking request UUID
    """
    cursor = conn.cursor()
    
    attrs = tracking_request_data.get('attributes', {})
    t49_id = tracking_request_data.get('id')
    
    if not t49_id:
        raise ValueError("Tracking request data missing 'id' field")
    
    query = """
        INSERT INTO tracking_requests (
            t49_tracking_request_id,
            request_number,
            request_type,
            scac,
            status,
            failed_reason,
            raw_data,
            created_at,
            updated_at
        ) VALUES (
            %(t49_id)s,
            %(request_number)s,
            %(request_type)s,
            %(scac)s,
            %(status)s,
            %(failed_reason)s,
            %(raw_data)s,
            NOW(),
            NOW()
        )
        ON CONFLICT (t49_tracking_request_id) DO UPDATE SET
            status = EXCLUDED.status,
            failed_reason = EXCLUDED.failed_reason,
            raw_data = EXCLUDED.raw_data,
            updated_at = NOW()
        RETURNING id
    """
    
    params = {
        't49_id': t49_id,
        'request_number': attrs.get('request_number'),
        'request_type': attrs.get('request_type'),
        'scac': attrs.get('scac'),
        'status': attrs.get('status', 'unknown'),
        'failed_reason': attrs.get('failed_reason'),
        'raw_data': json.dumps(tracking_request_data)
    }
    
    try:
        cursor.execute(query, params)
        result = cursor.fetchone()
        tracking_request_id = result[0]
        
        logger.debug(
            "Tracking request upserted",
            extra={
                't49_tracking_request_id': t49_id,
                'tracking_request_id': str(tracking_request_id),
                'status': params['status']
            }
        )
        
        return str(tracking_request_id)
        
    except Exception as e:
        logger.error(
            "Failed to upsert tracking request",
            extra={
                't49_tracking_request_id': t49_id,
                'error': str(e),
                'error_type': type(e).__name__
            },
            exc_info=True
        )
        raise


def record_webhook_delivery(
    notification_id: str,
    event_type: str,
    payload: Dict[str, Any],
    processing_status: str,
    processing_error: Optional[str],
    conn
) -> str:
    """
    Records webhook delivery for tracking and debugging.
    
    Args:
        notification_id: Terminal49 notification ID (will generate UUID if invalid)
        event_type: Event type
        payload: Raw webhook payload
        processing_status: Status (received, processing, completed, failed)
        processing_error: Error message if failed
        conn: Database connection
        
    Returns:
        Webhook delivery UUID
    """
    cursor = conn.cursor()
    
    # Validate and sanitize notification_id to ensure it's a valid UUID
    validated_notification_id = _validate_or_generate_uuid(notification_id)
    
    if validated_notification_id != notification_id:
        logger.warning(
            "Invalid notification_id format, generated UUID",
            extra={
                'original_notification_id': notification_id,
                'generated_uuid': validated_notification_id
            }
        )
    
    query = """
        INSERT INTO webhook_deliveries (
            t49_notification_id,
            event_type,
            delivery_status,
            processing_status,
            processing_error,
            raw_payload,
            received_at,
            processed_at
        ) VALUES (
            %(notification_id)s,
            %(event_type)s,
            'succeeded',
            %(processing_status)s,
            %(processing_error)s,
            %(raw_payload)s,
            NOW(),
            CASE WHEN %(processing_status)s IN ('completed', 'failed') 
                 THEN NOW() 
                 ELSE NULL 
            END
        )
        ON CONFLICT (t49_notification_id) DO UPDATE SET
            processing_status = EXCLUDED.processing_status,
            processing_error = EXCLUDED.processing_error,
            processed_at = EXCLUDED.processed_at
        RETURNING id
    """
    
    params = {
        'notification_id': validated_notification_id,
        'event_type': event_type,
        'processing_status': processing_status,
        'processing_error': processing_error,
        'raw_payload': json.dumps(payload)
    }
    
    try:
        cursor.execute(query, params)
        result = cursor.fetchone()
        delivery_id = result[0]
        
        logger.debug(
            "Webhook delivery recorded",
            extra={
                'notification_id': notification_id,
                'delivery_id': str(delivery_id),
                'processing_status': processing_status
            }
        )
        
        return str(delivery_id)
        
    except Exception as e:
        logger.error(
            "Failed to record webhook delivery",
            extra={
                'notification_id': notification_id,
                'error': str(e)
            },
            exc_info=True
        )
        raise


def _validate_or_generate_uuid(value: Optional[str]) -> str:
    """
    Validates if a string is a valid UUID, generates one if not.
    
    Args:
        value: String to validate as UUID
        
    Returns:
        Valid UUID string (original if valid, generated if not)
    """
    if not value:
        return str(uuid.uuid4())
    
    try:
        # Try to parse as UUID to validate format
        uuid.UUID(value)
        return value
    except (ValueError, AttributeError):
        # Invalid UUID format, generate a new one
        return str(uuid.uuid4())


def _parse_timestamp(timestamp_str: Optional[str]) -> Optional[datetime]:
    """
    Parses ISO 8601 timestamp string to datetime object.
    
    Args:
        timestamp_str: ISO 8601 timestamp string
        
    Returns:
        datetime object or None if invalid/missing
    """
    if not timestamp_str:
        return None
    
    try:
        # Handle various ISO 8601 formats
        # Terminal49 uses format: 2024-01-15T10:30:00Z
        if timestamp_str.endswith('Z'):
            timestamp_str = timestamp_str[:-1] + '+00:00'
        
        return datetime.fromisoformat(timestamp_str)
        
    except (ValueError, AttributeError) as e:
        logger.warning(
            "Failed to parse timestamp",
            extra={'timestamp': timestamp_str, 'error': str(e)}
        )
        return None
