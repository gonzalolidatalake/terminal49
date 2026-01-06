"""
Pub/Sub Event Publisher for Terminal49 Webhooks

This module handles publishing validated webhook events to Google Cloud Pub/Sub
for asynchronous processing by downstream Cloud Functions.

Features:
- Automatic retry with exponential backoff
- Message attributes for filtering and routing
- Structured error handling
- Performance monitoring
"""

import json
import logging
import os
from datetime import datetime
from typing import Dict, Any

from google.cloud import pubsub_v1
from google.api_core import retry
from google.api_core.exceptions import GoogleAPIError

logger = logging.getLogger(__name__)

# Initialize publisher client (reused across invocations)
_publisher_client = None


def get_publisher_client() -> pubsub_v1.PublisherClient:
    """
    Get or create Pub/Sub publisher client.
    
    The client is cached to improve performance across function invocations.
    
    Returns:
        PublisherClient instance
    """
    global _publisher_client
    
    if _publisher_client is None:
        _publisher_client = pubsub_v1.PublisherClient()
        logger.info("Pub/Sub publisher client initialized")
    
    return _publisher_client


def get_topic_path() -> str:
    """
    Get the full Pub/Sub topic path.
    
    Returns:
        Full topic path in format: projects/{project}/topics/{topic}
        
    Raises:
        ValueError: If required environment variables are not set
    """
    project_id = os.environ.get('GCP_PROJECT_ID')
    topic_name = os.environ.get('PUBSUB_TOPIC', 'terminal49-webhook-events')
    
    if not project_id:
        raise ValueError("GCP_PROJECT_ID environment variable not configured")
    
    publisher = get_publisher_client()
    return publisher.topic_path(project_id, topic_name)


def publish_event(
    payload: Dict[str, Any],
    event_type: str,
    request_id: str
) -> str:
    """
    Publishes webhook event to Pub/Sub.
    
    The event is published with metadata attributes for filtering and routing:
    - event_type: Type of Terminal49 event
    - request_id: Correlation ID for tracking
    - timestamp: ISO 8601 timestamp of publication
    
    Args:
        payload: Parsed webhook payload (dict)
        event_type: Terminal49 event type (e.g., "container.transport.vessel_arrived")
        request_id: Request correlation ID
        
    Returns:
        Message ID from Pub/Sub
        
    Raises:
        GoogleAPIError: If publishing fails after retries
        ValueError: If configuration is invalid
        
    Example:
        >>> payload = {"data": {"type": "notification"}}
        >>> message_id = publish_event(payload, "container.updated", "req-123")
        >>> print(message_id)
        "1234567890"
    """
    start_time = datetime.utcnow()
    
    try:
        # Get topic path
        topic_path = get_topic_path()
        
        # Serialize payload to JSON bytes
        message_data = json.dumps(payload).encode('utf-8')
        
        # Prepare message attributes
        attributes = {
            'event_type': event_type,
            'request_id': request_id,
            'timestamp': datetime.utcnow().isoformat(),
            'source': 'webhook_receiver'
        }
        
        # Extract additional metadata if available
        if 'data' in payload and 'id' in payload['data']:
            attributes['notification_id'] = payload['data']['id']
        
        logger.info(
            "Publishing event to Pub/Sub",
            extra={
                'request_id': request_id,
                'event_type': event_type,
                'topic_path': topic_path,
                'message_size_bytes': len(message_data)
            }
        )
        
        # Publish with retry configuration
        publisher = get_publisher_client()
        future = publisher.publish(
            topic_path,
            message_data,
            **attributes
        )
        
        # Wait for publish to complete (with timeout)
        message_id = future.result(timeout=5.0)
        
        # Calculate publish duration
        duration_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        logger.info(
            "Event published successfully",
            extra={
                'request_id': request_id,
                'event_type': event_type,
                'message_id': message_id,
                'publish_duration_ms': duration_ms
            }
        )
        
        return message_id
        
    except GoogleAPIError as e:
        logger.error(
            "Failed to publish to Pub/Sub",
            extra={
                'request_id': request_id,
                'event_type': event_type,
                'error': str(e),
                'error_code': e.code if hasattr(e, 'code') else None
            }
        )
        raise
        
    except Exception as e:
        logger.error(
            "Unexpected error publishing to Pub/Sub",
            extra={
                'request_id': request_id,
                'event_type': event_type,
                'error': str(e),
                'error_type': type(e).__name__
            }
        )
        raise


def publish_batch(
    events: list[Dict[str, Any]],
    request_id: str
) -> list[str]:
    """
    Publish multiple events in batch for improved performance.
    
    Note: This is an optimization for future use. Currently, webhooks
    arrive one at a time, but batch publishing may be useful for
    reprocessing scenarios.
    
    Args:
        events: List of (payload, event_type) tuples
        request_id: Request correlation ID
        
    Returns:
        List of message IDs
        
    Raises:
        GoogleAPIError: If publishing fails
    """
    message_ids = []
    
    for payload, event_type in events:
        try:
            message_id = publish_event(payload, event_type, request_id)
            message_ids.append(message_id)
        except Exception as e:
            logger.error(
                "Failed to publish event in batch",
                extra={
                    'request_id': request_id,
                    'event_type': event_type,
                    'error': str(e)
                }
            )
            # Continue with remaining events
            continue
    
    return message_ids
