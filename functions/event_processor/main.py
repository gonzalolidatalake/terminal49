"""
Event Processor Cloud Function

Processes Terminal49 webhook events from Pub/Sub.
Transforms data and writes to Supabase and BigQuery.

Triggered by: Pub/Sub subscription to terminal49-webhook-events topic
Timeout: 120 seconds
Memory: 512MB
"""

import functions_framework
import base64
import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional

from database import get_db_connection
from transformers import transform_event
from bigquery_archiver import archive_raw_event

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@functions_framework.cloud_event
def process_webhook_event(cloud_event):
    """
    Processes Terminal49 webhook events from Pub/Sub.
    
    This function:
    1. Decodes the Pub/Sub message
    2. Archives raw event to BigQuery
    3. Transforms and writes data to Supabase
    4. Handles errors with retry logic
    
    Args:
        cloud_event: CloudEvent containing Pub/Sub message
        
    Raises:
        Exception: On processing failure (triggers Pub/Sub retry)
    """
    start_time = datetime.utcnow()
    
    # Extract message data and attributes
    try:
        message_data = base64.b64decode(cloud_event.data["message"]["data"])
        payload = json.loads(message_data)
        
        attributes = cloud_event.data["message"].get("attributes", {})
        event_type = attributes.get('event_type', 'unknown')
        request_id = attributes.get('request_id', 'unknown')
        
        logger.info(
            "Processing event started",
            extra={
                'request_id': request_id,
                'event_type': event_type,
                'message_id': cloud_event.data["message"]["messageId"]
            }
        )
        
    except (KeyError, json.JSONDecodeError) as e:
        logger.error(
            "Failed to decode Pub/Sub message",
            extra={
                'error': str(e),
                'error_type': type(e).__name__
            }
        )
        # Don't retry for malformed messages
        return
    
    # Extract notification ID for idempotency
    notification_id = _extract_notification_id(payload)
    
    try:
        # Step 1: Archive raw event to BigQuery (always do this first)
        archive_raw_event(
            payload=payload,
            event_type=event_type,
            request_id=request_id,
            notification_id=notification_id
        )
        logger.info(
            "Raw event archived to BigQuery",
            extra={'request_id': request_id, 'notification_id': notification_id}
        )
        
        # Step 2: Transform and write to Supabase
        with get_db_connection() as conn:
            transform_event(
                payload=payload,
                event_type=event_type,
                notification_id=notification_id,
                conn=conn
            )
        
        # Calculate processing duration
        duration_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        logger.info(
            "Event processed successfully",
            extra={
                'request_id': request_id,
                'event_type': event_type,
                'notification_id': notification_id,
                'duration_ms': duration_ms
            }
        )
        
    except Exception as e:
        duration_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        logger.error(
            "Event processing failed",
            extra={
                'request_id': request_id,
                'event_type': event_type,
                'notification_id': notification_id,
                'error': str(e),
                'error_type': type(e).__name__,
                'duration_ms': duration_ms
            },
            exc_info=True
        )
        
        # Re-raise to trigger Pub/Sub retry
        raise


def _extract_notification_id(payload: Dict[str, Any]) -> Optional[str]:
    """
    Extracts notification ID from Terminal49 webhook payload.
    
    Args:
        payload: Webhook payload dictionary
        
    Returns:
        Notification ID string or None if not found
    """
    try:
        # Terminal49 notification ID is in data.id
        return payload.get('data', {}).get('id')
    except (AttributeError, TypeError):
        return None
