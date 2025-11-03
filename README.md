# Arc-Halo Cognitive Fusion Reactor

Integrate your application with the Arc-Halo platform. The **Arc-Halo Cognitive Fusion Reactor** is a sophisticated database-backed system for managing LLM transformer models with advanced tensor storage, training state management, and multi-model cognitive fusion capabilities.

## 🚀 Features

### Database-Backed LLM Infrastructure
- **Neon PostgreSQL Integration**: Scalable, serverless PostgreSQL database optimized for AI workloads
- **Tensor Storage**: Efficient storage and retrieval of model weights, embeddings, and activations
- **Training State Management**: Complete tracking of training sessions, metrics, and checkpoints
- **Inference Optimization**: KV-cache and activation caching for high-performance inference
- **Multi-Model Fusion**: Cognitive fusion reactor for ensemble and hierarchical model orchestration

### Schema Components

1. **Core Tables**: Model registry, transformer layers, and attention mechanisms
2. **Tensor Storage**: Metadata and binary storage for tensors with chunking support
3. **Training State**: Sessions, metrics, optimizer state, and checkpointing
4. **Inference & Cache**: Session management, KV-cache, and activation caching
5. **Cognitive Fusion**: Multi-model reactors with fusion strategies and interaction graphs

## 📦 Quick Start

### Prerequisites
- PostgreSQL client (psql)
- Python 3.8+ (for utilities)
- Neon database account ([sign up here](https://neon.tech))

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Cosmic-Construction/Arc-Halo.git
   cd Arc-Halo
   ```

2. **Configure database connection**
   ```bash
   cp db/config/.env.template db/config/.env
   # Edit .env with your Neon database credentials
   ```

3. **Run setup script**
   ```bash
   ./db/scripts/setup_database.sh
   ```

4. **Test connection**
   ```bash
   pip install -r db/requirements.txt
   python db/scripts/test_connection.py
   ```

See [db/QUICKSTART.md](db/QUICKSTART.md) for detailed setup instructions.

## 🏗️ Architecture

The Arc-Halo Cognitive Fusion Reactor is built on a comprehensive database schema designed for:

- **Model Architecture Management**: Store and version transformer model configurations
- **Tensor Operations**: Efficient tensor storage with support for large models (chunking, compression)
- **Training Lifecycle**: Complete training session tracking with metrics and checkpointing
- **Inference Pipeline**: Optimized caching strategies for production deployments
- **Cognitive Fusion**: Multi-model orchestration with configurable fusion strategies

```
┌─────────────────────────────────────────────────────────┐
│          Arc-Halo Cognitive Fusion Reactor              │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Models     │  │   Tensors    │  │   Training   │  │
│  │   Registry   │  │   Storage    │  │    State     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │  Inference   │  │   Cognitive  │                     │
│  │   & Cache    │  │    Fusion    │                     │
│  └──────────────┘  └──────────────┘                     │
│                                                          │
├─────────────────────────────────────────────────────────┤
│              Neon PostgreSQL Database                    │
└─────────────────────────────────────────────────────────┘
```

## 📚 Documentation

- [Quick Start Guide](db/QUICKSTART.md) - Get up and running quickly
- [Database README](db/README.md) - Comprehensive database documentation
- [Migration Guide](db/migrations/MIGRATION_GUIDE.md) - Schema management and migrations
- [GitHub Actions](.github/workflows/deploy-db-schema.yml) - Automated deployment workflow

## 🔧 Database Schema

### Core Tables
- `models` - Model registry and configuration
- `transformer_layers` - Layer definitions
- `attention_heads` - Multi-head attention specifications

### Tensor Storage
- `tensor_metadata` - Tensor shape, type, and metadata
- `tensor_data` - Binary tensor storage (chunked)
- `model_weights` - Weight management with gradient tracking
- `embeddings` - Token, position, and segment embeddings

### Training State
- `training_sessions` - Training run tracking
- `training_metrics` - Performance metrics
- `optimizer_state` - Adam, SGD, AdamW state
- `model_checkpoints` - Checkpoint management

### Inference & Cache
- `inference_sessions` - Inference tracking
- `activation_cache` - Activation caching
- `kv_cache` - Key-value cache for generation
- `attention_patterns` - Attention analysis

### Cognitive Fusion
- `cognitive_fusion_reactors` - Multi-model reactors
- `reactor_models` - Model-reactor mappings
- `fusion_operations` - Fusion tracking
- `model_interaction_graph` - Inter-model dependencies

## 🔐 Security

- Never commit `.env` files or database credentials
- Use GitHub Secrets for CI/CD workflows
- Enable SSL/TLS for all database connections
- Rotate credentials regularly
- See [Security Best Practices](db/QUICKSTART.md#security-best-practices)

## 🚀 GitHub Actions

Automated schema deployment via GitHub Actions:
- ✅ SQL syntax validation
- ✅ Local PostgreSQL testing
- ✅ Automated deployment to Neon
- ✅ Deployment reports

Configure `NEON_DATABASE_URL` secret in your repository settings.

## 🛠️ Development

### Python Utilities

```python
from db.scripts.db_utils import NeonDBConnection, ModelRepository

db = NeonDBConnection()
model_repo = ModelRepository(db)

# Create a model
model_id = model_repo.create_model(
    model_name="gpt-fusion-1",
    model_type="transformer",
    architecture_config={"num_layers": 12, "hidden_size": 768},
    version="1.0.0"
)
```

### Database Views

```sql
-- View model architecture
SELECT * FROM v_model_architecture WHERE model_name = 'gpt-fusion-1';

-- Check training progress
SELECT * FROM v_training_progress WHERE status = 'running';

-- Monitor reactor status
SELECT * FROM v_reactor_status WHERE status = 'active';
```

## 📊 Use Cases

- **LLM Model Management**: Version control for transformer models
- **Training Infrastructure**: Complete training lifecycle tracking
- **Inference Optimization**: Production-ready caching strategies
- **Model Ensembles**: Cognitive fusion for multi-model systems
- **Research Platform**: Experiment tracking and reproducibility

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:
1. Review the [Migration Guide](db/migrations/MIGRATION_GUIDE.md) for schema changes
2. Test changes locally before submitting PRs
3. Ensure GitHub Actions pass
4. Document new features

## 📝 License

This project is part of the Arc-Halo ecosystem.

## 🔗 Links

- [Neon Database](https://neon.tech) - Serverless PostgreSQL
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgvector Extension](https://github.com/pgvector/pgvector) - Vector similarity search

---

**Arc-Halo Cognitive Fusion Reactor** - Building the future of AI model orchestration 🧠⚡
