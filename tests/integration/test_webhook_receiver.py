"""
Integration tests for Terminal49 webhook receiver Cloud Function.

Tests cover:
- End-to-end webhook processing
- Health check endpoint
- Error handling scenarios
- Pub/Sub integration
- Performance requirements
"""

import pytest
import json
import os
from unittest.mock import patch, MagicMock, Mock
from datetime import datetime

# Import the module under test
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../functions/webhook_receiver'))

from main import webhook_receiver, extract_event_type, handle_health_check
from webhook_validator import compute_signature


class MockRequest:
    """Mock Flask request object for testing."""
    
    def __init__(self, method='POST', path='/', headers=None, body='', content_type='application/json'):
        self.method = method
        self.path = path
        self.headers = headers or {}
        self._body = body
        self.content_type = content_type
        self.content_length = len(body)
    
    def get_data(self, as_text=False):
        """Mock get_data method."""
        return self._body if as_text else self._body.encode('utf-8')


class TestWebhookReceiver:
    """Integration tests for webhook_receiver function."""
    
    @pytest.fixture
    def mock_env(self):
        """Fixture to set up environment variables."""
        env_vars = {
            'TERMINAL49_WEBHOOK_SECRET': 'test-secret-key',
            'GCP_PROJECT_ID': 'test-project',
            'PUBSUB_TOPIC': 'terminal49-webhook-events'
        }
        with patch.dict(os.environ, env_vars):
            yield env_vars
    
    @pytest.fixture
    def sample_payload(self):
        """Fixture providing a sample Terminal49 webhook payload."""
        return {
            "data": {
                "id": "notif_123456",
                "type": "notification",
                "attributes": {
                    "event": "container.transport.vessel_arrived",
                    "occurred_at": "2024-01-15T10:30:00Z"
                }
            },
            "included": [
                {
                    "id": "cont_789",
                    "type": "container",
                    "attributes": {
                        "number": "ABCU1234567"
                    }
                }
            ]
        }
    
    @pytest.fixture
    def mock_pubsub(self):
        """Fixture to mock Pub/Sub publisher."""
        with patch('pubsub_publisher.get_publisher_client') as mock_client:
            mock_future = MagicMock()
            mock_future.result.return_value = "msg_123456"
            
            mock_publisher = MagicMock()
            mock_publisher.publish.return_value = mock_future
            mock_publisher.topic_path.return_value = "projects/test-project/topics/terminal49-webhook-events"
            
            mock_client.return_value = mock_publisher
            yield mock_publisher
    
    def test_successful_webhook_processing(self, mock_env, sample_payload, mock_pubsub):
        """Test successful webhook reception and processing."""
        body = json.dumps(sample_payload)
        signature = compute_signature(body, mock_env['TERMINAL49_WEBHOOK_SECRET'])
        
        request = MockRequest(
            method='POST',
            headers={
                'X-T49-Webhook-Signature': signature,
                'X-Request-ID': 'test-req-123'
            },
            body=body
        )
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 200
        assert response == 'OK'
        
        # Verify Pub/Sub was called
        assert mock_pubsub.publish.called
    
    def test_invalid_signature_rejected(self, mock_env, sample_payload, mock_pubsub):
        """Test that invalid signature is rejected."""
        body = json.dumps(sample_payload)
        invalid_signature = "0" * 64
        
        request = MockRequest(
            method='POST',
            headers={'X-T49-Webhook-Signature': invalid_signature},
            body=body
        )
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 401
        assert 'Unauthorized' in response
        
        # Verify Pub/Sub was NOT called
        assert not mock_pubsub.publish.called
    
    def test_missing_signature_rejected(self, mock_env, sample_payload, mock_pubsub):
        """Test that missing signature is rejected."""
        body = json.dumps(sample_payload)
        
        request = MockRequest(
            method='POST',
            headers={},
            body=body
        )
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 401
        assert 'Unauthorized' in response
    
    def test_invalid_json_rejected(self, mock_env, mock_pubsub):
        """Test that invalid JSON is rejected."""
        body = "not valid json {"
        signature = compute_signature(body, mock_env['TERMINAL49_WEBHOOK_SECRET'])
        
        request = MockRequest(
            method='POST',
            headers={'X-T49-Webhook-Signature': signature},
            body=body
        )
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 400
        assert 'Bad Request' in response
    
    def test_empty_body_rejected(self, mock_env, mock_pubsub):
        """Test that empty body is rejected."""
        request = MockRequest(
            method='POST',
            headers={'X-T49-Webhook-Signature': 'abc123'},
            body=''
        )
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 400
        assert 'Empty body' in response
    
    def test_missing_event_type_rejected(self, mock_env, mock_pubsub):
        """Test that payload without event type is rejected."""
        payload = {"data": {"type": "notification"}}  # Missing event attribute
        body = json.dumps(payload)
        signature = compute_signature(body, mock_env['TERMINAL49_WEBHOOK_SECRET'])
        
        request = MockRequest(
            method='POST',
            headers={'X-T49-Webhook-Signature': signature},
            body=body
        )
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 400
        assert 'Missing event type' in response
    
    def test_method_not_allowed(self, mock_env):
        """Test that non-POST methods are rejected (except GET for health)."""
        request = MockRequest(method='PUT', path='/')
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 405
        assert 'Method Not Allowed' in response
    
    def test_pubsub_failure_returns_500(self, mock_env, sample_payload):
        """Test that Pub/Sub failures return 500 error."""
        body = json.dumps(sample_payload)
        signature = compute_signature(body, mock_env['TERMINAL49_WEBHOOK_SECRET'])
        
        # Mock Pub/Sub to raise exception
        with patch('pubsub_publisher.publish_event') as mock_publish:
            mock_publish.side_effect = Exception("Pub/Sub unavailable")
            
            request = MockRequest(
                method='POST',
                headers={'X-T49-Webhook-Signature': signature},
                body=body
            )
            
            response, status_code = webhook_receiver(request)
            
            assert status_code == 500
            assert 'Internal Server Error' in response
    
    def test_request_id_tracking(self, mock_env, sample_payload, mock_pubsub):
        """Test that request ID is properly tracked."""
        body = json.dumps(sample_payload)
        signature = compute_signature(body, mock_env['TERMINAL49_WEBHOOK_SECRET'])
        custom_request_id = 'custom-req-456'
        
        request = MockRequest(
            method='POST',
            headers={
                'X-T49-Webhook-Signature': signature,
                'X-Request-ID': custom_request_id
            },
            body=body
        )
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 200
        
        # Verify request ID was passed to Pub/Sub
        call_args = mock_pubsub.publish.call_args
        assert call_args is not None
        # Check attributes passed to publish
        attributes = call_args[1]
        assert attributes.get('request_id') == custom_request_id
    
    def test_large_payload_handling(self, mock_env, mock_pubsub):
        """Test handling of large payloads."""
        # Create a large payload (100KB)
        large_payload = {
            "data": {
                "id": "notif_large",
                "type": "notification",
                "attributes": {
                    "event": "container.updated",
                    "data": "x" * 100000
                }
            }
        }
        
        body = json.dumps(large_payload)
        signature = compute_signature(body, mock_env['TERMINAL49_WEBHOOK_SECRET'])
        
        request = MockRequest(
            method='POST',
            headers={'X-T49-Webhook-Signature': signature},
            body=body
        )
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 200


