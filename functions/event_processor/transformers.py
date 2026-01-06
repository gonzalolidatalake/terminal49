"""
Event Transformers Module

Transforms Terminal49 webhook events into database operations.
Handles all event types with appropriate extraction and storage logic.
"""

import logging
from typing import Dict, Any, List, Optional
from database_operations import (
    upsert_shipment,
    upsert_container,
    insert_container_event,
    upsert_tracking_request,
    record_webhook_delivery
)

logger = logging.getLogger(__name__)


def transform_event(
    payload: Dict[str, Any],
    event_type: str,
    notification_id: Optional[str],
    conn
) -> None:
    """
    Main event transformation dispatcher.
    
    Routes events to appropriate handler based on event type.
    
    Args:
        payload: Raw webhook payload
        event_type: Event type from message attributes
        notification_id: Terminal49 notification ID
        conn: Database connection
        
    Raises:
        ValueError: If event type is unknown or payload is invalid
    """
    # Record webhook delivery
    try:
        record_webhook_delivery(
            notification_id=notification_id,
            event_type=event_type,
            payload=payload,
            processing_status='processing',
            processing_error=None,
            conn=conn
        )
    except Exception as e:
        logger.warning(
            "Failed to record webhook delivery",
            extra={'notification_id': notification_id, 'error': str(e)}
        )
    
    # Route to appropriate handler
    try:
        if event_type.startswith('container.transport.'):
            _handle_container_transport_event(payload, conn)
            
        elif event_type == 'container.updated':
            _handle_container_updated_event(payload, conn)
            
        elif event_type == 'container.created':
            _handle_container_created_event(payload, conn)
            
        elif event_type.startswith('tracking_request.'):
            _handle_tracking_request_event(payload, conn)
            
        elif event_type == 'shipment.estimated.arrival':
            _handle_shipment_estimated_arrival_event(payload, conn)
            
        elif event_type == 'container.pickup_lfd.changed':
            _handle_container_pickup_lfd_changed_event(payload, conn)
            
        else:
            logger.warning(
                "Unknown event type, storing raw data only",
                extra={'event_type': event_type, 'notification_id': notification_id}
            )
            # Still record as completed even if we don't process it
        
        # Update webhook delivery status to completed
        record_webhook_delivery(
            notification_id=notification_id,
            event_type=event_type,
            payload=payload,
            processing_status='completed',
            processing_error=None,
            conn=conn
        )
        
    except Exception as e:
        # Record failure
        record_webhook_delivery(
            notification_id=notification_id,
            event_type=event_type,
            payload=payload,
            processing_status='failed',
            processing_error=str(e),
            conn=conn
        )
        raise


def _handle_container_transport_event(payload: Dict[str, Any], conn) -> None:
    """
    Handles container.transport.* events.
    
    These events contain transport_event, container, and shipment data.
    """
    included = payload.get('included', [])
    
    # Extract entities by type
    shipments = [i for i in included if i.get('type') == 'shipment']
    containers = [i for i in included if i.get('type') == 'container']
    transport_events = [i for i in included if i.get('type') == 'transport_event']
    
    logger.debug(
        "Processing container transport event",
        extra={
            'shipments_count': len(shipments),
            'containers_count': len(containers),
            'events_count': len(transport_events)
        }
    )
    
    # Process shipments first (foreign key dependency)
    shipment_ids = {}
    for shipment_data in shipments:
        t49_shipment_id = shipment_data.get('id')
        db_shipment_id = upsert_shipment(shipment_data, conn)
        shipment_ids[t49_shipment_id] = db_shipment_id
    
    # Process containers
    container_ids = {}
    for container_data in containers:
        t49_container_id = container_data.get('id')
        
        # Find related shipment
        relationships = container_data.get('relationships', {})
        shipment_rel = relationships.get('shipment', {}).get('data', {})
        t49_shipment_id = shipment_rel.get('id')
        
        db_shipment_id = shipment_ids.get(t49_shipment_id)
        db_container_id = upsert_container(container_data, db_shipment_id, conn)
        container_ids[t49_container_id] = db_container_id
    
    # Process transport events
    for event_data in transport_events:
        # Find related container
        relationships = event_data.get('relationships', {})
        container_rel = relationships.get('container', {}).get('data', {})
        t49_container_id = container_rel.get('id')
        
        db_container_id = container_ids.get(t49_container_id)
        
        # Find related shipment (may not always be present)
        shipment_rel = relationships.get('shipment', {}).get('data', {})
        t49_shipment_id = shipment_rel.get('id') if shipment_rel else None
        db_shipment_id = shipment_ids.get(t49_shipment_id) if t49_shipment_id else None
        
        if db_container_id:
            insert_container_event(event_data, db_container_id, db_shipment_id, conn)
        else:
            logger.warning(
                "Transport event missing container reference",
                extra={'event_id': event_data.get('id')}
            )


