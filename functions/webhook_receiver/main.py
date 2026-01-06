"""
Terminal49 Webhook Receiver Cloud Function

This Cloud Function receives POST requests from Terminal49, validates HMAC-SHA256
signatures, and publishes events to Pub/Sub for asynchronous processing.

Environment Variables:
    TERMINAL49_WEBHOOK_SECRET: Secret key for HMAC signature validation
    GCP_PROJECT_ID: GCP project ID for Pub/Sub
    PUBSUB_TOPIC: Pub/Sub topic name (default: terminal49-webhook-events)
"""

import functions_framework
import json
import logging
import os
import uuid
from datetime import datetime
from typing import Tuple

from webhook_validator import validate_signature
from pubsub_publisher import publish_event

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def generate_request_id() -> str:
    """Generate a unique request ID for tracking."""
    return str(uuid.uuid4())


@functions_framework.http
def webhook_receiver(request):
    """
    Receives Terminal49 webhook notifications.
    Validates signature and publishes to Pub/Sub.
    
    Args:
        request: Flask request object
        
    Returns:
        Tuple of (response_body, status_code)
    """
    start_time = datetime.utcnow()
    request_id = request.headers.get('X-Request-ID', generate_request_id())
    
    # Handle health check endpoint
    if request.method == 'GET' and request.path == '/health':
        return handle_health_check(request_id)
    
    # Only accept POST requests for webhooks
    if request.method != 'POST':
        logger.warning(
            "Method not allowed",
            extra={
                'request_id': request_id,
                'method': request.method
            }
        )
        return ('Method Not Allowed', 405)
    
    # Log receipt
    logger.info(
        "Webhook received",
        extra={
            'request_id': request_id,
            'content_length': request.content_length,
            'content_type': request.content_type
        }
    )
    
    try:
        # Get raw body and signature
        signature = request.headers.get('X-T49-Webhook-Signature')
        body = request.get_data(as_text=True)
        
        if not body:
            logger.warning(
                "Empty request body",
                extra={'request_id': request_id}
            )
            return ('Bad Request: Empty body', 400)
        
        # Validate signature
        if not validate_signature(body, signature):
            logger.warning(
                "Invalid signature",
                extra={
                    'request_id': request_id,
                    'signature_present': bool(signature)
                }
            )
            return ('Unauthorized: Invalid signature', 401)
        
        # Parse payload
        try:
            payload = json.loads(body)
        except json.JSONDecodeError as e:
            logger.error(
                "Invalid JSON payload",
                extra={
                    'request_id': request_id,
                    'error': str(e),
                    'body_preview': body[:200]
                }
            )
            return ('Bad Request: Invalid JSON', 400)
        
        # Extract event type
        event_type = extract_event_type(payload)
        if not event_type:
            logger.warning(
                "Missing event type in payload",
                extra={
                    'request_id': request_id,
                    'payload_keys': list(payload.keys())
                }
            )
            return ('Bad Request: Missing event type', 400)
        
        # Publish to Pub/Sub
        try:
            message_id = publish_event(payload, event_type, request_id)
            
            # Calculate processing time
            duration_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
            
            logger.info(
                "Webhook processed successfully",
                extra={
                    'request_id': request_id,
                    'event_type': event_type,
                    'duration_ms': duration_ms,
                    'pubsub_message_id': message_id
                }
            )
            
            return ('OK', 200)
            
        except Exception as e:
            logger.error(
                "Failed to publish to Pub/Sub",
                extra={
                    'request_id': request_id,
                    'event_type': event_type,
                    'error': str(e)
                }
            )
            return ('Internal Server Error: Failed to queue event', 500)
        
    except Exception as e:
        logger.error(
            "Unexpected error processing webhook",
            extra={
                'request_id': request_id,
                'error': str(e),
                'error_type': type(e).__name__
            }
        )
        return ('Internal Server Error', 500)


def extract_event_type(payload: dict) -> str:
    """
    Extract event type from Terminal49 webhook payload.
    
    Terminal49 payloads follow JSON:API format:
    {
        "data": {
            "attributes": {
                "event": "container.transport.vessel_arrived"
            }
        }
    }
    
    Args:
        payload: Parsed JSON payload
        
    Returns:
        Event type string or empty string if not found
    """
    try:
        return payload.get('data', {}).get('attributes', {}).get('event', '')
    except (AttributeError, TypeError):
        return ''


def handle_health_check(request_id: str) -> Tuple[str, int]:
    """
    Handle health check endpoint.
    
    Checks:
    - Function is running
    - Environment variables are configured
    - Pub/Sub connectivity (basic check)
    
    Args:
        request_id: Request tracking ID
        
    Returns:
        Tuple of (response_body, status_code)
    """
    logger.info(
        "Health check requested",
        extra={'request_id': request_id}
    )
    
    health_status = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0',
        'checks': {}
    }
    
    # Check environment variables
    required_env_vars = [
        'TERMINAL49_WEBHOOK_SECRET',
        'GCP_PROJECT_ID'
    ]
    
    for var in required_env_vars:
        health_status['checks'][var] = 'configured' if os.environ.get(var) else 'missing'
    
    # Check Pub/Sub topic configuration
    pubsub_topic = os.environ.get('PUBSUB_TOPIC', 'terminal49-webhook-events')
    health_status['checks']['pubsub_topic'] = pubsub_topic
    
    # Determine overall health
    if any(status == 'missing' for status in health_status['checks'].values()):
        health_status['status'] = 'unhealthy'
        status_code = 503
    else:
        status_code = 200
    
    return (json.dumps(health_status, indent=2), status_code)
