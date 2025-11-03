-- Arc-Halo Cognitive Fusion Reactor - Training State Schema
-- Part 3: Training State, Checkpoints, and Optimization

-- Training Sessions Table
-- Tracks individual training runs
CREATE TABLE IF NOT EXISTS training_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    session_name VARCHAR(255),
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'running', -- running, paused, completed, failed
    total_epochs INTEGER,
    current_epoch INTEGER DEFAULT 0,
    training_config JSONB NOT NULL, -- Learning rate, batch size, optimizer config, etc.
    dataset_info JSONB, -- Information about training dataset
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for training sessions
CREATE INDEX IF NOT EXISTS idx_training_model ON training_sessions(model_id);
CREATE INDEX IF NOT EXISTS idx_training_status ON training_sessions(status);

-- Training Metrics Table
-- Stores metrics for each training step/epoch
CREATE TABLE IF NOT EXISTS training_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES training_sessions(session_id) ON DELETE CASCADE,
    epoch INTEGER NOT NULL,
    step BIGINT NOT NULL,
    metric_type VARCHAR(100) NOT NULL, -- 'loss', 'accuracy', 'perplexity', 'learning_rate'
    metric_value DOUBLE PRECISION NOT NULL,
    metric_scope VARCHAR(50), -- 'train', 'validation', 'test'
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for metrics queries
CREATE INDEX IF NOT EXISTS idx_metrics_session ON training_metrics(session_id);
CREATE INDEX IF NOT EXISTS idx_metrics_type ON training_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_metrics_epoch ON training_metrics(epoch);

-- Optimizer State Table
-- Stores optimizer state (momentum, variance, etc.)
CREATE TABLE IF NOT EXISTS optimizer_state (
    state_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES training_sessions(session_id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    optimizer_type VARCHAR(100) NOT NULL, -- 'adam', 'sgd', 'adamw', 'rmsprop'
    learning_rate DOUBLE PRECISION,
    state_tensors JSONB NOT NULL, -- Maps weight names to optimizer state tensor IDs
    hyperparameters JSONB, -- Beta1, beta2, epsilon, weight_decay, etc.
    step_count BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for optimizer state
CREATE INDEX IF NOT EXISTS idx_optimizer_session ON optimizer_state(session_id);
CREATE INDEX IF NOT EXISTS idx_optimizer_model ON optimizer_state(model_id);

-- Model Checkpoints Table
-- Stores checkpoint metadata for model recovery
CREATE TABLE IF NOT EXISTS model_checkpoints (
    checkpoint_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    session_id UUID REFERENCES training_sessions(session_id) ON DELETE SET NULL,
    checkpoint_name VARCHAR(255) NOT NULL,
    epoch INTEGER,
    step BIGINT,
    checkpoint_type VARCHAR(50) DEFAULT 'full', -- 'full', 'weights_only', 'optimizer_only'
    storage_path TEXT, -- Path or URI to checkpoint storage
    checkpoint_size BIGINT, -- Size in bytes
    metrics_snapshot JSONB, -- Snapshot of key metrics at checkpoint time
    is_best BOOLEAN DEFAULT FALSE, -- Mark best checkpoint based on validation metric
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for checkpoints
CREATE INDEX IF NOT EXISTS idx_checkpoint_model ON model_checkpoints(model_id);
CREATE INDEX IF NOT EXISTS idx_checkpoint_session ON model_checkpoints(session_id);
CREATE INDEX IF NOT EXISTS idx_checkpoint_best ON model_checkpoints(is_best) WHERE is_best = TRUE;

-- Gradient Checkpointing Table
-- Stores information about gradient checkpointing for memory optimization
CREATE TABLE IF NOT EXISTS gradient_checkpoints (
    grad_checkpoint_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    layer_id UUID REFERENCES transformer_layers(layer_id) ON DELETE CASCADE,
    checkpoint_layer BOOLEAN DEFAULT FALSE, -- Whether this layer should be checkpointed
    recompute_strategy VARCHAR(100), -- 'full', 'selective', 'none'
    memory_saved_bytes BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for gradient checkpoints
CREATE INDEX IF NOT EXISTS idx_grad_checkpoint_model ON gradient_checkpoints(model_id);
CREATE INDEX IF NOT EXISTS idx_grad_checkpoint_layer ON gradient_checkpoints(layer_id);

-- Comments for documentation
COMMENT ON TABLE training_sessions IS 'Tracks individual training runs with configuration and status';
COMMENT ON TABLE training_metrics IS 'Time-series storage of training metrics per epoch/step';
COMMENT ON TABLE optimizer_state IS 'Stores optimizer state including momentum and variance tensors';
COMMENT ON TABLE model_checkpoints IS 'Checkpoint metadata for model recovery and versioning';
COMMENT ON TABLE gradient_checkpoints IS 'Configuration for gradient checkpointing memory optimization';
