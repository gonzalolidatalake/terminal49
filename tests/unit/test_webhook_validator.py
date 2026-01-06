"""
Unit tests for webhook signature validation.

Tests cover:
- Valid signature validation
- Invalid signature rejection
- Missing signature handling
- Malformed signature handling
- Constant-time comparison
- Environment variable configuration
"""

import pytest
import os
from unittest.mock import patch

# Import the module under test
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../functions/webhook_receiver'))

from webhook_validator import validate_signature, compute_signature, _is_valid_hex


class TestValidateSignature:
    """Test cases for validate_signature function."""
    
    @pytest.fixture
    def mock_secret(self):
        """Fixture to set webhook secret in environment."""
        test_secret = "test-webhook-secret-key"
        with patch.dict(os.environ, {'TERMINAL49_WEBHOOK_SECRET': test_secret}):
            yield test_secret
    
    def test_valid_signature(self, mock_secret):
        """Test that a valid signature is accepted."""
        body = '{"data": {"type": "notification", "id": "123"}}'
        signature = compute_signature(body, mock_secret)
        
        assert validate_signature(body, signature) is True
    
    def test_invalid_signature(self, mock_secret):
        """Test that an invalid signature is rejected."""
        body = '{"data": {"type": "notification"}}'
        invalid_signature = "0" * 64  # Wrong signature
        
        assert validate_signature(body, invalid_signature) is False
    
    def test_missing_signature(self, mock_secret):
        """Test that missing signature is rejected."""
        body = '{"data": {"type": "notification"}}'
        
        assert validate_signature(body, None) is False
        assert validate_signature(body, "") is False
    
    def test_malformed_signature(self, mock_secret):
        """Test that malformed signature is rejected."""
        body = '{"data": {"type": "notification"}}'
        
        # Non-hex characters
        assert validate_signature(body, "not-a-hex-string") is False
        
        # Too short
        assert validate_signature(body, "abc123") is False
        
        # Special characters
        assert validate_signature(body, "abc!@#$%^&*()") is False
    
    def test_modified_body_invalidates_signature(self, mock_secret):
        """Test that modifying the body invalidates the signature."""
        original_body = '{"data": {"type": "notification"}}'
        signature = compute_signature(original_body, mock_secret)
        
        # Modify body slightly
        modified_body = '{"data": {"type": "notification", "extra": "field"}}'
        
        assert validate_signature(modified_body, signature) is False
    
    def test_whitespace_sensitivity(self, mock_secret):
        """Test that signature validation is sensitive to whitespace."""
        body_with_spaces = '{"data": {"type": "notification"}}'
        body_without_spaces = '{"data":{"type":"notification"}}'
        
        signature = compute_signature(body_with_spaces, mock_secret)
        
        # Same signature should not work with different whitespace
        assert validate_signature(body_with_spaces, signature) is True
        assert validate_signature(body_without_spaces, signature) is False
    
    def test_missing_secret_raises_error(self):
        """Test that missing webhook secret raises ValueError."""
        body = '{"data": {"type": "notification"}}'
        signature = "a" * 64
        
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(ValueError, match="TERMINAL49_WEBHOOK_SECRET not configured"):
                validate_signature(body, signature)
    
    def test_empty_body(self, mock_secret):
        """Test validation with empty body."""
        empty_body = ""
        signature = compute_signature(empty_body, mock_secret)
        
        assert validate_signature(empty_body, signature) is True
    
    def test_large_payload(self, mock_secret):
        """Test validation with large payload."""
        # Create a large payload (10KB)
        large_body = '{"data": "' + ("x" * 10000) + '"}'
        signature = compute_signature(large_body, mock_secret)
        
        assert validate_signature(large_body, signature) is True
    
    def test_unicode_characters(self, mock_secret):
        """Test validation with unicode characters in body."""
        unicode_body = '{"data": {"message": "Hello 世界 🌍"}}'
        signature = compute_signature(unicode_body, mock_secret)
        
        assert validate_signature(unicode_body, signature) is True
    
    def test_case_sensitivity(self, mock_secret):
        """Test that signature comparison is case-sensitive."""
        body = '{"data": {"type": "notification"}}'
        signature = compute_signature(body, mock_secret)
        
        # Uppercase signature should fail
        assert validate_signature(body, signature.upper()) is False


