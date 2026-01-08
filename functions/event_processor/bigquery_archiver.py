"""
BigQuery Raw Event Archiver

Archives all raw webhook payloads to BigQuery for debugging and reprocessing.
"""

import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from google.cloud import bigquery
from google.api_core import exceptions

logger = logging.getLogger(__name__)

# Global BigQuery client (cached across function invocations)
_bigquery_client = None


def _get_bigquery_client():
    """
    Gets or creates the BigQuery client.
    
    Client is cached globally to reuse across function invocations.
    
    Returns:
        BigQuery client instance
    """
    global _bigquery_client
    
    if _bigquery_client is None:
        logger.info("Initializing BigQuery client")
        _bigquery_client = bigquery.Client()
    
    return _bigquery_client


def _extract_payload_fields(payload: Dict[str, Any], event_type: str) -> Dict[str, Any]:
    """
    Extracts key fields from Terminal49 webhook payload for BigQuery archival.
    
    Terminal49 webhook structure:
    {
        "data": {
            "id": "notification_id",
            "attributes": {
                "event": "event_type",
                "created_at": "timestamp"
            },
            "relationships": {
                "reference_object": {"data": {"id": "...", "type": "..."}}
            }
        },
        "included": [
            {"type": "shipment", "id": "...", "attributes": {...}},
            {"type": "container", "id": "...", "attributes": {...}},
            {"type": "transport_event", "id": "...", "attributes": {...}}
        ]
    }
    
    Args:
        payload: Raw webhook payload dictionary
        event_type: Event type string
        
    Returns:
        Dictionary with extracted fields
    """
    extracted = {
        'event_timestamp': None,
        'event_category': None,
        'shipment_id': None,
        'container_id': None,
        'tracking_request_id': None,
        'bill_of_lading': None,
        'container_number': None
    }
    
    try:
        # Extract notification data
        data = payload.get('data', {})
        
        # Extract event timestamp from attributes.created_at
        attributes = data.get('attributes', {})
        created_at = attributes.get('created_at')
        if created_at:
            extracted['event_timestamp'] = created_at
        
        # Determine event category from event type
        if event_type:
            if event_type.startswith('container.'):
                extracted['event_category'] = 'container'
            elif event_type.startswith('shipment.'):
                extracted['event_category'] = 'shipment'
            elif event_type.startswith('tracking_request.'):
                extracted['event_category'] = 'tracking_request'
            else:
                extracted['event_category'] = 'other'
        
        # Extract IDs from included objects
        included = payload.get('included', [])
        for item in included:
            item_type = item.get('type')
            item_id = item.get('id')
            item_attrs = item.get('attributes', {})
            
            if item_type == 'shipment' and item_id:
                extracted['shipment_id'] = item_id
                # Extract bill of lading from shipment attributes
                bol = item_attrs.get('bill_of_lading_number') or item_attrs.get('normalized_number')
                if bol:
                    extracted['bill_of_lading'] = bol
            
            elif item_type == 'container' and item_id:
                extracted['container_id'] = item_id
                # Extract container number from container attributes
                container_num = item_attrs.get('number')
                if container_num:
                    extracted['container_number'] = container_num
            
            elif item_type == 'tracking_request' and item_id:
                extracted['tracking_request_id'] = item_id
        
        # If no container/shipment in included, check relationships
        relationships = data.get('relationships', {})
        
        # Check reference_object for transport_event, container, or shipment
        ref_obj = relationships.get('reference_object', {}).get('data', {})
        if ref_obj:
            ref_type = ref_obj.get('type')
            ref_id = ref_obj.get('id')
            
            # For transport events, we need to look in included for the actual container/shipment
            if ref_type == 'transport_event':
                # Find the transport_event in included to get container/shipment references
                for item in included:
                    if item.get('type') == 'transport_event' and item.get('id') == ref_id:
                        te_relationships = item.get('relationships', {})
                        
                        # Extract container ID from transport event
                        container_ref = te_relationships.get('container', {}).get('data', {})
                        if container_ref and not extracted['container_id']:
                            extracted['container_id'] = container_ref.get('id')
                        
                        # Extract shipment ID from transport event
                        shipment_ref = te_relationships.get('shipment', {}).get('data', {})
                        if shipment_ref and not extracted['shipment_id']:
                            extracted['shipment_id'] = shipment_ref.get('id')
                        
                        break
        
        logger.debug(
            "Extracted payload fields",
            extra={
                'event_type': event_type,
                'extracted_fields': {k: v for k, v in extracted.items() if v is not None}
            }
        )
        
    except Exception as e:
        logger.warning(
            "Failed to extract some payload fields",
            extra={
                'event_type': event_type,
                'error': str(e),
                'error_type': type(e).__name__
            }
        )
    
    return extracted


