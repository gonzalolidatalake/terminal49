"""
Unit Tests for Event Transformers

Tests transformation logic for all Terminal49 event types.
"""

import pytest
import sys
from pathlib import Path
from unittest.mock import Mock, MagicMock, patch, call

# Add functions directory to path
functions_path = Path(__file__).parent.parent.parent / 'functions' / 'event_processor'
sys.path.insert(0, str(functions_path))

from transformers import (
    transform_event,
    extract_entities_by_type,
    find_related_entity,
    _handle_container_transport_event,
    _handle_container_updated_event,
    _handle_tracking_request_event,
    _handle_shipment_estimated_arrival_event,
    _handle_container_pickup_lfd_changed_event
)


class TestTransformEvent:
    """Tests for main transform_event dispatcher."""
    
    @patch('transformers.record_webhook_delivery')
    @patch('transformers._handle_container_transport_event')
    def test_transform_container_transport_event(
        self,
        mock_handle_transport,
        mock_record_delivery
    ):
        """Test routing of container.transport.* events."""
        payload = {'data': {'type': 'transport_event'}}
        event_type = 'container.transport.vessel_arrived'
        notification_id = 'notif-123'
        conn = Mock()
        
        transform_event(payload, event_type, notification_id, conn)
        
        # Should record delivery twice (processing and completed)
        assert mock_record_delivery.call_count == 2
        mock_handle_transport.assert_called_once_with(payload, conn)
    
    @patch('transformers.record_webhook_delivery')
    @patch('transformers._handle_container_updated_event')
    def test_transform_container_updated_event(
        self,
        mock_handle_updated,
        mock_record_delivery
    ):
        """Test routing of container.updated events."""
        payload = {'data': {'type': 'container'}}
        event_type = 'container.updated'
        notification_id = 'notif-456'
        conn = Mock()
        
        transform_event(payload, event_type, notification_id, conn)
        
        mock_handle_updated.assert_called_once_with(payload, conn)
    
    @patch('transformers.record_webhook_delivery')
    @patch('transformers._handle_tracking_request_event')
    def test_transform_tracking_request_event(
        self,
        mock_handle_tracking,
        mock_record_delivery
    ):
        """Test routing of tracking_request.* events."""
        payload = {'data': {'type': 'tracking_request'}}
        event_type = 'tracking_request.succeeded'
        notification_id = 'notif-789'
        conn = Mock()
        
        transform_event(payload, event_type, notification_id, conn)
        
        mock_handle_tracking.assert_called_once_with(payload, conn)
    
    @patch('transformers.record_webhook_delivery')
    def test_transform_unknown_event_type(self, mock_record_delivery):
        """Test handling of unknown event types."""
        payload = {'data': {'type': 'unknown'}}
        event_type = 'unknown.event.type'
        notification_id = 'notif-999'
        conn = Mock()
        
        # Should not raise exception
        transform_event(payload, event_type, notification_id, conn)
        
        # Should still record as completed
        assert mock_record_delivery.call_count == 2
    
    @patch('transformers.record_webhook_delivery')
    @patch('transformers._handle_container_transport_event')
    def test_transform_event_handles_processing_error(
        self,
        mock_handle_transport,
        mock_record_delivery
    ):
        """Test error handling during event processing."""
        payload = {'data': {'type': 'transport_event'}}
        event_type = 'container.transport.vessel_arrived'
        notification_id = 'notif-error'
        conn = Mock()
        
        # Simulate processing error
        mock_handle_transport.side_effect = ValueError("Processing failed")
        
        with pytest.raises(ValueError):
            transform_event(payload, event_type, notification_id, conn)
        
        # Should record failure
        calls = mock_record_delivery.call_args_list
        assert any('failed' in str(call) for call in calls)


