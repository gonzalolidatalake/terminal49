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


def archive_raw_event(
    payload: Dict[str, Any],
    event_type: str,
    request_id: str,
    notification_id: Optional[str] = None,
    signature_valid: bool = True
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
        
    Raises:
        google.api_core.exceptions.GoogleAPIError: On BigQuery errors
    """
    client = _get_bigquery_client()
    
    # Get configuration
    project_id = os.environ.get('GCP_PROJECT_ID')
    dataset_id = os.environ.get('BIGQUERY_DATASET_ID', 'terminal49_webhooks')
    table_id = 'raw_events_archive'
    
    if not project_id:
        raise ValueError("GCP_PROJECT_ID environment variable not set")
    
    # Construct table reference
    table_ref = f"{project_id}.{dataset_id}.{table_id}"
    
    # Prepare row for insertion
    row = {
        'event_id': notification_id or request_id,
        'received_at': datetime.utcnow().isoformat(),
        'event_type': event_type,
        'payload': payload,  # BigQuery handles JSON serialization
        'signature_valid': signature_valid,
        'request_id': request_id,
        'processing_duration_ms': None  # Will be updated later if needed
    }
    
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
    dataset_id = os.environ.get('BIGQUERY_DATASET_ID', 'terminal49_webhooks')
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
    dataset_id = os.environ.get('BIGQUERY_DATASET_ID', 'terminal49_webhooks')
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
