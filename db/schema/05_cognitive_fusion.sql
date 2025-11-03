-- Arc-Halo Cognitive Fusion Reactor - Cognitive Fusion Schema
-- Part 5: Multi-Model Fusion and Cognitive Processing

-- Cognitive Fusion Reactor Table
-- Core table for the fusion reactor managing multiple model interactions
CREATE TABLE IF NOT EXISTS cognitive_fusion_reactors (
    reactor_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reactor_name VARCHAR(255) NOT NULL UNIQUE,
    reactor_type VARCHAR(100) NOT NULL, -- 'ensemble', 'cascade', 'parallel', 'hierarchical'
    fusion_strategy VARCHAR(100), -- 'weighted_average', 'voting', 'stacking', 'dynamic'
    status VARCHAR(50) DEFAULT 'initialized', -- initialized, active, inactive, error
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    config JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create index for reactor lookups
CREATE INDEX IF NOT EXISTS idx_reactor_name ON cognitive_fusion_reactors(reactor_name);
CREATE INDEX IF NOT EXISTS idx_reactor_status ON cognitive_fusion_reactors(status);

-- Reactor Models Table
-- Maps models to fusion reactors with their weights and roles
CREATE TABLE IF NOT EXISTS reactor_models (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reactor_id UUID NOT NULL REFERENCES cognitive_fusion_reactors(reactor_id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    model_role VARCHAR(100), -- 'primary', 'secondary', 'validator', 'specialist'
    weight DOUBLE PRECISION DEFAULT 1.0, -- Weight in fusion ensemble
    priority INTEGER DEFAULT 0, -- Priority order for cascade models
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(reactor_id, model_id)
);

-- Create indexes for reactor models
CREATE INDEX IF NOT EXISTS idx_reactor_models_reactor ON reactor_models(reactor_id);
CREATE INDEX IF NOT EXISTS idx_reactor_models_model ON reactor_models(model_id);
CREATE INDEX IF NOT EXISTS idx_reactor_models_active ON reactor_models(is_active);

-- Fusion Operations Table
-- Tracks individual fusion operations across models
CREATE TABLE IF NOT EXISTS fusion_operations (
    operation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reactor_id UUID NOT NULL REFERENCES cognitive_fusion_reactors(reactor_id) ON DELETE CASCADE,
    operation_type VARCHAR(100) NOT NULL, -- 'inference', 'training', 'evaluation'
    input_data JSONB, -- Input data or reference
    fusion_results JSONB, -- Aggregated results from all models
    participating_models UUID[], -- Array of model IDs
    operation_status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    execution_time_ms BIGINT,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for fusion operations
CREATE INDEX IF NOT EXISTS idx_fusion_ops_reactor ON fusion_operations(reactor_id);
CREATE INDEX IF NOT EXISTS idx_fusion_ops_status ON fusion_operations(operation_status);
CREATE INDEX IF NOT EXISTS idx_fusion_ops_type ON fusion_operations(operation_type);
CREATE INDEX IF NOT EXISTS idx_fusion_ops_time ON fusion_operations(started_at);

-- Model Interaction Graph Table
-- Tracks interactions and dependencies between models
CREATE TABLE IF NOT EXISTS model_interaction_graph (
    interaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reactor_id UUID NOT NULL REFERENCES cognitive_fusion_reactors(reactor_id) ON DELETE CASCADE,
    source_model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    target_model_id UUID NOT NULL REFERENCES models(model_id) ON DELETE CASCADE,
    interaction_type VARCHAR(100), -- 'feeds_into', 'validates', 'augments', 'corrects'
    interaction_weight DOUBLE PRECISION DEFAULT 1.0,
    data_flow_config JSONB, -- Configuration for data flow between models
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(reactor_id, source_model_id, target_model_id)
);

-- Create indexes for model interactions
CREATE INDEX IF NOT EXISTS idx_interaction_reactor ON model_interaction_graph(reactor_id);
CREATE INDEX IF NOT EXISTS idx_interaction_source ON model_interaction_graph(source_model_id);
CREATE INDEX IF NOT EXISTS idx_interaction_target ON model_interaction_graph(target_model_id);

-- Cognitive State Table
-- Stores high-level cognitive state across the fusion reactor
CREATE TABLE IF NOT EXISTS cognitive_state (
    state_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reactor_id UUID NOT NULL REFERENCES cognitive_fusion_reactors(reactor_id) ON DELETE CASCADE,
    state_type VARCHAR(100) NOT NULL, -- 'context', 'memory', 'attention_focus', 'goal'
    state_data JSONB NOT NULL,
    priority INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for cognitive state
CREATE INDEX IF NOT EXISTS idx_cognitive_state_reactor ON cognitive_state(reactor_id);
CREATE INDEX IF NOT EXISTS idx_cognitive_state_type ON cognitive_state(state_type);
CREATE INDEX IF NOT EXISTS idx_cognitive_state_expires ON cognitive_state(expires_at);

-- Reactor Metrics Table
-- Performance and health metrics for the fusion reactor
CREATE TABLE IF NOT EXISTS reactor_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reactor_id UUID NOT NULL REFERENCES cognitive_fusion_reactors(reactor_id) ON DELETE CASCADE,
    metric_type VARCHAR(100) NOT NULL, -- 'throughput', 'latency', 'accuracy', 'coherence', 'diversity'
    metric_value DOUBLE PRECISION NOT NULL,
    metric_scope VARCHAR(50), -- 'overall', 'model_specific', 'fusion_quality'
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for reactor metrics
CREATE INDEX IF NOT EXISTS idx_reactor_metrics_reactor ON reactor_metrics(reactor_id);
CREATE INDEX IF NOT EXISTS idx_reactor_metrics_type ON reactor_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_reactor_metrics_time ON reactor_metrics(recorded_at);

-- Comments for documentation
COMMENT ON TABLE cognitive_fusion_reactors IS 'Core fusion reactor managing multi-model cognitive processing';
COMMENT ON TABLE reactor_models IS 'Maps models to reactors with roles and fusion weights';
COMMENT ON TABLE fusion_operations IS 'Tracks individual fusion operations across multiple models';
COMMENT ON TABLE model_interaction_graph IS 'Defines interaction patterns and dependencies between models';
COMMENT ON TABLE cognitive_state IS 'High-level cognitive state management for the reactor';
COMMENT ON TABLE reactor_metrics IS 'Performance and quality metrics for fusion reactor operations';
