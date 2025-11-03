# Arc-Halo Cognitive Fusion Reactor - Usage Examples

This guide provides practical examples for working with the Arc-Halo database.

## Table of Contents
1. [Basic Model Management](#basic-model-management)
2. [Tensor Storage](#tensor-storage)
3. [Training Sessions](#training-sessions)
4. [Inference Operations](#inference-operations)
5. [Cognitive Fusion Reactors](#cognitive-fusion-reactors)
6. [Database Queries](#database-queries)

## Prerequisites

```bash
# Install dependencies
pip install -r db/requirements.txt

# Set environment variable
export NEON_DATABASE_URL="postgresql://user:pass@host/dbname"
```

## Basic Model Management

### Creating a Model

```python
from db.scripts.db_utils import NeonDBConnection, ModelRepository

# Initialize connection
db = NeonDBConnection()
model_repo = ModelRepository(db)

# Create a GPT-style model
model_id = model_repo.create_model(
    model_name="gpt-mini",
    model_type="transformer",
    architecture_config={
        "num_layers": 6,
        "hidden_size": 512,
        "num_attention_heads": 8,
        "intermediate_size": 2048,
        "vocab_size": 50257,
        "max_position_embeddings": 1024
    },
    version="1.0.0"
)

print(f"Created model: {model_id}")

# Clean up
db.close_all()
```

### Listing Models

```python
# List all models
models = model_repo.list_models()
for model in models:
    print(f"{model['model_name']}: {model['status']}")

# List only trained models
trained_models = model_repo.list_models(status='trained')
```

### Retrieving Model Details

```python
# Get specific model
model = model_repo.get_model(model_id)
print(f"Model: {model['model_name']}")
print(f"Type: {model['model_type']}")
print(f"Config: {model['architecture_config']}")
```

## Tensor Storage

### Storing Model Weights

```python
import numpy as np
from db.scripts.db_utils import TensorRepository

tensor_repo = TensorRepository(db)

# Create weight tensor metadata
weight_shape = [512, 512]  # Hidden size x Hidden size
tensor_id = tensor_repo.create_tensor(
    tensor_name="layer_0_attention_qkv_weight",
    tensor_type="weight",
    model_id=model_id,
    shape=weight_shape,
    dtype="float32"
)

# Store tensor data
weight_data = np.random.randn(*weight_shape).astype(np.float32)
tensor_bytes = weight_data.tobytes()
tensor_repo.store_tensor_data(tensor_id, tensor_bytes)

print(f"Stored weight tensor: {tensor_id}")
```

### Storing Embeddings

```python
# Token embeddings
vocab_size = 50257
embedding_dim = 512

token_embed_id = tensor_repo.create_tensor(
    tensor_name="token_embeddings",
    tensor_type="embedding",
    model_id=model_id,
    shape=[vocab_size, embedding_dim],
    dtype="float32"
)

# Position embeddings
max_positions = 1024
pos_embed_id = tensor_repo.create_tensor(
    tensor_name="position_embeddings",
    tensor_type="embedding",
    model_id=model_id,
    shape=[max_positions, embedding_dim],
    dtype="float32"
)
```

### Chunked Storage for Large Tensors

```python
# For very large tensors, store in chunks
large_tensor = np.random.randn(10000, 10000).astype(np.float32)
chunk_size = 1000 * 1000  # 1M elements per chunk

tensor_id = tensor_repo.create_tensor(
    tensor_name="large_weight_matrix",
    tensor_type="weight",
    model_id=model_id,
    shape=[10000, 10000],
    dtype="float32"
)

# Store in chunks
for chunk_idx in range(0, len(large_tensor.flatten()), chunk_size):
    chunk_data = large_tensor.flatten()[chunk_idx:chunk_idx+chunk_size]
    tensor_repo.store_tensor_data(
        tensor_id=tensor_id,
        data=chunk_data.tobytes(),
        chunk_index=chunk_idx // chunk_size
    )
```

## Training Sessions

### Starting a Training Session

```python
import json

# Create training session
query = """
    INSERT INTO training_sessions 
    (model_id, session_name, total_epochs, training_config, dataset_info)
    VALUES (%s::uuid, %s, %s, %s::jsonb, %s::jsonb)
    RETURNING session_id::text
"""

training_config = {
    "learning_rate": 0.0001,
    "batch_size": 32,
    "optimizer": "adam",
    "beta1": 0.9,
    "beta2": 0.999,
    "weight_decay": 0.01
}

dataset_info = {
    "name": "custom_dataset",
    "num_samples": 100000,
    "train_split": 0.8,
    "val_split": 0.1,
    "test_split": 0.1
}

result = db.execute_query(
    query,
    (model_id, "training_run_1", 10, json.dumps(training_config), json.dumps(dataset_info))
)
session_id = result[0]['session_id']
print(f"Started training session: {session_id}")
```

### Recording Training Metrics

```python
# Record loss for epoch 1, step 100
query = """
    INSERT INTO training_metrics
    (session_id, epoch, step, metric_type, metric_value, metric_scope)
    VALUES (%s::uuid, %s, %s, %s, %s, %s)
"""

db.execute_command(query, (session_id, 1, 100, 'loss', 2.5, 'train'))
db.execute_command(query, (session_id, 1, 100, 'accuracy', 0.65, 'train'))
db.execute_command(query, (session_id, 1, 100, 'perplexity', 12.18, 'train'))

# Validation metrics
db.execute_command(query, (session_id, 1, 100, 'loss', 2.3, 'validation'))
db.execute_command(query, (session_id, 1, 100, 'accuracy', 0.68, 'validation'))
```

### Creating Checkpoints

```python
# Save checkpoint
query = """
    INSERT INTO model_checkpoints
    (model_id, session_id, checkpoint_name, epoch, step, 
     checkpoint_type, metrics_snapshot, is_best)
    VALUES (%s::uuid, %s::uuid, %s, %s, %s, %s, %s::jsonb, %s)
    RETURNING checkpoint_id::text
"""

metrics_snapshot = {
    "train_loss": 2.5,
    "val_loss": 2.3,
    "train_accuracy": 0.65,
    "val_accuracy": 0.68
}

result = db.execute_query(
    query,
    (model_id, session_id, "checkpoint_epoch_1", 1, 100, 
     'full', json.dumps(metrics_snapshot), True)
)
checkpoint_id = result[0]['checkpoint_id']
print(f"Saved checkpoint: {checkpoint_id}")
```

## Inference Operations

### Starting an Inference Session

```python
# Create inference session
query = """
    INSERT INTO inference_sessions
    (model_id, session_name, inference_config)
    VALUES (%s::uuid, %s, %s::jsonb)
    RETURNING inference_id::text
"""

inference_config = {
    "temperature": 0.7,
    "top_k": 50,
    "top_p": 0.95,
    "max_new_tokens": 100,
    "do_sample": True
}

result = db.execute_query(
    query,
    (model_id, "inference_1", json.dumps(inference_config))
)
inference_id = result[0]['inference_id']
```

### Caching KV Pairs

```python
# Cache key-value pairs for attention
query = """
    INSERT INTO kv_cache
    (inference_id, layer_id, sequence_position, key_tensor_id, value_tensor_id)
    VALUES (%s::uuid, %s::uuid, %s, %s::uuid, %s::uuid)
"""

# For each layer and position
db.execute_command(
    query,
    (inference_id, layer_id, 0, key_tensor_id, value_tensor_id)
)
```

### Recording Inference Metrics

```python
# Record latency
query = """
    INSERT INTO inference_metrics
    (inference_id, metric_type, metric_value)
    VALUES (%s::uuid, %s, %s)
"""

db.execute_command(query, (inference_id, 'latency', 0.125))  # 125ms
db.execute_command(query, (inference_id, 'tokens_per_second', 80.0))
db.execute_command(query, (inference_id, 'memory_usage', 2048.0))  # MB
```

## Cognitive Fusion Reactors

### Creating a Reactor

```python
from db.scripts.db_utils import ReactorRepository

reactor_repo = ReactorRepository(db)

# Create ensemble reactor
reactor_id = reactor_repo.create_reactor(
    reactor_name="multi-model-ensemble",
    reactor_type="ensemble",
    fusion_strategy="weighted_average"
)

print(f"Created reactor: {reactor_id}")
```

### Adding Models to Reactor

```python
# Add primary model
reactor_repo.add_model_to_reactor(
    reactor_id=reactor_id,
    model_id=model_id_1,
    model_role="primary",
    weight=0.6
)

# Add secondary model
reactor_repo.add_model_to_reactor(
    reactor_id=reactor_id,
    model_id=model_id_2,
    model_role="secondary",
    weight=0.4
)
```

### Creating Model Interactions

```python
# Define interaction between models
query = """
    INSERT INTO model_interaction_graph
    (reactor_id, source_model_id, target_model_id, interaction_type, interaction_weight)
    VALUES (%s::uuid, %s::uuid, %s::uuid, %s, %s)
"""

db.execute_command(
    query,
    (reactor_id, model_id_1, model_id_2, 'validates', 0.8)
)
```

### Executing Fusion Operations

```python
# Record fusion operation
query = """
    INSERT INTO fusion_operations
    (reactor_id, operation_type, input_data, participating_models, operation_status)
    VALUES (%s::uuid, %s, %s::jsonb, %s::uuid[], %s)
    RETURNING operation_id::text
"""

input_data = {"prompt": "Once upon a time", "max_tokens": 50}

result = db.execute_query(
    query,
    (reactor_id, 'inference', json.dumps(input_data), 
     [model_id_1, model_id_2], 'processing')
)
operation_id = result[0]['operation_id']
```

## Database Queries

### View Model Architecture

```sql
-- Get complete model architecture
SELECT * FROM v_model_architecture 
WHERE model_name = 'gpt-mini';

-- Count parameters
SELECT * FROM calculate_model_parameters('model_id_here');
```

### Monitor Training Progress

```sql
-- View all active training sessions
SELECT * FROM v_training_progress 
WHERE status = 'running'
ORDER BY updated_at DESC;

-- Get metrics for a session
SELECT 
    epoch,
    step,
    metric_type,
    metric_value,
    metric_scope,
    recorded_at
FROM training_metrics
WHERE session_id = 'session_id_here'
ORDER BY epoch DESC, step DESC, metric_type;
```

### Check Reactor Status

```sql
-- View reactor overview
SELECT * FROM v_reactor_status
WHERE status = 'active';

-- Get reactor models
SELECT 
    m.model_name,
    rm.model_role,
    rm.weight,
    rm.is_active
FROM reactor_models rm
JOIN models m ON rm.model_id = m.model_id
WHERE rm.reactor_id = 'reactor_id_here'
ORDER BY rm.weight DESC;
```

### Analyze Inference Performance

```sql
-- Average inference metrics
SELECT 
    metric_type,
    AVG(metric_value) as avg_value,
    MIN(metric_value) as min_value,
    MAX(metric_value) as max_value
FROM inference_metrics
WHERE inference_id = 'inference_id_here'
GROUP BY metric_type;
```

### Find Latest Checkpoint

```sql
-- Get latest checkpoint for a model
SELECT get_latest_checkpoint('model_id_here');

-- Get best checkpoint based on metrics
SELECT 
    checkpoint_id,
    checkpoint_name,
    epoch,
    step,
    metrics_snapshot,
    created_at
FROM model_checkpoints
WHERE model_id = 'model_id_here' AND is_best = true
ORDER BY created_at DESC
LIMIT 1;
```

## Advanced Examples

### Batch Operations

```python
# Batch insert multiple metrics
from psycopg2.extras import execute_batch

conn = db.get_connection()
try:
    with conn.cursor() as cursor:
        metrics_data = [
            (session_id, 1, i, 'loss', 2.5 - i*0.01, 'train')
            for i in range(100)
        ]
        
        execute_batch(
            cursor,
            """INSERT INTO training_metrics 
               (session_id, epoch, step, metric_type, metric_value, metric_scope)
               VALUES (%s::uuid, %s, %s, %s, %s, %s)""",
            metrics_data
        )
    conn.commit()
finally:
    db.return_connection(conn)
```

### Transaction Example

```python
# Create model and tensors in a transaction
conn = db.get_connection()
try:
    with conn.cursor() as cursor:
        # Start transaction
        cursor.execute("BEGIN")
        
        # Create model
        cursor.execute(
            "INSERT INTO models (...) VALUES (...) RETURNING model_id"
        )
        model_id = cursor.fetchone()[0]
        
        # Create tensors
        cursor.execute(
            "INSERT INTO tensor_metadata (...) VALUES (...)"
        )
        
        # Commit transaction
        cursor.execute("COMMIT")
except Exception as e:
    cursor.execute("ROLLBACK")
    raise
finally:
    db.return_connection(conn)
```

## Cleanup

```python
# Always close connections when done
db.close_all()
```

## Next Steps

- Review [QUICKSTART.md](QUICKSTART.md) for setup instructions
- Check [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) for architecture details
- See [MIGRATION_GUIDE.md](migrations/MIGRATION_GUIDE.md) for schema changes
- Explore [db_utils.py](scripts/db_utils.py) for more utilities

---

For more examples, see the [example_init.py](scripts/example_init.py) script.