class TestContainerTransportEventHandler:
    """Tests for container transport event handling."""
    
    @patch('transformers.upsert_shipment')
    @patch('transformers.upsert_container')
    @patch('transformers.insert_container_event')
    def test_handle_container_transport_event_complete(
        self,
        mock_insert_event,
        mock_upsert_container,
        mock_upsert_shipment
    ):
        """Test handling complete container transport event."""
        payload = {
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
                        'container': {'data': {'id': 'cont-456'}},
                        'shipment': {'data': {'id': 'ship-123'}}
                    }
                }
            ]
        }
        conn = Mock()
        
        mock_upsert_shipment.return_value = 'db-ship-123'
        mock_upsert_container.return_value = 'db-cont-456'
        
        _handle_container_transport_event(payload, conn)
        
        # Verify all operations called
        mock_upsert_shipment.assert_called_once()
        mock_upsert_container.assert_called_once()
        mock_insert_event.assert_called_once()
    
    @patch('transformers.upsert_shipment')
    @patch('transformers.upsert_container')
    @patch('transformers.insert_container_event')
    def test_handle_container_transport_event_multiple_entities(
        self,
        mock_insert_event,
        mock_upsert_container,
        mock_upsert_shipment
    ):
        """Test handling event with multiple containers and shipments."""
        payload = {
            'included': [
                {'type': 'shipment', 'id': 'ship-1', 'attributes': {}},
                {'type': 'shipment', 'id': 'ship-2', 'attributes': {}},
                {
                    'type': 'container',
                    'id': 'cont-1',
                    'attributes': {},
                    'relationships': {'shipment': {'data': {'id': 'ship-1'}}}
                },
                {
                    'type': 'container',
                    'id': 'cont-2',
                    'attributes': {},
                    'relationships': {'shipment': {'data': {'id': 'ship-2'}}}
                },
                {
                    'type': 'transport_event',
                    'id': 'event-1',
                    'attributes': {},
                    'relationships': {'container': {'data': {'id': 'cont-1'}}}
                },
                {
                    'type': 'transport_event',
                    'id': 'event-2',
                    'attributes': {},
                    'relationships': {'container': {'data': {'id': 'cont-2'}}}
                }
            ]
        }
        conn = Mock()
        
        mock_upsert_shipment.side_effect = ['db-ship-1', 'db-ship-2']
        mock_upsert_container.side_effect = ['db-cont-1', 'db-cont-2']
        
        _handle_container_transport_event(payload, conn)
        
        # Verify counts
        assert mock_upsert_shipment.call_count == 2
        assert mock_upsert_container.call_count == 2
        assert mock_insert_event.call_count == 2


class TestContainerUpdatedEventHandler:
    """Tests for container updated event handling."""
    
    @patch('transformers.upsert_shipment')
    @patch('transformers.upsert_container')
    def test_handle_container_updated_event(
        self,
        mock_upsert_container,
        mock_upsert_shipment
    ):
        """Test handling container.updated event."""
        payload = {
            'included': [
                {
                    'type': 'shipment',
                    'id': 'ship-123',
                    'attributes': {}
                },
                {
                    'type': 'container',
                    'id': 'cont-456',
                    'attributes': {'available_for_pickup': True},
                    'relationships': {
                        'shipment': {'data': {'id': 'ship-123'}}
                    }
                }
            ]
        }
        conn = Mock()
        
        mock_upsert_shipment.return_value = 'db-ship-123'
        
        _handle_container_updated_event(payload, conn)
        
        mock_upsert_shipment.assert_called_once()
        mock_upsert_container.assert_called_once()


class TestTrackingRequestEventHandler:
    """Tests for tracking request event handling."""
    
    @patch('transformers.upsert_tracking_request')
    def test_handle_tracking_request_succeeded(
        self,
        mock_upsert_tracking_request
    ):
        """Test handling tracking_request.succeeded event."""
        payload = {
            'data': {
                'type': 'tracking_request',
                'id': 'tr-123',
                'attributes': {
                    'request_number': 'BOL123',
                    'status': 'created'
                }
            }
        }
        conn = Mock()
        
        _handle_tracking_request_event(payload, conn)
        
        mock_upsert_tracking_request.assert_called_once_with(
            payload['data'],
            conn
        )
    
    @patch('transformers.upsert_tracking_request')
    def test_handle_tracking_request_failed(
        self,
        mock_upsert_tracking_request
    ):
        """Test handling tracking_request.failed event."""
        payload = {
            'data': {
                'type': 'tracking_request',
                'id': 'tr-456',
                'attributes': {
                    'request_number': 'BOL456',
                    'status': 'failed',
                    'failed_reason': 'Invalid BOL number'
                }
            }
        }
        conn = Mock()
        
        _handle_tracking_request_event(payload, conn)
        
        mock_upsert_tracking_request.assert_called_once()