class TestHealthCheck:
    """Tests for health check endpoint."""
    
    @pytest.fixture
    def mock_env(self):
        """Fixture to set up environment variables."""
        env_vars = {
            'TERMINAL49_WEBHOOK_SECRET': 'test-secret-key',
            'GCP_PROJECT_ID': 'test-project',
            'PUBSUB_TOPIC': 'terminal49-webhook-events'
        }
        with patch.dict(os.environ, env_vars):
            yield env_vars
    
    def test_health_check_healthy(self, mock_env):
        """Test health check returns healthy status."""
        request = MockRequest(method='GET', path='/health')
        
        response, status_code = webhook_receiver(request)
        
        assert status_code == 200
        
        health_data = json.loads(response)
        assert health_data['status'] == 'healthy'
        assert 'timestamp' in health_data
        assert 'version' in health_data
        assert 'checks' in health_data
    
    def test_health_check_missing_config(self):
        """Test health check returns unhealthy when config is missing."""
        with patch.dict(os.environ, {}, clear=True):
            request = MockRequest(method='GET', path='/health')
            
            response, status_code = webhook_receiver(request)
            
            assert status_code == 503
            
            health_data = json.loads(response)
            assert health_data['status'] == 'unhealthy'
    
    def test_health_check_includes_all_checks(self, mock_env):
        """Test that health check includes all required checks."""
        request = MockRequest(method='GET', path='/health')
        
        response, status_code = webhook_receiver(request)
        
        health_data = json.loads(response)
        checks = health_data['checks']
        
        assert 'TERMINAL49_WEBHOOK_SECRET' in checks
        assert 'GCP_PROJECT_ID' in checks
        assert 'pubsub_topic' in checks


