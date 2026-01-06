"""
Database Connection Module

Manages PostgreSQL connections to Supabase with connection pooling.
"""

import os
import logging
from contextlib import contextmanager
from typing import Generator
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

logger = logging.getLogger(__name__)

# Global connection pool (cached across function invocations)
_connection_pool = None


def _get_connection_pool():
    """
    Gets or creates the connection pool.
    
    Connection pool is cached globally to reuse across function invocations.
    This improves performance by avoiding connection overhead on warm starts.
    
    Returns:
        SimpleConnectionPool instance
    """
    global _connection_pool
    
    if _connection_pool is None:
        logger.info("Initializing database connection pool")
        
        # Get database configuration from environment
        db_host = os.environ.get('SUPABASE_DB_HOST')
        db_port = os.environ.get('SUPABASE_DB_PORT', '5432')
        db_name = os.environ.get('SUPABASE_DB_NAME')
        db_user = os.environ.get('SUPABASE_DB_USER')
        db_password = os.environ.get('SUPABASE_DB_PASSWORD')
        
        # Validate required configuration
        if not all([db_host, db_name, db_user, db_password]):
            raise ValueError(
                "Missing required database configuration. "
                "Ensure SUPABASE_DB_HOST, SUPABASE_DB_NAME, "
                "SUPABASE_DB_USER, and SUPABASE_DB_PASSWORD are set."
            )
        
        # Create connection pool
        # minconn=1, maxconn=5 is appropriate for Cloud Functions
        # Each function instance handles one request at a time
        try:
            _connection_pool = pool.SimpleConnectionPool(
                minconn=1,
                maxconn=5,
                host=db_host,
                port=db_port,
                database=db_name,
                user=db_user,
                password=db_password,
                # Connection timeout settings
                connect_timeout=10,
                # Keep connections alive
                keepalives=1,
                keepalives_idle=30,
                keepalives_interval=10,
                keepalives_count=5
            )
            logger.info("Database connection pool initialized successfully")
            
        except psycopg2.Error as e:
            logger.error(
                "Failed to initialize database connection pool",
                extra={'error': str(e), 'error_type': type(e).__name__},
                exc_info=True
            )
            raise
    
    return _connection_pool


@contextmanager
def get_db_connection() -> Generator:
    """
    Context manager for database connections.
    
    Automatically handles connection acquisition, commit/rollback, and release.
    
    Usage:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM shipments")
            results = cursor.fetchall()
    
    Yields:
        psycopg2 connection object
        
    Raises:
        psycopg2.Error: On database connection or operation errors
    """
    pool_instance = _get_connection_pool()
    conn = None
    
    try:
        # Get connection from pool
        conn = pool_instance.getconn()
        
        if conn is None:
            raise psycopg2.Error("Failed to get connection from pool")
        
        logger.debug("Database connection acquired from pool")
        
        # Yield connection to caller
        yield conn
        
        # Commit transaction on success
        conn.commit()
        logger.debug("Database transaction committed")
        
    except psycopg2.Error as e:
        # Rollback on error
        if conn:
            conn.rollback()
            logger.warning(
                "Database transaction rolled back",
                extra={'error': str(e), 'error_type': type(e).__name__}
            )
        raise
        
    except Exception as e:
        # Rollback on any error
        if conn:
            conn.rollback()
            logger.error(
                "Unexpected error, transaction rolled back",
                extra={'error': str(e), 'error_type': type(e).__name__},
                exc_info=True
            )
        raise
        
    finally:
        # Always return connection to pool
        if conn:
            pool_instance.putconn(conn)
            logger.debug("Database connection returned to pool")


def execute_query(conn, query: str, params: dict = None) -> list:
    """
    Executes a SELECT query and returns results as list of dicts.
    
    Args:
        conn: Database connection
        query: SQL query string
        params: Query parameters dictionary
        
    Returns:
        List of result rows as dictionaries
    """
    with conn.cursor(cursor_factory=RealDictCursor) as cursor:
        cursor.execute(query, params)
        return cursor.fetchall()


def execute_update(conn, query: str, params: dict = None) -> int:
    """
    Executes an INSERT/UPDATE/DELETE query.
    
    Args:
        conn: Database connection
        query: SQL query string
        params: Query parameters dictionary
        
    Returns:
        Number of affected rows
    """
    with conn.cursor() as cursor:
        cursor.execute(query, params)
        return cursor.rowcount


def close_connection_pool():
    """
    Closes all connections in the pool.
    
    Should be called during graceful shutdown (not typically needed in Cloud Functions).
    """
    global _connection_pool
    
    if _connection_pool:
        _connection_pool.closeall()
        _connection_pool = None
        logger.info("Database connection pool closed")