class TestShipmentEstimatedArrivalEventHandler:
    """Tests for shipment estimated arrival event handling."""
    
    @patch('transformers.upsert_shipment')
    def test_handle_shipment_estimated_arrival(
        self,
        mock_upsert_shipment
    ):
        """Test handling shipment.estimated.arrival event."""
        payload = {
            'included': [
                {
                    'type': 'shipment',
                    'id': 'ship-123',
                    'attributes': {
                        'pod_eta_at': '2024-01-15T10:30:00Z'
                    }
                }
            ]
        }
        conn = Mock()
        
        _handle_shipment_estimated_arrival_event(payload, conn)
        
        mock_upsert_shipment.assert_called_once()


class TestContainerPickupLfdChangedEventHandler:
    """Tests for container pickup LFD changed event handling."""
    
    @patch('transformers.upsert_shipment')
    @patch('transformers.upsert_container')
    def test_handle_container_pickup_lfd_changed(
        self,
        mock_upsert_container,
        mock_upsert_shipment
    ):
        """Test handling container.pickup_lfd.changed event."""
        payload = {
            'included': [
                {
                    'type': 'shipment',
                    'id': 'ship-123',
                    'attributes': {}
                },
                {
                    'type': 'container',
                    'id': 'cont-456',
                    'attributes': {
                        'pickup_lfd': '2024-01-20T23:59:59Z'
                    },
                    'relationships': {
                        'shipment': {'data': {'id': 'ship-123'}}
                    }
                }
            ]
        }
        conn = Mock()
        
        mock_upsert_shipment.return_value = 'db-ship-123'
        
        _handle_container_pickup_lfd_changed_event(payload, conn)
        
        mock_upsert_shipment.assert_called_once()
        mock_upsert_container.assert_called_once()


class TestHelperFunctions:
    """Tests for helper functions."""
    
    def test_extract_entities_by_type(self):
        """Test extracting entities by type from included array."""
        included = [
            {'type': 'shipment', 'id': '1'},
            {'type': 'container', 'id': '2'},
            {'type': 'shipment', 'id': '3'},
            {'type': 'transport_event', 'id': '4'}
        ]
        
        shipments = extract_entities_by_type(included, 'shipment')
        containers = extract_entities_by_type(included, 'container')
        events = extract_entities_by_type(included, 'transport_event')
        
        assert len(shipments) == 2
        assert len(containers) == 1
        assert len(events) == 1
    
    def test_extract_entities_by_type_empty(self):
        """Test extracting from empty included array."""
        included = []
        
        result = extract_entities_by_type(included, 'shipment')
        
        assert result == []
    
    def test_find_related_entity(self):
        """Test finding related entity from relationships."""
        entity = {
            'relationships': {
                'shipment': {
                    'data': {'id': 't49-ship-123'}
                }
            }
        }
        entity_map = {
            't49-ship-123': 'db-ship-123',
            't49-ship-456': 'db-ship-456'
        }
        
        result = find_related_entity(entity, 'shipment', entity_map)
        
        assert result == 'db-ship-123'
    
    def test_find_related_entity_not_found(self):
        """Test finding related entity that doesn't exist in map."""
        entity = {
            'relationships': {
                'shipment': {
                    'data': {'id': 't49-ship-999'}
                }
            }
        }
        entity_map = {
            't49-ship-123': 'db-ship-123'
        }
        
        result = find_related_entity(entity, 'shipment', entity_map)
        
        assert result is None
    
    def test_find_related_entity_missing_relationship(self):
        """Test finding related entity when relationship doesn't exist."""
        entity = {
            'relationships': {}
        }
        entity_map = {
            't49-ship-123': 'db-ship-123'
        }
        
        result = find_related_entity(entity, 'shipment', entity_map)
        
        assert result is None


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
