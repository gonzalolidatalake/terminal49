"""
HMAC-SHA256 Signature Validation for Terminal49 Webhooks

This module implements secure signature validation using HMAC-SHA256 to verify
that webhook requests are genuinely from Terminal49.

Security Features:
- Constant-time comparison to prevent timing attacks
- Validates signature format before computation
- Comprehensive error logging without exposing secrets
"""

import hmac
import hashlib
import os
import logging
from typing import Optional

logger = logging.getLogger(__name__)


def validate_signature(body: str, signature: Optional[str]) -> bool:
    """
    Validates Terminal49 webhook signature using HMAC-SHA256.
    
    Terminal49 sends the signature in the X-T49-Webhook-Signature header.
    The signature is computed as: HMAC-SHA256(webhook_secret, request_body)
    
    Args:
        body: Raw request body as string
        signature: X-T49-Webhook-Signature header value
        
    Returns:
        True if signature is valid, False otherwise
        
    Raises:
        ValueError: If TERMINAL49_WEBHOOK_SECRET is not configured
        
    Example:
        >>> body = '{"data": {"type": "notification"}}'
        >>> signature = "a1b2c3d4..."
        >>> validate_signature(body, signature)
        True
    """
    # Check if signature is provided
    if not signature:
        logger.warning("No signature provided in request")
        return False
    
    # Check if signature is a valid hex string
    if not _is_valid_hex(signature):
        logger.warning(
            "Invalid signature format",
            extra={'signature_length': len(signature)}
        )
        return False
    
    # Get webhook secret from environment
    secret = os.environ.get('TERMINAL49_WEBHOOK_SECRET')
    if not secret:
        logger.error("TERMINAL49_WEBHOOK_SECRET environment variable not configured")
        raise ValueError("TERMINAL49_WEBHOOK_SECRET not configured")
    
    # Compute HMAC-SHA256 signature
    try:
        computed_signature = hmac.new(
            secret.encode('utf-8'),
            body.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
    except Exception as e:
        logger.error(
            "Failed to compute signature",
            extra={'error': str(e)}
        )
        return False
    
    # Constant-time comparison to prevent timing attacks
    is_valid = hmac.compare_digest(computed_signature, signature)
    
    if not is_valid:
        logger.warning(
            "Signature mismatch",
            extra={
                'expected_length': len(computed_signature),
                'received_length': len(signature)
            }
        )
    
    return is_valid


def _is_valid_hex(value: str) -> bool:
    """
    Check if a string is a valid hexadecimal string.
    
    Args:
        value: String to validate
        
    Returns:
        True if valid hex string, False otherwise
    """
    if not value:
        return False
    
    try:
        int(value, 16)
        return True
    except ValueError:
        return False


def compute_signature(body: str, secret: str) -> str:
    """
    Compute HMAC-SHA256 signature for a given body and secret.
    
    This function is primarily used for testing and debugging.
    In production, signatures are validated, not computed.
    
    Args:
        body: Request body as string
        secret: Webhook secret key
        
    Returns:
        Hexadecimal signature string
        
    Example:
        >>> compute_signature('{"test": "data"}', 'my-secret')
        'a1b2c3d4e5f6...'
    """
    return hmac.new(
        secret.encode('utf-8'),
        body.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
