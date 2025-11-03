"""
Arc-Halo Cognitive Fusion Reactor - Database Connection Utilities
Python utilities for connecting to and managing the Neon database
"""

import os
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from typing import Optional, Dict, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class NeonDBConnection:
    """Manages connection pool to Neon PostgreSQL database"""
    
    def __init__(self, connection_string: Optional[str] = None):
        """
        Initialize database connection pool
        
        Args:
            connection_string: PostgreSQL connection string. If None, reads from env var.
        """
        self.connection_string = connection_string or os.getenv('NEON_DATABASE_URL')
        
        if not self.connection_string:
            raise ValueError(
                "Database connection string not provided. "
                "Set NEON_DATABASE_URL environment variable or pass connection_string parameter."
            )
        
        # Create connection pool
        self.pool = psycopg2.pool.ThreadedConnectionPool(
            minconn=1,
            maxconn=20,
            dsn=self.connection_string
        )
        logger.info("Database connection pool initialized")
    
    def get_connection(self):
        """Get a connection from the pool"""
        return self.pool.getconn()
    
    def return_connection(self, conn):
        """Return a connection to the pool"""
        self.pool.putconn(conn)
    
    def close_all(self):
        """Close all connections in the pool"""
        self.pool.closeall()
        logger.info("All database connections closed")
    
    def execute_query(self, query: str, params: Optional[tuple] = None) -> list:
        """
        Execute a SELECT query and return results
        
        Args:
            query: SQL query string
            params: Query parameters
            
        Returns:
            List of dictionaries containing query results
        """
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(query, params)
                results = cursor.fetchall()
                return [dict(row) for row in results]
        finally:
            self.return_connection(conn)
    
    def execute_command(self, command: str, params: Optional[tuple] = None) -> int:
        """
        Execute an INSERT/UPDATE/DELETE command
        
        Args:
            command: SQL command string
            params: Command parameters
            
        Returns:
            Number of rows affected
        """
        conn = self.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute(command, params)
                conn.commit()
                return cursor.rowcount
        except Exception as e:
            conn.rollback()
            logger.error(f"Error executing command: {e}")
            raise
        finally:
            self.return_connection(conn)
    
    def execute_script(self, script_path: str) -> None:
        """
        Execute a SQL script file
        
        Args:
            script_path: Path to SQL script file
        """
        conn = self.get_connection()
        try:
            with open(script_path, 'r') as f:
                script = f.read()
            
            with conn.cursor() as cursor:
                cursor.execute(script)
                conn.commit()
            
            logger.info(f"Successfully executed script: {script_path}")
        except Exception as e:
            conn.rollback()
            logger.error(f"Error executing script {script_path}: {e}")
            raise
        finally:
            self.return_connection(conn)


class ModelRepository:
    """Repository for model-related database operations"""
    
    def __init__(self, db_connection: NeonDBConnection):
        self.db = db_connection
    
    def create_model(self, model_name: str, model_type: str, 
                    architecture_config: Dict[str, Any], version: str) -> str:
        """
        Create a new model in the database
        
        Args:
            model_name: Name of the model
            model_type: Type of model (e.g., 'transformer', 'gpt', 'bert')
            architecture_config: Model architecture configuration
            version: Model version
            
        Returns:
            UUID of created model
        """
        query = """
            INSERT INTO models (model_name, model_type, architecture_config, version)
            VALUES (%s, %s, %s::jsonb, %s)
            RETURNING model_id::text
        """
        import json
        result = self.db.execute_query(
            query, 
            (model_name, model_type, json.dumps(architecture_config), version)
        )
        return result[0]['model_id']
    
    def get_model(self, model_id: str) -> Optional[Dict[str, Any]]:
        """Get model by ID"""
        query = "SELECT * FROM models WHERE model_id = %s::uuid"
        results = self.db.execute_query(query, (model_id,))
        return results[0] if results else None
    
    def list_models(self, status: Optional[str] = None) -> list:
        """List all models, optionally filtered by status"""
        if status:
            query = "SELECT * FROM models WHERE status = %s ORDER BY created_at DESC"
            return self.db.execute_query(query, (status,))
        else:
            query = "SELECT * FROM models ORDER BY created_at DESC"
            return self.db.execute_query(query)


