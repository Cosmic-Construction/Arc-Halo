# Neon Database Configuration for Arc-Halo Cognitive Fusion Reactor

## Database Connection

This directory contains the database schema and configuration for the Arc-Halo Cognitive Fusion Reactor.

### Environment Variables Required

The following environment variables must be set to connect to your Neon database:

```bash
NEON_DATABASE_URL=postgresql://[user]:[password]@[host]/[database]?sslmode=require
NEON_HOST=your-project.neon.tech
NEON_DATABASE=arc_halo_db
NEON_USER=your_username
NEON_PASSWORD=your_password
```

### Neon Database Features

This schema is designed to leverage Neon's PostgreSQL-compatible features:

- **Branching**: Create database branches for development and testing
- **Vector Extension**: Optimized for embedding storage and similarity search
- **Autoscaling**: Automatically scales compute based on load
- **Point-in-time Recovery**: Restore to any point in time
- **Connection Pooling**: Efficient connection management for high-throughput workloads

## Schema Overview

The database schema is organized into 5 main components:

### 1. Core Tables (`01_core_tables.sql`)
- `models`: Model registry and configuration
- `transformer_layers`: Layer definitions and configurations
- `attention_heads`: Multi-head attention specifications

### 2. Tensor Storage (`02_tensor_storage.sql`)
- `tensor_metadata`: Tensor shape, type, and storage metadata
- `tensor_data`: Binary tensor data storage (chunked for large tensors)
- `model_weights`: Organized weight management with gradient tracking
- `embeddings`: Token, position, and segment embeddings

### 3. Training State (`03_training_state.sql`)
- `training_sessions`: Training run tracking
- `training_metrics`: Time-series metrics (loss, accuracy, etc.)
- `optimizer_state`: Optimizer state persistence (Adam, SGD, etc.)
- `model_checkpoints`: Checkpoint management
- `gradient_checkpoints`: Memory optimization configuration

### 4. Inference & Cache (`04_inference_cache.sql`)
- `inference_sessions`: Inference run tracking
- `activation_cache`: Intermediate activation caching
- `kv_cache`: Key-value cache for autoregressive generation
- `inference_metrics`: Performance metrics
- `attention_patterns`: Attention visualization data

### 5. Cognitive Fusion (`05_cognitive_fusion.sql`)
- `cognitive_fusion_reactors`: Multi-model fusion management
- `reactor_models`: Model-to-reactor mappings with weights
- `fusion_operations`: Fusion operation tracking
- `model_interaction_graph`: Inter-model dependencies
- `cognitive_state`: High-level cognitive state
- `reactor_metrics`: Reactor performance metrics

## Deployment

### Manual Deployment

1. Create a Neon project and database
2. Install required extensions:
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   ```
3. Run the master schema:
   ```bash
   psql $NEON_DATABASE_URL -f db/schema/00_master_schema.sql
   ```

### Automated Deployment (GitHub Actions)

The schema is automatically deployed via GitHub Actions workflow (`.github/workflows/deploy-db-schema.yml`).

To trigger deployment:
1. Push changes to the `main` branch or create a PR
2. The workflow will validate and deploy the schema
3. Secrets must be configured in GitHub repository settings:
   - `NEON_DATABASE_URL`
   - `NEON_API_KEY` (optional, for branch management)

## Database Views

### v_model_architecture
Complete view of model architecture with layers and weight counts.

```sql
SELECT * FROM v_model_architecture WHERE model_name = 'gpt-fusion-1';
```

### v_training_progress
Real-time training session progress and metrics.

```sql
SELECT * FROM v_training_progress WHERE status = 'running';
```

### v_reactor_status
Overview of cognitive fusion reactor status and performance.

```sql
SELECT * FROM v_reactor_status WHERE status = 'active';
```

## Helper Functions

### calculate_model_parameters(model_id)
Calculate total and trainable parameters for a model.

```sql
SELECT * FROM calculate_model_parameters('your-model-uuid');
```

### get_latest_checkpoint(model_id)
Get the most recent checkpoint for a model.

```sql
SELECT get_latest_checkpoint('your-model-uuid');
```

## Best Practices

1. **Use Connection Pooling**: Configure PgBouncer or use Neon's built-in pooling
2. **Chunk Large Tensors**: Use the tensor_data chunking system for tensors > 100MB
3. **Regular Checkpoints**: Save checkpoints every N epochs for recovery
4. **Monitor Metrics**: Use the metrics tables to track training and inference performance
5. **Clean Old Cache**: Implement TTL policies for activation_cache and kv_cache
6. **Index Optimization**: Additional indexes can be added based on query patterns

## Scaling Considerations

- **Tensor Storage**: Consider external blob storage (S3, GCS) for very large models
- **Time-series Data**: Training metrics may require partitioning for long training runs
- **Cache Expiration**: Implement automated cleanup for expired cache entries
- **Read Replicas**: Use Neon read replicas for analytics and monitoring queries

## Security

- Never commit database credentials to source control
- Use environment variables or secret management systems
- Enable SSL/TLS for all database connections
- Implement row-level security (RLS) if needed for multi-tenancy
- Regularly rotate database credentials
