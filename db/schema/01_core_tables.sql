-- Arc-Halo Cognitive Fusion Reactor - Core Database Schema
-- Part 1: Core Tables for LLM Transformer Model Architecture

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Model Registry Table
-- Tracks different transformer models and their configurations
CREATE TABLE IF NOT EXISTS models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(255) NOT NULL UNIQUE,
    model_type VARCHAR(100) NOT NULL, -- e.g., 'transformer', 'gpt', 'bert'
    architecture_config JSONB NOT NULL, -- Stores model architecture parameters
    version VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'initialized', -- initialized, training, trained, deployed
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create index for model lookups
CREATE INDEX IF NOT EXISTS idx_models_name ON models(model_name);
CREATE INDEX IF NOT EXISTS idx_models_status ON models(status);

-- Transformer Layers Table
-- Stores configuration for each layer in the transformer model
CREATE TABLE IF NOT EXISTS transformer_layers (
    layer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    layer_index INTEGER NOT NULL,
    layer_type VARCHAR(100) NOT NULL, -- e.g., 'attention', 'feedforward', 'embedding', 'normalization'
    layer_config JSONB NOT NULL, -- Layer-specific configuration
    input_dim INTEGER NOT NULL,
    output_dim INTEGER NOT NULL,
    num_heads INTEGER, -- For attention layers
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(model_id, layer_index)
);

-- Create indexes for layer queries
CREATE INDEX IF NOT EXISTS idx_layers_model ON transformer_layers(model_id);
CREATE INDEX IF NOT EXISTS idx_layers_type ON transformer_layers(layer_type);

-- Attention Heads Table
-- Tracks individual attention heads within multi-head attention layers
CREATE TABLE IF NOT EXISTS attention_heads (
    head_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    layer_id UUID NOT NULL REFERENCES transformer_layers(layer_id) ON DELETE CASCADE,
    head_index INTEGER NOT NULL,
    head_dim INTEGER NOT NULL,
    query_weight_id UUID, -- Reference to tensor_weights table
    key_weight_id UUID,
    value_weight_id UUID,
    output_weight_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(layer_id, head_index)
);

-- Create index for attention head queries
CREATE INDEX IF NOT EXISTS idx_heads_layer ON attention_heads(layer_id);

-- Comments for documentation
COMMENT ON TABLE models IS 'Registry of transformer models in the Cognitive Fusion Reactor';
COMMENT ON TABLE transformer_layers IS 'Configuration and metadata for each layer in transformer models';
COMMENT ON TABLE attention_heads IS 'Individual attention heads within multi-head attention mechanisms';
