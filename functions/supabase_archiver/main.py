"""
Supabase to BigQuery Archival Function

Archives container events older than 90 days from Supabase to BigQuery.
Runs daily via Cloud Scheduler.

Author: Terminal49 Platform Team
Version: 1.0.0
"""

import functions_framework
from google.cloud import bigquery
from datetime import datetime, timedelta
import os
import logging
import json
from typing import Dict, List, Any, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global clients (cached across invocations)
_bigquery_client: Optional[bigquery.Client] = None
_supabase_client = None


def _get_supabase_client():
    """
    Initialize Supabase client (lazy initialization).
    
    Returns:
        Supabase Client instance
        
    Raises:
        ValueError: If required environment variables are missing
    """
    global _supabase_client
    
    if _supabase_client is None:
        try:
            from supabase import create_client, Client
            
            url = os.environ.get('SUPABASE_URL')
            key = os.environ.get('SUPABASE_SERVICE_KEY')
            
            if not url or not key:
                raise ValueError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
            
            _supabase_client = create_client(url, key)
            logger.info("Supabase client initialized successfully")
            
        except ImportError:
            logger.error("supabase-py library not installed")
            raise
        except Exception as e:
            logger.error(f"Failed to initialize Supabase client: {str(e)}")
            raise
    
    return _supabase_client


def _get_bigquery_client() -> bigquery.Client:
    """
    Initialize BigQuery client (lazy initialization).
    
    Returns:
        BigQuery Client instance
    """
    global _bigquery_client
    
    if _bigquery_client is None:
        _bigquery_client = bigquery.Client()
        logger.info("BigQuery client initialized successfully")
    
    return _bigquery_client