class TensorRepository:
    """Repository for tensor-related database operations"""
    
    def __init__(self, db_connection: NeonDBConnection):
        self.db = db_connection
    
    def create_tensor(self, tensor_name: str, tensor_type: str, 
                     model_id: str, shape: list, dtype: str = 'float32') -> str:
        """
        Create tensor metadata
        
        Args:
            tensor_name: Name of the tensor
            tensor_type: Type (weight, bias, embedding, activation)
            model_id: Associated model ID
            shape: Tensor dimensions
            dtype: Data type
            
        Returns:
            UUID of created tensor
        """
        import json
        total_elements = 1
        for dim in shape:
            total_elements *= dim
        
        query = """
            INSERT INTO tensor_metadata 
            (tensor_name, tensor_type, model_id, shape, dtype, total_elements)
            VALUES (%s, %s, %s::uuid, %s::integer[], %s, %s)
            RETURNING tensor_id::text
        """
        result = self.db.execute_query(
            query,
            (tensor_name, tensor_type, model_id, shape, dtype, total_elements)
        )
        return result[0]['tensor_id']
    
    def store_tensor_data(self, tensor_id: str, data: bytes, chunk_index: int = 0) -> None:
        """
        Store tensor binary data
        
        Args:
            tensor_id: Tensor ID
            data: Binary tensor data
            chunk_index: Chunk index for large tensors
        """
        query = """
            INSERT INTO tensor_data (tensor_id, chunk_index, data_blob, chunk_size)
            VALUES (%s::uuid, %s, %s, %s)
            ON CONFLICT (tensor_id, chunk_index) DO UPDATE
            SET data_blob = EXCLUDED.data_blob, chunk_size = EXCLUDED.chunk_size
        """
        self.db.execute_command(query, (tensor_id, chunk_index, data, len(data)))


class ReactorRepository:
    """Repository for cognitive fusion reactor operations"""
    
    def __init__(self, db_connection: NeonDBConnection):
        self.db = db_connection
    
    def create_reactor(self, reactor_name: str, reactor_type: str,
                      fusion_strategy: str) -> str:
        """
        Create a new cognitive fusion reactor
        
        Args:
            reactor_name: Name of the reactor
            reactor_type: Type (ensemble, cascade, parallel, hierarchical)
            fusion_strategy: Strategy (weighted_average, voting, stacking, dynamic)
            
        Returns:
            UUID of created reactor
        """
        query = """
            INSERT INTO cognitive_fusion_reactors 
            (reactor_name, reactor_type, fusion_strategy)
            VALUES (%s, %s, %s)
            RETURNING reactor_id::text
        """
        result = self.db.execute_query(query, (reactor_name, reactor_type, fusion_strategy))
        return result[0]['reactor_id']
    
    def add_model_to_reactor(self, reactor_id: str, model_id: str,
                            model_role: str = 'primary', weight: float = 1.0) -> None:
        """
        Add a model to a reactor
        
        Args:
            reactor_id: Reactor ID
            model_id: Model ID to add
            model_role: Role of the model in the reactor
            weight: Weight in fusion ensemble
        """
        query = """
            INSERT INTO reactor_models (reactor_id, model_id, model_role, weight)
            VALUES (%s::uuid, %s::uuid, %s, %s)
        """
        self.db.execute_command(query, (reactor_id, model_id, model_role, weight))
    
    def get_reactor_status(self, reactor_id: str) -> Optional[Dict[str, Any]]:
        """Get reactor status from view"""
        query = "SELECT * FROM v_reactor_status WHERE reactor_id = %s::uuid"
        results = self.db.execute_query(query, (reactor_id,))
        return results[0] if results else None


# Example usage
if __name__ == "__main__":
    # Initialize connection
    db = NeonDBConnection()
    
    # Create repositories
    model_repo = ModelRepository(db)
    tensor_repo = TensorRepository(db)
    reactor_repo = ReactorRepository(db)
    
    # Example: Create a model
    # model_id = model_repo.create_model(
    #     model_name="gpt-fusion-1",
    #     model_type="transformer",
    #     architecture_config={
    #         "num_layers": 12,
    #         "hidden_size": 768,
    #         "num_attention_heads": 12
    #     },
    #     version="1.0.0"
    # )
    # print(f"Created model: {model_id}")
    
    # Close connections
    db.close_all()
