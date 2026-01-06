"""
Unit Tests for Database Operations

Tests upsert and insert operations with idempotency.
"""

import pytest
import sys
from pathlib import Path
from unittest.mock import Mock, MagicMock, patch
from datetime import datetime

# Add functions directory to path
functions_path = Path(__file__).parent.parent.parent / 'functions' / 'event_processor'
sys.path.insert(0, str(functions_path))

from database_operations import (
    upsert_shipment,
    upsert_container,
    insert_container_event,
    upsert_tracking_request,
    record_webhook_delivery,
    _parse_timestamp
)


class TestUpsertShipment:
    """Tests for shipment upsert operations."""
    
    def test_upsert_shipment_success(self):
        """Test successful shipment upsert."""
        shipment_data = {
            'id': 't49-ship-123',
            'attributes': {
                'bill_of_lading_number': 'BOL123',
                'normalized_number': 'BOL123',
                'shipping_line_scac': 'MAEU',
                'port_of_lading_locode': 'CNSHA',
                'port_of_discharge_locode': 'USLAX',
                'pod_eta_at': '2024-01-15T10:30:00Z'
            }
        }
        
        # Mock connection and cursor
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-ship-uuid',)
        
        result = upsert_shipment(shipment_data, mock_conn)
        
        assert result == 'db-ship-uuid'
        mock_cursor.execute.assert_called_once()
        
        # Verify SQL contains ON CONFLICT clause
        sql = mock_cursor.execute.call_args[0][0]
        assert 'ON CONFLICT' in sql
        assert 't49_shipment_id' in sql
    
    def test_upsert_shipment_missing_id(self):
        """Test upsert fails when shipment ID is missing."""
        shipment_data = {
            'attributes': {'bill_of_lading_number': 'BOL123'}
        }
        
        mock_conn = Mock()
        
        with pytest.raises(ValueError, match="missing 'id' field"):
            upsert_shipment(shipment_data, mock_conn)
    
    def test_upsert_shipment_handles_null_values(self):
        """Test upsert handles null/missing attributes gracefully."""
        shipment_data = {
            'id': 't49-ship-456',
            'attributes': {
                'bill_of_lading_number': 'BOL456',
                # Many fields missing/null
            }
        }
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-ship-uuid',)
        
        result = upsert_shipment(shipment_data, mock_conn)
        
        assert result == 'db-ship-uuid'
        
        # Verify params include None for missing fields
        params = mock_cursor.execute.call_args[0][1]
        assert params['t49_id'] == 't49-ship-456'
        assert params['bol'] == 'BOL456'
        assert params['destination'] is None


class TestUpsertContainer:
    """Tests for container upsert operations."""
    
    def test_upsert_container_success(self):
        """Test successful container upsert."""
        container_data = {
            'id': 't49-cont-123',
            'attributes': {
                'number': 'CONT123456',
                'equipment_type': '40HC',
                'equipment_length': 40,
                'available_for_pickup': True,
                'current_status': 'available'
            }
        }
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-cont-uuid',)
        
        result = upsert_container(container_data, 'db-ship-123', mock_conn)
        
        assert result == 'db-cont-uuid'
        mock_cursor.execute.assert_called_once()
        
        # Verify shipment_id is included
        params = mock_cursor.execute.call_args[0][1]
        assert params['shipment_id'] == 'db-ship-123'
        assert params['number'] == 'CONT123456'
    
    def test_upsert_container_without_shipment(self):
        """Test container upsert without shipment reference."""
        container_data = {
            'id': 't49-cont-456',
            'attributes': {'number': 'CONT456789'}
        }
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-cont-uuid',)
        
        result = upsert_container(container_data, None, mock_conn)
        
        assert result == 'db-cont-uuid'
        
        # Verify shipment_id is None
        params = mock_cursor.execute.call_args[0][1]
        assert params['shipment_id'] is None


class TestInsertContainerEvent:
    """Tests for container event insert operations."""
    
    def test_insert_container_event_success(self):
        """Test successful container event insert."""
        event_data = {
            'id': 't49-event-123',
            'attributes': {
                'event': 'container.transport.vessel_arrived',
                'timestamp': '2024-01-15T10:30:00Z',
                'location_locode': 'USLAX',
                'data_source': 'shipping_line'
            }
        }
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-event-uuid',)
        
        result = insert_container_event(
            event_data,
            'db-cont-123',
            'db-ship-123',
            mock_conn
        )
        
        assert result == 'db-event-uuid'
        
        # Verify idempotency clause
        sql = mock_cursor.execute.call_args[0][0]
        assert 'ON CONFLICT' in sql
        assert 't49_event_id' in sql
        assert 'DO NOTHING' in sql
    
    def test_insert_container_event_duplicate(self):
        """Test inserting duplicate event (idempotency)."""
        event_data = {
            'id': 't49-event-duplicate',
            'attributes': {
                'event': 'container.transport.vessel_departed',
                'timestamp': '2024-01-10T08:00:00Z'
            }
        }
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        # fetchone returns None for duplicate (ON CONFLICT DO NOTHING)
        mock_cursor.fetchone.return_value = None
        
        result = insert_container_event(
            event_data,
            'db-cont-123',
            'db-ship-123',
            mock_conn
        )
        
        # Should return None for duplicate
        assert result is None