def _transform_event_to_bigquery_row(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Transform Supabase event record to BigQuery schema.
    
    Args:
        event: Event record from Supabase
        
    Returns:
        Dictionary matching BigQuery events_historical schema
    """
    # Handle raw_data field - ensure it's a dict
    raw_data = event.get('raw_data', {})
    if isinstance(raw_data, str):
        try:
            raw_data = json.loads(raw_data)
        except json.JSONDecodeError:
            logger.warning(f"Failed to parse raw_data for event {event.get('event_id')}")
            raw_data = {}
    
    return {
        'event_id': event['event_id'],
        'container_id': event['container_id'],
        'shipment_id': event['shipment_id'],
        'event_type': event['event_type'],
        'event_timestamp': event.get('event_timestamp'),
        'location_locode': event.get('location_locode'),
        'location_name': event.get('location_name'),
        'vessel_name': event.get('vessel_name'),
        'vessel_imo': event.get('vessel_imo'),
        'voyage_number': event.get('voyage_number'),
        'data_source': event.get('data_source'),
        'raw_data': json.dumps(raw_data) if isinstance(raw_data, dict) else raw_data,
        'created_at': event['created_at'],
        'archived_at': datetime.utcnow().isoformat()
    }


def _query_old_events(supabase_client, cutoff_date: datetime, batch_size: int) -> List[Dict[str, Any]]:
    """
    Query old events from Supabase.
    
    Args:
        supabase_client: Supabase client instance
        cutoff_date: Events older than this date will be archived
        batch_size: Maximum number of events to retrieve
        
    Returns:
        List of event records
    """
    try:
        response = supabase_client.table('container_events') \
            .select('*') \
            .lt('created_at', cutoff_date.isoformat()) \
            .limit(batch_size) \
            .execute()
        
        events = response.data if response.data else []
        logger.info(f"Retrieved {len(events)} events from Supabase")
        return events
        
    except Exception as e:
        logger.error(f"Failed to query Supabase: {str(e)}")
        raise


def _insert_to_bigquery(
    bq_client: bigquery.Client,
    table_ref: str,
    rows: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """
    Insert rows to BigQuery table.
    
    Args:
        bq_client: BigQuery client instance
        table_ref: Full table reference (project.dataset.table)
        rows: List of rows to insert
        
    Returns:
        List of errors (empty if successful)
    """
    try:
        errors = bq_client.insert_rows_json(table_ref, rows)
        
        if errors:
            logger.error(f"BigQuery insert errors: {errors}")
        else:
            logger.info(f"Successfully inserted {len(rows)} rows to BigQuery")
        
        return errors
        
    except Exception as e:
        logger.error(f"Failed to insert to BigQuery: {str(e)}")
        raise


def _delete_from_supabase(supabase_client, event_ids: List[str]) -> None:
    """
    Delete archived events from Supabase.
    
    Args:
        supabase_client: Supabase client instance
        event_ids: List of event IDs to delete
    """
    try:
        supabase_client.table('container_events') \
            .delete() \
            .in_('event_id', event_ids) \
            .execute()
        
        logger.info(f"Deleted {len(event_ids)} events from Supabase")
        
    except Exception as e:
        logger.error(f"Failed to delete from Supabase: {str(e)}")
        raise


@functions_framework.http
def archive_old_events(request):
    """
    Archives events older than 90 days from Supabase to BigQuery.
    
    Process:
    1. Query Supabase for events where created_at < (now - retention_days)
    2. Transform to BigQuery schema
    3. Batch insert to events_historical table
    4. Delete from Supabase (if DELETE_AFTER_ARCHIVE=true)
    5. Return statistics
    
    Args:
        request: Flask request object
        
    Returns:
        JSON response with archival statistics
    """
    start_time = datetime.utcnow()
    
    # Configuration from environment variables
    retention_days = int(os.environ.get('RETENTION_DAYS', '90'))
    batch_size = int(os.environ.get('BATCH_SIZE', '1000'))
    delete_after_archive = os.environ.get('DELETE_AFTER_ARCHIVE', 'false').lower() == 'true'
    project_id = os.environ.get('GCP_PROJECT_ID')
    dataset_id = os.environ.get('BIGQUERY_DATASET_ID', 'terminal49_raw_events')
    table_id = 'events_historical'
    
    cutoff_date = datetime.utcnow() - timedelta(days=retention_days)
    
    logger.info(f"Starting archival for events older than {cutoff_date.isoformat()}")
    logger.info(f"Configuration: retention_days={retention_days}, batch_size={batch_size}, "
                f"delete_after_archive={delete_after_archive}")
    
    try:
        # Initialize clients
        supabase = _get_supabase_client()
        bq_client = _get_bigquery_client()
        
        table_ref = f"{project_id}.{dataset_id}.{table_id}"
        logger.info(f"Target BigQuery table: {table_ref}")
        
        # Query old events from Supabase
        events = _query_old_events(supabase, cutoff_date, batch_size)
        
        if not events:
            logger.info("No events to archive")
            return {
                "status": "success",
                "archived_count": 0,
                "deleted_from_supabase": False,
                "duration_ms": (datetime.utcnow() - start_time).total_seconds() * 1000,
                "cutoff_date": cutoff_date.isoformat()
            }, 200
        
        # Transform to BigQuery schema
        rows_to_insert = [_transform_event_to_bigquery_row(event) for event in events]
        
        # Insert to BigQuery
        errors = _insert_to_bigquery(bq_client, table_ref, rows_to_insert)
        
        if errors:
            logger.error(f"BigQuery insert failed with errors: {errors}")
            return {
                "status": "error",
                "message": f"BigQuery insert errors: {errors}",
                "archived_count": 0
            }, 500
        
        archived_count = len(rows_to_insert)
        logger.info(f"Successfully archived {archived_count} events to BigQuery")
        
        # Delete from Supabase if configured
        deleted_from_supabase = False
        if delete_after_archive:
            event_ids = [event['event_id'] for event in events]
            _delete_from_supabase(supabase, event_ids)
            deleted_from_supabase = True
            logger.info(f"Deleted {archived_count} events from Supabase")
        
        duration_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        response = {
            "status": "success",
            "archived_count": archived_count,
            "deleted_from_supabase": deleted_from_supabase,
            "duration_ms": duration_ms,
            "cutoff_date": cutoff_date.isoformat(),
            "batch_size": batch_size,
            "retention_days": retention_days
        }
        
        logger.info(f"Archival completed successfully: {response}")
        return response, 200
        
    except Exception as e:
        logger.error(f"Archival failed: {str(e)}", exc_info=True)
        return {
            "status": "error",
            "message": str(e),
            "archived_count": 0
        }, 500
