-- Arc-Halo Cognitive Fusion Reactor - Inference and Activation Schema
-- Part 4: Inference State and Activation Caching

-- Inference Sessions Table
-- Tracks inference runs for deployed models
CREATE TABLE IF NOT EXISTS inference_sessions (
    inference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    session_name VARCHAR(255),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    inference_config JSONB, -- Temperature, top_k, top_p, beam_size, etc.
    total_requests INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'active', -- active, completed, failed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for inference sessions
CREATE INDEX IF NOT EXISTS idx_inference_model ON inference_sessions(model_id);
CREATE INDEX IF NOT EXISTS idx_inference_status ON inference_sessions(status);

-- Activation Cache Table
-- Caches intermediate activations for specific inputs
CREATE TABLE IF NOT EXISTS activation_cache (
    cache_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    layer_id UUID REFERENCES transformer_layers(layer_id) ON DELETE CASCADE,
    input_hash VARCHAR(64) NOT NULL, -- Hash of input for cache key
    activation_tensor_id UUID REFERENCES tensor_metadata(tensor_id) ON DELETE CASCADE,
    cache_hit_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(model_id, layer_id, input_hash)
);

-- Create indexes for activation cache
CREATE INDEX IF NOT EXISTS idx_cache_model ON activation_cache(model_id);
CREATE INDEX IF NOT EXISTS idx_cache_layer ON activation_cache(layer_id);
CREATE INDEX IF NOT EXISTS idx_cache_hash ON activation_cache(input_hash);
CREATE INDEX IF NOT EXISTS idx_cache_expires ON activation_cache(expires_at);

-- KV Cache Table
-- Stores key-value pairs for attention mechanism during inference
CREATE TABLE IF NOT EXISTS kv_cache (
    kv_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inference_id UUID NOT NULL REFERENCES inference_sessions(inference_id) ON DELETE CASCADE,
    layer_id UUID NOT NULL REFERENCES transformer_layers(layer_id) ON DELETE CASCADE,
    sequence_position INTEGER NOT NULL,
    key_tensor_id UUID REFERENCES tensor_metadata(tensor_id) ON DELETE CASCADE,
    value_tensor_id UUID REFERENCES tensor_metadata(tensor_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(inference_id, layer_id, sequence_position)
);

-- Create indexes for KV cache
CREATE INDEX IF NOT EXISTS idx_kv_inference ON kv_cache(inference_id);
CREATE INDEX IF NOT EXISTS idx_kv_layer ON kv_cache(layer_id);

-- Inference Metrics Table
-- Stores performance metrics for inference operations
CREATE TABLE IF NOT EXISTS inference_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inference_id UUID NOT NULL REFERENCES inference_sessions(inference_id) ON DELETE CASCADE,
    request_id UUID,
    metric_type VARCHAR(100) NOT NULL, -- 'latency', 'throughput', 'tokens_per_second', 'memory_usage'
    metric_value DOUBLE PRECISION NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for inference metrics
CREATE INDEX IF NOT EXISTS idx_inference_metrics_session ON inference_metrics(inference_id);
CREATE INDEX IF NOT EXISTS idx_inference_metrics_type ON inference_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_inference_metrics_time ON inference_metrics(recorded_at);

-- Attention Patterns Table
-- Stores attention patterns for analysis and debugging
CREATE TABLE IF NOT EXISTS attention_patterns (
    pattern_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inference_id UUID REFERENCES inference_sessions(inference_id) ON DELETE CASCADE,
    layer_id UUID NOT NULL REFERENCES transformer_layers(layer_id) ON DELETE CASCADE,
    head_id UUID REFERENCES attention_heads(head_id) ON DELETE CASCADE,
    sequence_length INTEGER NOT NULL,
    attention_weights_id UUID REFERENCES tensor_metadata(tensor_id) ON DELETE CASCADE, -- Attention weight matrix
    input_tokens TEXT[], -- Array of input tokens for context
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for attention patterns
CREATE INDEX IF NOT EXISTS idx_attention_inference ON attention_patterns(inference_id);
CREATE INDEX IF NOT EXISTS idx_attention_layer ON attention_patterns(layer_id);
CREATE INDEX IF NOT EXISTS idx_attention_head ON attention_patterns(head_id);

-- Comments for documentation
COMMENT ON TABLE inference_sessions IS 'Tracks inference sessions for model deployment and serving';
COMMENT ON TABLE activation_cache IS 'Caches intermediate activations to speed up repeated computations';
COMMENT ON TABLE kv_cache IS 'Key-value cache for efficient autoregressive generation';
COMMENT ON TABLE inference_metrics IS 'Performance metrics for inference operations';
COMMENT ON TABLE attention_patterns IS 'Stores attention patterns for visualization and analysis';
