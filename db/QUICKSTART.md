# Arc-Halo Cognitive Fusion Reactor - Quick Start Guide

## Overview

The Arc-Halo Cognitive Fusion Reactor is a database-backed system for managing LLM transformer models with tensor storage, training state management, and multi-model cognitive fusion capabilities.

## Prerequisites

- PostgreSQL client (psql) installed
- Python 3.8+ (for utility scripts)
- A Neon database account and project

## Quick Setup

### 1. Create a Neon Database

1. Sign up at [Neon](https://neon.tech)
2. Create a new project
3. Note your connection string (format: `postgresql://user:pass@host/dbname`)

### 2. Configure Environment

```bash
# Copy the environment template
cp db/config/.env.template db/config/.env

# Edit the .env file with your Neon credentials
nano db/config/.env
```

### 3. Run Setup Script

```bash
# Make sure you're in the repository root
cd /path/to/Arc-Halo

# Run the setup script
./db/scripts/setup_database.sh
```

The script will:
- ✅ Test your database connection
- ✅ Install required PostgreSQL extensions
- ✅ Deploy all schema files
- ✅ Verify the installation
- ✅ Optionally create sample data

## Manual Setup

If you prefer manual setup:

```bash
# Set your database URL
export NEON_DATABASE_URL="postgresql://user:pass@host/dbname"

# Install extensions
psql $NEON_DATABASE_URL -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
psql $NEON_DATABASE_URL -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Apply schema files
psql $NEON_DATABASE_URL -f db/schema/01_core_tables.sql
psql $NEON_DATABASE_URL -f db/schema/02_tensor_storage.sql
psql $NEON_DATABASE_URL -f db/schema/03_training_state.sql
psql $NEON_DATABASE_URL -f db/schema/04_inference_cache.sql
psql $NEON_DATABASE_URL -f db/schema/05_cognitive_fusion.sql
```

## Using Python Utilities

```bash
# Install Python dependencies
pip install -r db/requirements.txt

# Set environment variable
export NEON_DATABASE_URL="postgresql://user:pass@host/dbname"
```

Example Python usage:

```python
from db.scripts.db_utils import NeonDBConnection, ModelRepository, ReactorRepository

# Initialize connection
db = NeonDBConnection()

# Create repositories
model_repo = ModelRepository(db)
reactor_repo = ReactorRepository(db)

# Create a model
model_id = model_repo.create_model(
    model_name="gpt-fusion-alpha",
    model_type="transformer",
    architecture_config={
        "num_layers": 12,
        "hidden_size": 768,
        "num_attention_heads": 12,
        "intermediate_size": 3072
    },
    version="1.0.0"
)

# Create a cognitive fusion reactor
reactor_id = reactor_repo.create_reactor(
    reactor_name="alpha-reactor",
    reactor_type="ensemble",
    fusion_strategy="weighted_average"
)

# Add model to reactor
reactor_repo.add_model_to_reactor(
    reactor_id=reactor_id,
    model_id=model_id,
    model_role="primary",
    weight=1.0
)

# Clean up
db.close_all()
```

## GitHub Actions Setup

For automated deployments via GitHub Actions:

1. Go to your repository settings
2. Navigate to Secrets and Variables → Actions
3. Add a new secret:
   - Name: `NEON_DATABASE_URL`
   - Value: Your Neon database connection string

The workflow will automatically:
- ✅ Validate SQL syntax on PRs
- ✅ Test schema with local PostgreSQL
- ✅ Deploy to Neon on push to main
- ✅ Generate deployment reports

## Database Schema Components

### Core Tables (01_core_tables.sql)
- **models**: Model registry
- **transformer_layers**: Layer configurations
- **attention_heads**: Attention mechanisms

### Tensor Storage (02_tensor_storage.sql)
- **tensor_metadata**: Tensor information
- **tensor_data**: Binary tensor storage
- **model_weights**: Weight management
- **embeddings**: Embedding layers

### Training State (03_training_state.sql)
- **training_sessions**: Training runs
- **training_metrics**: Performance metrics
- **optimizer_state**: Optimizer state
- **model_checkpoints**: Checkpoints
- **gradient_checkpoints**: Memory optimization

### Inference & Cache (04_inference_cache.sql)
- **inference_sessions**: Inference runs
- **activation_cache**: Activation caching
- **kv_cache**: Key-value cache
- **inference_metrics**: Performance metrics
- **attention_patterns**: Attention analysis

### Cognitive Fusion (05_cognitive_fusion.sql)
- **cognitive_fusion_reactors**: Reactor management
- **reactor_models**: Model-reactor mapping
- **fusion_operations**: Fusion tracking
- **model_interaction_graph**: Model interactions
- **cognitive_state**: Cognitive state
- **reactor_metrics**: Reactor metrics

## Common Operations

### Query Model Architecture

```sql
SELECT * FROM v_model_architecture WHERE model_name = 'your-model';
```

### Check Training Progress

```sql
SELECT * FROM v_training_progress WHERE status = 'running';
```

### View Reactor Status

```sql
SELECT * FROM v_reactor_status WHERE status = 'active';
```

### Calculate Model Parameters

```sql
SELECT * FROM calculate_model_parameters('model-uuid');
```

## Troubleshooting

### Connection Issues

If you can't connect to Neon:
1. Verify your connection string in `.env`
2. Check if your IP is whitelisted (if IP restrictions are enabled)
3. Ensure SSL mode is set to `require`

### Extension Issues

If `vector` extension fails:
1. Check if it's enabled in your Neon project settings
2. Some extensions may require specific Neon plan tiers

### Schema Deployment Failures

If schema deployment fails:
1. Check PostgreSQL logs for specific errors
2. Ensure you have sufficient privileges
3. Verify all schema files are present

## Security Best Practices

1. ✅ Never commit `.env` files
2. ✅ Rotate database credentials regularly
3. ✅ Use connection pooling
4. ✅ Enable SSL/TLS for connections
5. ✅ Implement row-level security if needed
6. ✅ Monitor database access logs

## Next Steps

1. Review the detailed documentation in `db/README.md`
2. Explore the schema files to understand the data model
3. Test the Python utilities with sample data
4. Set up monitoring and alerting
5. Configure backups and disaster recovery

## Support

For issues or questions:
- Review the documentation in `db/README.md`
- Check the GitHub Actions logs for deployment issues
- Consult Neon documentation for database-specific questions

---

**Arc-Halo Cognitive Fusion Reactor** - Building the future of AI model orchestration 🚀