class TestUpsertTrackingRequest:
    """Tests for tracking request upsert operations."""
    
    def test_upsert_tracking_request_success(self):
        """Test successful tracking request upsert."""
        tracking_request_data = {
            'id': 't49-tr-123',
            'attributes': {
                'request_number': 'BOL123',
                'request_type': 'bill_of_lading',
                'scac': 'MAEU',
                'status': 'created'
            }
        }
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-tr-uuid',)
        
        result = upsert_tracking_request(tracking_request_data, mock_conn)
        
        assert result == 'db-tr-uuid'
        
        params = mock_cursor.execute.call_args[0][1]
        assert params['request_number'] == 'BOL123'
        assert params['status'] == 'created'
    
    def test_upsert_tracking_request_failed_status(self):
        """Test tracking request with failed status."""
        tracking_request_data = {
            'id': 't49-tr-456',
            'attributes': {
                'request_number': 'BOL456',
                'request_type': 'bill_of_lading',
                'scac': 'MAEU',
                'status': 'failed',
                'failed_reason': 'Invalid BOL number'
            }
        }
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-tr-uuid',)
        
        result = upsert_tracking_request(tracking_request_data, mock_conn)
        
        assert result == 'db-tr-uuid'
        
        params = mock_cursor.execute.call_args[0][1]
        assert params['status'] == 'failed'
        assert params['failed_reason'] == 'Invalid BOL number'


class TestRecordWebhookDelivery:
    """Tests for webhook delivery recording."""
    
    def test_record_webhook_delivery_processing(self):
        """Test recording webhook delivery in processing state."""
        payload = {'data': {'type': 'container'}}
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-delivery-uuid',)
        
        result = record_webhook_delivery(
            notification_id='notif-123',
            event_type='container.updated',
            payload=payload,
            processing_status='processing',
            processing_error=None,
            conn=mock_conn
        )
        
        assert result == 'db-delivery-uuid'
        
        params = mock_cursor.execute.call_args[0][1]
        assert params['notification_id'] == 'notif-123'
        assert params['processing_status'] == 'processing'
        assert params['processing_error'] is None
    
    def test_record_webhook_delivery_failed(self):
        """Test recording webhook delivery in failed state."""
        payload = {'data': {'type': 'container'}}
        
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('db-delivery-uuid',)
        
        result = record_webhook_delivery(
            notification_id='notif-456',
            event_type='container.updated',
            payload=payload,
            processing_status='failed',
            processing_error='Database connection failed',
            conn=mock_conn
        )
        
        assert result == 'db-delivery-uuid'
        
        params = mock_cursor.execute.call_args[0][1]
        assert params['processing_status'] == 'failed'
        assert params['processing_error'] == 'Database connection failed'


class TestParseTimestamp:
    """Tests for timestamp parsing utility."""
    
    def test_parse_timestamp_valid_iso8601(self):
        """Test parsing valid ISO 8601 timestamp."""
        timestamp_str = '2024-01-15T10:30:00Z'
        
        result = _parse_timestamp(timestamp_str)
        
        assert isinstance(result, datetime)
        assert result.year == 2024
        assert result.month == 1
        assert result.day == 15
    
    def test_parse_timestamp_with_timezone(self):
        """Test parsing timestamp with timezone offset."""
        timestamp_str = '2024-01-15T10:30:00+00:00'
        
        result = _parse_timestamp(timestamp_str)
        
        assert isinstance(result, datetime)
    
    def test_parse_timestamp_none(self):
        """Test parsing None timestamp."""
        result = _parse_timestamp(None)
        
        assert result is None
    
    def test_parse_timestamp_empty_string(self):
        """Test parsing empty string."""
        result = _parse_timestamp('')
        
        assert result is None
    
    def test_parse_timestamp_invalid_format(self):
        """Test parsing invalid timestamp format."""
        timestamp_str = 'not-a-timestamp'
        
        result = _parse_timestamp(timestamp_str)
        
        # Should return None and log warning
        assert result is None


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