def archive_raw_event(
    payload: Dict[str, Any],
    event_type: str,
    request_id: str,
    notification_id: Optional[str] = None,
    signature_valid: bool = True,
    signature_header: Optional[str] = None,
    source_ip: Optional[str] = None,
    user_agent: Optional[str] = None
) -> None:
    """
    Archives raw webhook event to BigQuery.
    
    This function performs a streaming insert to BigQuery for immediate availability.
    All events are archived regardless of processing success/failure.
    
    Args:
        payload: Raw webhook payload dictionary
        event_type: Event type from message attributes
        request_id: Request correlation ID
        notification_id: Terminal49 notification ID (for deduplication)
        signature_valid: Whether webhook signature was valid
        signature_header: Original webhook signature header
        source_ip: Source IP address of webhook request
        user_agent: User-Agent header from request
        
    Raises:
        google.api_core.exceptions.GoogleAPIError: On BigQuery errors
    """
    client = _get_bigquery_client()
    
    # Get configuration
    project_id = os.environ.get('GCP_PROJECT_ID')
    dataset_id = os.environ.get('BIGQUERY_DATASET_ID', os.environ.get('BIGQUERY_DATASET', 'terminal49_raw_events'))
    table_id = 'raw_events_archive'
    
    if not project_id:
        raise ValueError("GCP_PROJECT_ID environment variable not set")
    
    # Construct table reference
    table_ref = f"{project_id}.{dataset_id}.{table_id}"
    
    # Extract fields from Terminal49 payload
    extracted_fields = _extract_payload_fields(payload, event_type)
    
    # Prepare row for insertion
    # Note: BigQuery JSON type requires the payload to be serialized as a JSON string
    import json as json_module
    
    # Calculate payload size
    payload_json = json_module.dumps(payload)
    payload_size = len(payload_json.encode('utf-8'))
    
    row = {
        'event_id': notification_id or request_id,
        'notification_id': notification_id,
        'received_at': datetime.utcnow().isoformat(),
        'event_timestamp': extracted_fields.get('event_timestamp'),
        'event_type': event_type,
        'event_category': extracted_fields.get('event_category'),
        'payload': payload_json,  # Serialize dict to JSON string for BigQuery JSON type
        'payload_size_bytes': payload_size,
        'signature_valid': signature_valid,
        'signature_header': signature_header,
        'processing_status': 'received',  # Required field - set initial status
        'processing_duration_ms': None,  # Will be updated later if needed
        'processing_error': None,
        'processed_at': None,
        'request_id': request_id,
        'source_ip': source_ip,
        'user_agent': user_agent,
        'shipment_id': extracted_fields.get('shipment_id'),
        'container_id': extracted_fields.get('container_id'),
        'tracking_request_id': extracted_fields.get('tracking_request_id'),
        'bill_of_lading': extracted_fields.get('bill_of_lading'),
        'container_number': extracted_fields.get('container_number'),
        'reprocessing_count': 0,
        'last_reprocessed_at': None
    }
    
    # Log the row structure for debugging
    logger.debug(
        "Preparing BigQuery insert",
        extra={
            'request_id': request_id,
            'notification_id': notification_id,
            'payload_type': type(payload).__name__,
            'row_keys': list(row.keys())
        }
    )
    
    try:
        # Streaming insert (immediate availability, higher cost)
        # For production, consider batch inserts if latency is acceptable
        errors = client.insert_rows_json(table_ref, [row])
        
        if errors:
            # Log errors but don't fail processing
            logger.error(
                "BigQuery insert errors",
                extra={
                    'request_id': request_id,
                    'notification_id': notification_id,
                    'errors': errors
                }
            )
            # Raise exception to trigger retry
            raise exceptions.GoogleAPIError(
                f"Failed to insert row to BigQuery: {errors}"
            )
        
        logger.debug(
            "Raw event archived to BigQuery",
            extra={
                'request_id': request_id,
                'notification_id': notification_id,
                'table': table_ref
            }
        )
        
    except exceptions.GoogleAPIError as e:
        logger.error(
            "BigQuery archival failed",
            extra={
                'request_id': request_id,
                'notification_id': notification_id,
                'error': str(e),
                'error_type': type(e).__name__
            },
            exc_info=True
        )
        raise
    
    except Exception as e:
        logger.error(
            "Unexpected error during BigQuery archival",
            extra={
                'request_id': request_id,
                'notification_id': notification_id,
                'error': str(e),
                'error_type': type(e).__name__
            },
            exc_info=True
        )
        raise


