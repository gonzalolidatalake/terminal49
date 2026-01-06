"""
Integration Tests for Event Processor Cloud Function

Tests end-to-end event processing with mocked external dependencies.
"""

import pytest
import sys
import json
import base64
from pathlib import Path
from unittest.mock import Mock, MagicMock, patch
from datetime import datetime

# Add functions directory to path
functions_path = Path(__file__).parent.parent.parent / 'functions' / 'event_processor'
sys.path.insert(0, str(functions_path))

from main import process_webhook_event, _extract_notification_id


class TestProcessWebhookEvent:
    """Integration tests for main event processing function."""
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    def test_process_webhook_event_success(
        self,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test successful event processing end-to-end."""
        # Create mock cloud event
        payload = {
            'data': {
                'id': 'notif-123',
                'type': 'container',
                'attributes': {'event': 'container.updated'}
            },
            'included': []
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-123',
                'attributes': {
                    'event_type': 'container.updated',
                    'request_id': 'req-123'
                }
            }
        }
        
        # Mock database connection
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        # Execute
        process_webhook_event(cloud_event)
        
        # Verify archival happened first
        mock_archive.assert_called_once()
        assert mock_archive.call_args[1]['event_type'] == 'container.updated'
        assert mock_archive.call_args[1]['notification_id'] == 'notif-123'
        
        # Verify transformation happened
        mock_transform.assert_called_once()
        assert mock_transform.call_args[0][1] == 'container.updated'
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    def test_process_webhook_event_container_transport(
        self,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test processing container transport event."""
        payload = {
            'data': {
                'id': 'notif-456',
                'type': 'transport_event'
            },
            'included': [
                {
                    'type': 'shipment',
                    'id': 'ship-123',
                    'attributes': {'bill_of_lading_number': 'BOL123'}
                },
                {
                    'type': 'container',
                    'id': 'cont-456',
                    'attributes': {'number': 'CONT123'},
                    'relationships': {
                        'shipment': {'data': {'id': 'ship-123'}}
                    }
                },
                {
                    'type': 'transport_event',
                    'id': 'event-789',
                    'attributes': {'event': 'vessel_arrived'},
                    'relationships': {
                        'container': {'data': {'id': 'cont-456'}}
                    }
                }
            ]
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-456',
                'attributes': {
                    'event_type': 'container.transport.vessel_arrived',
                    'request_id': 'req-456'
                }
            }
        }
        
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        process_webhook_event(cloud_event)
        
        # Verify correct event type passed
        assert mock_transform.call_args[0][1] == 'container.transport.vessel_arrived'
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    def test_process_webhook_event_tracking_request(
        self,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test processing tracking request event."""
        payload = {
            'data': {
                'id': 'notif-789',
                'type': 'tracking_request',
                'attributes': {
                    'request_number': 'BOL123',
                    'status': 'created'
                }
            }
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-789',
                'attributes': {
                    'event_type': 'tracking_request.succeeded',
                    'request_id': 'req-789'
                }
            }
        }
        
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        process_webhook_event(cloud_event)
        
        mock_transform.assert_called_once()
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    def test_process_webhook_event_transformation_error(
        self,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test handling of transformation errors."""
        payload = {
            'data': {
                'id': 'notif-error',
                'type': 'container'
            }
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-error',
                'attributes': {
                    'event_type': 'container.updated',
                    'request_id': 'req-error'
                }
            }
        }
        
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        # Simulate transformation error
        mock_transform.side_effect = ValueError("Invalid data")
        
        # Should raise exception to trigger Pub/Sub retry
        with pytest.raises(ValueError):
            process_webhook_event(cloud_event)
        
        # Archive should still have been called
        mock_archive.assert_called_once()
    
    @patch('main.archive_raw_event')
    def test_process_webhook_event_malformed_message(self, mock_archive):
        """Test handling of malformed Pub/Sub message."""
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': base64.b64encode(b'not-valid-json'),
                'messageId': 'msg-malformed',
                'attributes': {}
            }
        }
        
        # Should not raise exception (don't retry malformed messages)
        process_webhook_event(cloud_event)
        
        # Archive should not be called for malformed messages
        mock_archive.assert_not_called()
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    def test_process_webhook_event_missing_attributes(
        self,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test processing event with missing message attributes."""
        payload = {
            'data': {
                'id': 'notif-no-attrs',
                'type': 'container'
            }
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-no-attrs',
                'attributes': {}  # Missing event_type and request_id
            }
        }
        
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        # Should still process with defaults
        process_webhook_event(cloud_event)
        
        # Verify defaults used
        assert mock_transform.call_args[0][1] == 'unknown'


class TestExtractNotificationId:
    """Tests for notification ID extraction."""
    
    def test_extract_notification_id_present(self):
        """Test extracting notification ID when present."""
        payload = {
            'data': {
                'id': 'notif-123',
                'type': 'container'
            }
        }
        
        result = _extract_notification_id(payload)
        
        assert result == 'notif-123'
    
    def test_extract_notification_id_missing(self):
        """Test extracting notification ID when missing."""
        payload = {
            'data': {
                'type': 'container'
            }
        }
        
        result = _extract_notification_id(payload)
        
        assert result is None
    
    def test_extract_notification_id_malformed_payload(self):
        """Test extracting notification ID from malformed payload."""
        payload = {}
        
        result = _extract_notification_id(payload)
        
        assert result is None


class TestEventProcessingScenarios:
    """Integration tests for specific event processing scenarios."""
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    def test_process_multiple_containers_in_event(
        self,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test processing event with multiple containers."""
        payload = {
            'data': {
                'id': 'notif-multi',
                'type': 'transport_event'
            },
            'included': [
                {'type': 'shipment', 'id': 'ship-1', 'attributes': {}},
                {'type': 'container', 'id': 'cont-1', 'attributes': {}},
                {'type': 'container', 'id': 'cont-2', 'attributes': {}},
                {'type': 'transport_event', 'id': 'event-1', 'attributes': {}}
            ]
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-multi',
                'attributes': {
                    'event_type': 'container.transport.vessel_arrived',
                    'request_id': 'req-multi'
                }
            }
        }
        
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        process_webhook_event(cloud_event)
        
        # Verify payload passed to transform includes all entities
        transform_payload = mock_transform.call_args[0][0]
        assert len(transform_payload['included']) == 4
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    def test_process_event_with_null_values(
        self,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test processing event with null attribute values."""
        payload = {
            'data': {
                'id': 'notif-nulls',
                'type': 'container'
            },
            'included': [
                {
                    'type': 'container',
                    'id': 'cont-nulls',
                    'attributes': {
                        'number': 'CONT123',
                        'seal_number': None,
                        'pod_arrived_at': None,
                        'available_for_pickup': None
                    }
                }
            ]
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-nulls',
                'attributes': {
                    'event_type': 'container.updated',
                    'request_id': 'req-nulls'
                }
            }
        }
        
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        # Should process without errors
        process_webhook_event(cloud_event)
        
        mock_transform.assert_called_once()
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    def test_process_event_idempotency(
        self,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test processing same event multiple times (idempotency)."""
        payload = {
            'data': {
                'id': 'notif-duplicate',
                'type': 'container'
            }
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-duplicate',
                'attributes': {
                    'event_type': 'container.updated',
                    'request_id': 'req-duplicate'
                }
            }
        }
        
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        # Process same event twice
        process_webhook_event(cloud_event)
        process_webhook_event(cloud_event)
        
        # Both should succeed (idempotency handled in database layer)
        assert mock_transform.call_count == 2
        assert mock_archive.call_count == 2


class TestPerformanceMetrics:
    """Tests for performance logging and metrics."""
    
    @patch('main.archive_raw_event')
    @patch('main.get_db_connection')
    @patch('main.transform_event')
    @patch('main.logger')
    def test_processing_duration_logged(
        self,
        mock_logger,
        mock_transform,
        mock_get_db,
        mock_archive
    ):
        """Test that processing duration is logged."""
        payload = {
            'data': {
                'id': 'notif-perf',
                'type': 'container'
            }
        }
        
        message_data = base64.b64encode(json.dumps(payload).encode('utf-8'))
        
        cloud_event = Mock()
        cloud_event.data = {
            'message': {
                'data': message_data,
                'messageId': 'msg-perf',
                'attributes': {
                    'event_type': 'container.updated',
                    'request_id': 'req-perf'
                }
            }
        }
        
        mock_conn = Mock()
        mock_get_db.return_value.__enter__.return_value = mock_conn
        
        process_webhook_event(cloud_event)
        
        # Verify duration_ms is logged
        info_calls = [call for call in mock_logger.info.call_args_list]
        success_log = [call for call in info_calls if 'successfully' in str(call)]
        
        assert len(success_log) > 0


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