def _handle_container_updated_event(payload: Dict[str, Any], conn) -> None:
    """
    Handles container.updated events.
    
    Updates container attributes without creating new transport events.
    """
    included = payload.get('included', [])
    
    shipments = [i for i in included if i.get('type') == 'shipment']
    containers = [i for i in included if i.get('type') == 'container']
    
    logger.debug(
        "Processing container updated event",
        extra={
            'shipments_count': len(shipments),
            'containers_count': len(containers)
        }
    )
    
    # Process shipments
    shipment_ids = {}
    for shipment_data in shipments:
        t49_shipment_id = shipment_data.get('id')
        db_shipment_id = upsert_shipment(shipment_data, conn)
        shipment_ids[t49_shipment_id] = db_shipment_id
    
    # Process containers
    for container_data in containers:
        relationships = container_data.get('relationships', {})
        shipment_rel = relationships.get('shipment', {}).get('data', {})
        t49_shipment_id = shipment_rel.get('id')
        
        db_shipment_id = shipment_ids.get(t49_shipment_id)
        upsert_container(container_data, db_shipment_id, conn)


def _handle_container_created_event(payload: Dict[str, Any], conn) -> None:
    """
    Handles container.created events.
    
    Similar to container.updated but for new containers.
    """
    # Same logic as container.updated
    _handle_container_updated_event(payload, conn)


def _handle_tracking_request_event(payload: Dict[str, Any], conn) -> None:
    """
    Handles tracking_request.* events.
    
    Event types:
    - tracking_request.succeeded
    - tracking_request.failed
    - tracking_request.awaiting_manifest
    - tracking_request.tracking_stopped
    """
    data = payload.get('data', {})
    
    if data.get('type') == 'tracking_request':
        upsert_tracking_request(data, conn)
        
        logger.debug(
            "Processing tracking request event",
            extra={
                'tracking_request_id': data.get('id'),
                'status': data.get('attributes', {}).get('status')
            }
        )
    else:
        logger.warning(
            "Tracking request event missing data",
            extra={'payload_keys': list(payload.keys())}
        )


def _handle_shipment_estimated_arrival_event(payload: Dict[str, Any], conn) -> None:
    """
    Handles shipment.estimated.arrival events.
    
    Updates shipment ETA information.
    """
    included = payload.get('included', [])
    shipments = [i for i in included if i.get('type') == 'shipment']
    
    logger.debug(
        "Processing shipment estimated arrival event",
        extra={'shipments_count': len(shipments)}
    )
    
    for shipment_data in shipments:
        upsert_shipment(shipment_data, conn)


def _handle_container_pickup_lfd_changed_event(payload: Dict[str, Any], conn) -> None:
    """
    Handles container.pickup_lfd.changed events.
    
    Updates container Last Free Day (LFD) information.
    """
    included = payload.get('included', [])
    
    shipments = [i for i in included if i.get('type') == 'shipment']
    containers = [i for i in included if i.get('type') == 'container']
    
    logger.debug(
        "Processing container pickup LFD changed event",
        extra={
            'shipments_count': len(shipments),
            'containers_count': len(containers)
        }
    )
    
    # Process shipments
    shipment_ids = {}
    for shipment_data in shipments:
        t49_shipment_id = shipment_data.get('id')
        db_shipment_id = upsert_shipment(shipment_data, conn)
        shipment_ids[t49_shipment_id] = db_shipment_id
    
    # Process containers with updated LFD
    for container_data in containers:
        relationships = container_data.get('relationships', {})
        shipment_rel = relationships.get('shipment', {}).get('data', {})
        t49_shipment_id = shipment_rel.get('id')
        
        db_shipment_id = shipment_ids.get(t49_shipment_id)
        upsert_container(container_data, db_shipment_id, conn)


def extract_entities_by_type(
    included: List[Dict[str, Any]],
    entity_type: str
) -> List[Dict[str, Any]]:
    """
    Helper function to extract entities of a specific type from included array.
    
    Args:
        included: Included array from Terminal49 payload
        entity_type: Entity type to extract (e.g., 'shipment', 'container')
        
    Returns:
        List of entities matching the type
    """
    return [item for item in included if item.get('type') == entity_type]


def find_related_entity(
    entity: Dict[str, Any],
    relationship_name: str,
    entity_map: Dict[str, str]
) -> Optional[str]:
    """
    Helper function to find related entity ID from relationships.
    
    Args:
        entity: Entity with relationships
        relationship_name: Name of relationship (e.g., 'shipment', 'container')
        entity_map: Map of Terminal49 IDs to database IDs
        
    Returns:
        Database ID of related entity or None
    """
    relationships = entity.get('relationships', {})
    related = relationships.get(relationship_name, {}).get('data', {})
    t49_id = related.get('id')
    
    return entity_map.get(t49_id) if t49_id else None