def update_processing_duration(
    notification_id: str,
    duration_ms: int
) -> None:
    """
    Updates processing duration for an archived event.
    
    This is optional and can be called after successful processing.
    
    Args:
        notification_id: Terminal49 notification ID
        duration_ms: Processing duration in milliseconds
    """
    client = _get_bigquery_client()
    
    project_id = os.environ.get('GCP_PROJECT_ID')
    dataset_id = os.environ.get('BIGQUERY_DATASET_ID', os.environ.get('BIGQUERY_DATASET', 'terminal49_raw_events'))
    table_id = 'raw_events_archive'
    
    if not project_id:
        logger.warning("GCP_PROJECT_ID not set, skipping duration update")
        return
    
    query = f"""
        UPDATE `{project_id}.{dataset_id}.{table_id}`
        SET processing_duration_ms = @duration_ms
        WHERE event_id = @event_id
    """
    
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("duration_ms", "INT64", duration_ms),
            bigquery.ScalarQueryParameter("event_id", "STRING", notification_id),
        ]
    )
    
    try:
        query_job = client.query(query, job_config=job_config)
        query_job.result()  # Wait for completion
        
        logger.debug(
            "Processing duration updated in BigQuery",
            extra={
                'notification_id': notification_id,
                'duration_ms': duration_ms
            }
        )
        
    except Exception as e:
        # Don't fail if duration update fails
        logger.warning(
            "Failed to update processing duration",
            extra={
                'notification_id': notification_id,
                'error': str(e)
            }
        )


def query_raw_events(
    event_type: Optional[str] = None,
    start_time: Optional[datetime] = None,
    end_time: Optional[datetime] = None,
    limit: int = 100
) -> list:
    """
    Queries raw events from BigQuery for debugging/reprocessing.
    
    Args:
        event_type: Filter by event type
        start_time: Filter by received_at >= start_time
        end_time: Filter by received_at <= end_time
        limit: Maximum number of results
        
    Returns:
        List of event dictionaries
    """
    client = _get_bigquery_client()
    
    project_id = os.environ.get('GCP_PROJECT_ID')
    dataset_id = os.environ.get('BIGQUERY_DATASET_ID', os.environ.get('BIGQUERY_DATASET', 'terminal49_raw_events'))
    table_id = 'raw_events_archive'
    
    # Build query with filters
    where_clauses = []
    query_params = []
    
    if event_type:
        where_clauses.append("event_type = @event_type")
        query_params.append(
            bigquery.ScalarQueryParameter("event_type", "STRING", event_type)
        )
    
    if start_time:
        where_clauses.append("received_at >= @start_time")
        query_params.append(
            bigquery.ScalarQueryParameter(
                "start_time", "TIMESTAMP", start_time
            )
        )
    
    if end_time:
        where_clauses.append("received_at <= @end_time")
        query_params.append(
            bigquery.ScalarQueryParameter("end_time", "TIMESTAMP", end_time)
        )
    
    where_clause = " AND ".join(where_clauses) if where_clauses else "TRUE"
    
    query = f"""
        SELECT *
        FROM `{project_id}.{dataset_id}.{table_id}`
        WHERE {where_clause}
        ORDER BY received_at DESC
        LIMIT @limit
    """
    
    query_params.append(
        bigquery.ScalarQueryParameter("limit", "INT64", limit)
    )
    
    job_config = bigquery.QueryJobConfig(query_parameters=query_params)
    
    try:
        query_job = client.query(query, job_config=job_config)
        results = query_job.result()
        
        return [dict(row) for row in results]
        
    except Exception as e:
        logger.error(
            "Failed to query raw events",
            extra={'error': str(e)},
            exc_info=True
        )
        raise
