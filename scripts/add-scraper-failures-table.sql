-- Migration: Add scraper_failures table for tracking individual scraper errors
-- This table allows us to track which specific mountains are failing and why

-- Create scraper_failures table
CREATE TABLE IF NOT EXISTS scraper_failures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id VARCHAR(100) NOT NULL,
    mountain_id VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    source_url TEXT,
    failed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Foreign key to scraper_runs (cascade delete when run is deleted)
    CONSTRAINT fk_scraper_failures_run
        FOREIGN KEY (run_id)
        REFERENCES scraper_runs(run_id)
        ON DELETE CASCADE,

    -- Ensure one failure per mountain per run
    CONSTRAINT scraper_failures_run_mountain_key
        UNIQUE (run_id, mountain_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_scraper_failures_mountain
    ON scraper_failures(mountain_id);

CREATE INDEX IF NOT EXISTS idx_scraper_failures_failed_at
    ON scraper_failures(failed_at DESC);

CREATE INDEX IF NOT EXISTS idx_scraper_failures_run_id
    ON scraper_failures(run_id);

-- Add comment
COMMENT ON TABLE scraper_failures IS 'Tracks individual scraper failures for monitoring and debugging';

-- Grant permissions (adjust based on your database user)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON scraper_failures TO your_app_user;
