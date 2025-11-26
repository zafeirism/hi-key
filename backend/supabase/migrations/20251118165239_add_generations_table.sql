-- =====================================================
-- hi-key generations table
-- Tracks all AI image generations
-- =====================================================

CREATE TABLE generations (
  -- Primary identification
  id text PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  user_id text,
  session_id text,
  request_id text,
  
  -- Prompts
  user_prompt text,
  improved_prompt text,
  text_in_image jsonb,
  
  -- Generation metadata
  model text,
  file_extension text,
  file_size_bytes integer,
  cost_usd_mills integer,
    
  -- Status tracking
  status text,
  error_message text,
  
  -- User behavior analytics
  copied_at timestamptz,
  shared_at timestamptz,
  
  -- Performance tracking
  generation_duration_ms integer,
  upsampling_duration_ms integer,
  total_duration_ms integer,

  generation_started_at timestamptz,

  -- Comments
  comments jsonb
);

-- =====================================================
-- Indexes for query performance
-- =====================================================

-- Most common query: Get user's recent generations
CREATE INDEX idx_generations_user_id 
ON generations(user_id);

-- Analytics: Track generations per day
CREATE INDEX idx_generations_created_at
ON generations(created_at DESC);

-- Admin/debugging: Filter by status
CREATE INDEX idx_generations_status 
ON generations(status) WHERE status IS NOT NULL;

-- =====================================================
-- Row Level Security (RLS)
-- Enable RLS but don't create policies yet
-- This prevents iOS from accessing this table directly
-- =====================================================

ALTER TABLE generations ENABLE ROW LEVEL SECURITY;

-- No policies = no direct access from client
-- Only service role (backend) can read/write

-- =====================================================
-- Comments for documentation
-- =====================================================

COMMENT ON TABLE generations IS 'AI image generations - one row per generated image';
COMMENT ON COLUMN generations.session_id IS 'Unique per keyboard session - resets when user opens keyboard';
COMMENT ON COLUMN generations.request_id IS 'Multiple images share same request_id (generated together)';
COMMENT ON COLUMN generations.cost_usd_mills IS 'Cost in mills (15 = $0.015)';
COMMENT ON COLUMN generations.text_in_image IS 'JSON array of text phrases to include in image';
COMMENT ON COLUMN generations.comments IS 'Additional data for debugging';