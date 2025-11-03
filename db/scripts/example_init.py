"""
Arc-Halo Cognitive Fusion Reactor - Example Model Initialization
Demonstrates how to initialize a simple transformer model in the database
"""

import os
import json
from db.scripts.db_utils import (
    NeonDBConnection,
    ModelRepository,
    TensorRepository,
    ReactorRepository
)


def create_example_transformer_model():
    """Create an example transformer model with basic architecture"""
    
    # Initialize database connection
    db = NeonDBConnection()
    
    try:
        # Create repositories
        model_repo = ModelRepository(db)
        tensor_repo = TensorRepository(db)
        reactor_repo = ReactorRepository(db)
        
        print("="*60)
        print("Arc-Halo Cognitive Fusion Reactor - Example Initialization")
        print("="*60)
        
        # 1. Create a transformer model
        print("\n1. Creating transformer model...")
        model_config = {
            "num_layers": 6,
            "hidden_size": 512,
            "num_attention_heads": 8,
            "intermediate_size": 2048,
            "max_position_embeddings": 1024,
            "vocab_size": 50000,
            "dropout": 0.1,
            "attention_dropout": 0.1
        }
        
        model_id = model_repo.create_model(
            model_name="example-gpt-small",
            model_type="transformer",
            architecture_config=model_config,
            version="1.0.0"
        )
        
        print(f"   ✓ Created model: {model_id}")
        print(f"   - Name: example-gpt-small")
        print(f"   - Layers: {model_config['num_layers']}")
        print(f"   - Hidden size: {model_config['hidden_size']}")
        print(f"   - Attention heads: {model_config['num_attention_heads']}")
        
        # 2. Create embedding tensors
        print("\n2. Creating embedding tensors...")
        
        # Token embedding
        token_embed_id = tensor_repo.create_tensor(
            tensor_name="token_embeddings",
            tensor_type="embedding",
            model_id=model_id,
            shape=[model_config['vocab_size'], model_config['hidden_size']],
            dtype="float32"
        )
        print(f"   ✓ Created token embeddings: {token_embed_id}")
        print(f"   - Shape: [{model_config['vocab_size']}, {model_config['hidden_size']}]")
        
        # Position embedding
        pos_embed_id = tensor_repo.create_tensor(
            tensor_name="position_embeddings",
            tensor_type="embedding",
            model_id=model_id,
            shape=[model_config['max_position_embeddings'], model_config['hidden_size']],
            dtype="float32"
        )
        print(f"   ✓ Created position embeddings: {pos_embed_id}")
        print(f"   - Shape: [{model_config['max_position_embeddings']}, {model_config['hidden_size']}]")
        
        # 3. Create a cognitive fusion reactor
        print("\n3. Creating cognitive fusion reactor...")
        
        reactor_id = reactor_repo.create_reactor(
            reactor_name="example-ensemble-reactor",
            reactor_type="ensemble",
            fusion_strategy="weighted_average"
        )
        
        print(f"   ✓ Created reactor: {reactor_id}")
        print(f"   - Type: ensemble")
        print(f"   - Strategy: weighted_average")
        
        # 4. Add model to reactor
        print("\n4. Adding model to reactor...")
        
        reactor_repo.add_model_to_reactor(
            reactor_id=reactor_id,
            model_id=model_id,
            model_role="primary",
            weight=1.0
        )
        
        print(f"   ✓ Added model to reactor")
        print(f"   - Role: primary")
        print(f"   - Weight: 1.0")
        
        # 5. Verify creation
        print("\n5. Verifying creation...")
        
        model_info = model_repo.get_model(model_id)
        if model_info:
            print(f"   ✓ Model verified in database")
            print(f"   - Status: {model_info['status']}")
            print(f"   - Created: {model_info['created_at']}")
        
        reactor_status = reactor_repo.get_reactor_status(reactor_id)
        if reactor_status:
            print(f"   ✓ Reactor verified in database")
            print(f"   - Active models: {reactor_status.get('active_models', 0)}")
        
        print("\n" + "="*60)
        print("Initialization Complete!")
        print("="*60)
        print("\nYour example model and reactor are ready for use.")
        print("\nNext steps:")
        print("  - Add more models to the reactor")
        print("  - Create training sessions")
        print("  - Start inference operations")
        print("  - Monitor with database views (v_model_architecture, v_reactor_status)")
        
        return {
            "model_id": model_id,
            "reactor_id": reactor_id,
            "token_embed_id": token_embed_id,
            "pos_embed_id": pos_embed_id
        }
        
    except Exception as e:
        print(f"\n❌ Error during initialization: {e}")
        raise
    finally:
        db.close_all()


if __name__ == "__main__":
    # Check if database URL is set
    if not os.getenv('NEON_DATABASE_URL'):
        print("Error: NEON_DATABASE_URL environment variable not set")
        print("Please set it with your Neon database connection string")
        print("Example: export NEON_DATABASE_URL='postgresql://user:pass@host/db'")
        exit(1)
    
    # Run the example
    result = create_example_transformer_model()
    
    print("\n📋 Created Resources:")
    print(json.dumps(result, indent=2))