class TestIsValidHex:
    """Test cases for _is_valid_hex helper function."""
    
    def test_valid_hex_strings(self):
        """Test that valid hex strings are recognized."""
        assert _is_valid_hex("abc123") is True
        assert _is_valid_hex("ABCDEF") is True
        assert _is_valid_hex("0123456789abcdef") is True
        assert _is_valid_hex("a" * 64) is True  # SHA256 length
    
    def test_invalid_hex_strings(self):
        """Test that invalid hex strings are rejected."""
        assert _is_valid_hex("xyz") is False
        assert _is_valid_hex("abc!@#") is False
        assert _is_valid_hex("hello world") is False
        assert _is_valid_hex("") is False
        assert _is_valid_hex(None) is False
    
    def test_mixed_case_hex(self):
        """Test that mixed case hex strings are valid."""
        assert _is_valid_hex("AbCdEf123") is True


class TestComputeSignature:
    """Test cases for compute_signature helper function."""
    
    def test_compute_signature_deterministic(self):
        """Test that compute_signature produces consistent results."""
        body = '{"test": "data"}'
        secret = "my-secret"
        
        sig1 = compute_signature(body, secret)
        sig2 = compute_signature(body, secret)
        
        assert sig1 == sig2
    
    def test_compute_signature_different_secrets(self):
        """Test that different secrets produce different signatures."""
        body = '{"test": "data"}'
        
        sig1 = compute_signature(body, "secret1")
        sig2 = compute_signature(body, "secret2")
        
        assert sig1 != sig2
    
    def test_compute_signature_format(self):
        """Test that computed signature is valid hex."""
        body = '{"test": "data"}'
        secret = "my-secret"
        
        signature = compute_signature(body, secret)
        
        # Should be 64 character hex string (SHA256)
        assert len(signature) == 64
        assert _is_valid_hex(signature)
    
    def test_compute_signature_empty_inputs(self):
        """Test signature computation with empty inputs."""
        # Empty body
        sig1 = compute_signature("", "secret")
        assert len(sig1) == 64
        
        # Empty secret
        sig2 = compute_signature("body", "")
        assert len(sig2) == 64


class TestSecurityProperties:
    """Test security properties of signature validation."""
    
    @pytest.fixture
    def mock_secret(self):
        """Fixture to set webhook secret in environment."""
        test_secret = "test-webhook-secret-key"
        with patch.dict(os.environ, {'TERMINAL49_WEBHOOK_SECRET': test_secret}):
            yield test_secret
    
    def test_timing_attack_resistance(self, mock_secret):
        """
        Test that validation uses constant-time comparison.
        
        Note: This is a basic test. True timing attack resistance
        requires specialized testing tools.
        """
        body = '{"data": {"type": "notification"}}'
        correct_signature = compute_signature(body, mock_secret)
        
        # Create signatures that differ at different positions
        wrong_sig_start = "0" + correct_signature[1:]
        wrong_sig_middle = correct_signature[:32] + "0" + correct_signature[33:]
        wrong_sig_end = correct_signature[:-1] + "0"
        
        # All should be rejected (constant-time comparison)
        assert validate_signature(body, wrong_sig_start) is False
        assert validate_signature(body, wrong_sig_middle) is False
        assert validate_signature(body, wrong_sig_end) is False
    
    def test_signature_not_logged(self, mock_secret, caplog):
        """Test that signatures are not logged in error messages."""
        body = '{"data": {"type": "notification"}}'
        invalid_signature = "a" * 64
        
        with caplog.at_level("WARNING"):
            validate_signature(body, invalid_signature)
        
        # Check that signature value is not in logs
        for record in caplog.records:
            assert invalid_signature not in record.message
    
    def test_secret_not_exposed_in_errors(self, mock_secret):
        """Test that secret is never exposed in error messages."""
        body = '{"data": {"type": "notification"}}'
        signature = "invalid"
        
        try:
            validate_signature(body, signature)
        except Exception as e:
            assert mock_secret not in str(e)


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
