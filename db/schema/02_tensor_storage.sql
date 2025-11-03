-- Arc-Halo Cognitive Fusion Reactor - Tensor Storage Schema
-- Part 2: Tensor Storage and Weight Management

-- Tensor Metadata Table
-- Stores metadata about tensors (weights, biases, activations)
CREATE TABLE IF NOT EXISTS tensor_metadata (
    tensor_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tensor_name VARCHAR(255) NOT NULL,
    tensor_type VARCHAR(100) NOT NULL, -- 'weight', 'bias', 'embedding', 'activation'
    model_id UUID REFERENCES models(model_id) ON DELETE CASCADE,
    layer_id UUID REFERENCES transformer_layers(layer_id) ON DELETE CASCADE,
    shape INTEGER[] NOT NULL, -- Array representing tensor dimensions
    dtype VARCHAR(50) NOT NULL DEFAULT 'float32', -- Data type: float32, float16, int32, etc.
    total_elements BIGINT NOT NULL, -- Total number of elements in tensor
    storage_format VARCHAR(50) DEFAULT 'dense', -- dense, sparse, quantized
    compression_type VARCHAR(50), -- None, gzip, lz4, etc.
    checksum VARCHAR(64), -- SHA256 checksum for integrity
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for tensor metadata
CREATE INDEX IF NOT EXISTS idx_tensor_model ON tensor_metadata(model_id);
CREATE INDEX IF NOT EXISTS idx_tensor_layer ON tensor_metadata(layer_id);
CREATE INDEX IF NOT EXISTS idx_tensor_type ON tensor_metadata(tensor_type);
CREATE INDEX IF NOT EXISTS idx_tensor_name ON tensor_metadata(tensor_name);

-- Tensor Data Storage Table
-- Stores actual tensor data in chunks for large tensors
CREATE TABLE IF NOT EXISTS tensor_data (
    data_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tensor_id UUID NOT NULL REFERENCES tensor_metadata(tensor_id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL DEFAULT 0, -- For splitting large tensors
    data_blob BYTEA NOT NULL, -- Actual binary tensor data
    chunk_shape INTEGER[], -- Shape of this specific chunk
    chunk_size BIGINT NOT NULL, -- Size in bytes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tensor_id, chunk_index)
);

-- Create index for efficient tensor data retrieval
CREATE INDEX IF NOT EXISTS idx_tensor_data_tensor ON tensor_data(tensor_id);

-- Model Weights Table (Denormalized for quick access)
-- Aggregated view of all weights for a model
CREATE TABLE IF NOT EXISTS model_weights (
    weight_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    layer_id UUID REFERENCES transformer_layers(layer_id) ON DELETE CASCADE,
    weight_name VARCHAR(255) NOT NULL, -- e.g., 'W_q', 'W_k', 'W_v', 'W_o', 'fc1', 'fc2'
    tensor_id UUID NOT NULL REFERENCES tensor_metadata(tensor_id) ON DELETE CASCADE,
    weight_category VARCHAR(100), -- 'attention', 'feedforward', 'embedding', 'normalization'
    is_trainable BOOLEAN DEFAULT TRUE,
    gradient_tensor_id UUID REFERENCES tensor_metadata(tensor_id), -- Reference to gradient tensor
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(model_id, layer_id, weight_name)
);

-- Create indexes for model weights
CREATE INDEX IF NOT EXISTS idx_weights_model ON model_weights(model_id);
CREATE INDEX IF NOT EXISTS idx_weights_layer ON model_weights(layer_id);
CREATE INDEX IF NOT EXISTS idx_weights_category ON model_weights(weight_category);

-- Embeddings Table
-- Special table for embedding layers with vector search capabilities
CREATE TABLE IF NOT EXISTS embeddings (
    embedding_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    embedding_type VARCHAR(100) NOT NULL, -- 'token', 'position', 'segment'
    vocab_size INTEGER,
    embedding_dim INTEGER NOT NULL,
    tensor_id UUID NOT NULL REFERENCES tensor_metadata(tensor_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create index for embeddings
CREATE INDEX IF NOT EXISTS idx_embeddings_model ON embeddings(model_id);
CREATE INDEX IF NOT EXISTS idx_embeddings_type ON embeddings(embedding_type);

-- Comments for documentation
COMMENT ON TABLE tensor_metadata IS 'Metadata about tensors including shape, type, and storage information';
COMMENT ON TABLE tensor_data IS 'Binary storage for tensor data, chunked for large tensors';
COMMENT ON TABLE model_weights IS 'Organized view of model weights with trainability and gradient tracking';
COMMENT ON TABLE embeddings IS 'Embedding layers for token, position, and segment embeddings';