class TestExtractEventType:
    """Tests for extract_event_type helper function."""
    
    def test_extract_valid_event_type(self):
        """Test extracting event type from valid payload."""
        payload = {
            "data": {
                "attributes": {
                    "event": "container.transport.vessel_arrived"
                }
            }
        }
        
        event_type = extract_event_type(payload)
        assert event_type == "container.transport.vessel_arrived"
    
    def test_extract_missing_event_type(self):
        """Test extracting from payload without event type."""
        payload = {
            "data": {
                "attributes": {}
            }
        }
        
        event_type = extract_event_type(payload)
        assert event_type == ""
    
    def test_extract_malformed_payload(self):
        """Test extracting from malformed payload."""
        payloads = [
            {},
            {"data": {}},
            {"data": None},
            {"data": {"attributes": None}},
        ]
        
        for payload in payloads:
            event_type = extract_event_type(payload)
            assert event_type == ""


class TestPerformanceRequirements:
    """Tests to verify performance requirements."""
    
    @pytest.fixture
    def mock_env(self):
        """Fixture to set up environment variables."""
        env_vars = {
            'TERMINAL49_WEBHOOK_SECRET': 'test-secret-key',
            'GCP_PROJECT_ID': 'test-project',
            'PUBSUB_TOPIC': 'terminal49-webhook-events'
        }
        with patch.dict(os.environ, env_vars):
            yield env_vars
    
    @pytest.fixture
    def mock_pubsub(self):
        """Fixture to mock Pub/Sub publisher."""
        with patch('pubsub_publisher.get_publisher_client') as mock_client:
            mock_future = MagicMock()
            mock_future.result.return_value = "msg_123456"
            
            mock_publisher = MagicMock()
            mock_publisher.publish.return_value = mock_future
            mock_publisher.topic_path.return_value = "projects/test-project/topics/terminal49-webhook-events"
            
            mock_client.return_value = mock_publisher
            yield mock_publisher
    
    def test_response_time_under_3_seconds(self, mock_env, mock_pubsub):
        """Test that webhook responds within 3 seconds (Terminal49 requirement)."""
        payload = {
            "data": {
                "id": "notif_perf",
                "type": "notification",
                "attributes": {
                    "event": "container.updated"
                }
            }
        }
        
        body = json.dumps(payload)
        signature = compute_signature(body, mock_env['TERMINAL49_WEBHOOK_SECRET'])
        
        request = MockRequest(
            method='POST',
            headers={'X-T49-Webhook-Signature': signature},
            body=body
        )
        
        start_time = datetime.utcnow()
        response, status_code = webhook_receiver(request)
        duration = (datetime.utcnow() - start_time).total_seconds()
        
        assert status_code == 200
        assert duration < 3.0  # Must respond within 3 seconds


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
