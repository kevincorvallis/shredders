-- Mountain Scraper Database Schema
-- PostgreSQL 15.4+

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables (for clean setup)
DROP TABLE IF EXISTS scraper_runs CASCADE;
DROP TABLE IF EXISTS mountain_status CASCADE;

-- Mountain status table (stores scraped data)
CREATE TABLE mountain_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mountain_id VARCHAR(50) NOT NULL,

    -- Status data
    is_open BOOLEAN NOT NULL DEFAULT false,
    percent_open INTEGER CHECK (percent_open >= 0 AND percent_open <= 100),

    -- Lifts
    lifts_open INTEGER DEFAULT 0 CHECK (lifts_open >= 0),
    lifts_total INTEGER DEFAULT 0 CHECK (lifts_total >= 0),

    -- Runs
    runs_open INTEGER DEFAULT 0 CHECK (runs_open >= 0),
    runs_total INTEGER DEFAULT 0 CHECK (runs_total >= 0),

    -- Message
    message TEXT,
    conditions_message TEXT,

    -- Metadata
    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    source_url TEXT,
    scraper_version VARCHAR(20) DEFAULT '1.0.0',

    -- Indexes
    CONSTRAINT mountain_status_mountain_id_scraped_at_key UNIQUE (mountain_id, scraped_at)
);

-- Scraper run tracking table (for monitoring)
CREATE TABLE scraper_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id VARCHAR(100) UNIQUE NOT NULL,

    -- Stats
    total_mountains INTEGER NOT NULL,
    successful_count INTEGER NOT NULL DEFAULT 0,
    failed_count INTEGER NOT NULL DEFAULT 0,

    -- Timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_ms INTEGER,

    -- Status
    status VARCHAR(20) CHECK (status IN ('running', 'completed', 'failed')) DEFAULT 'running',
    error_message TEXT,

    -- Metadata
    triggered_by VARCHAR(50) DEFAULT 'manual',  -- manual, cron, github-actions
    environment VARCHAR(20) DEFAULT 'production'
);

-- Indexes for performance
CREATE INDEX idx_mountain_status_mountain_id ON mountain_status(mountain_id);
CREATE INDEX idx_mountain_status_scraped_at ON mountain_status(scraped_at DESC);
CREATE INDEX idx_mountain_status_mountain_date ON mountain_status(mountain_id, scraped_at DESC);
CREATE INDEX idx_scraper_runs_started_at ON scraper_runs(started_at DESC);
CREATE INDEX idx_scraper_runs_status ON scraper_runs(status);

-- View for latest status per mountain
CREATE OR REPLACE VIEW latest_mountain_status AS
SELECT DISTINCT ON (mountain_id)
    mountain_id,
    is_open,
    percent_open,
    lifts_open,
    lifts_total,
    runs_open,
    runs_total,
    message,
    conditions_message,
    scraped_at,
    source_url
FROM mountain_status
ORDER BY mountain_id, scraped_at DESC;

-- View for scraper run statistics
CREATE OR REPLACE VIEW scraper_stats AS
SELECT
    DATE_TRUNC('day', started_at) as run_date,
    COUNT(*) as total_runs,
    AVG(successful_count) as avg_successful,
    AVG(failed_count) as avg_failed,
    AVG(duration_ms) as avg_duration_ms,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_runs
FROM scraper_runs
GROUP BY DATE_TRUNC('day', started_at)
ORDER BY run_date DESC;

-- Function to clean old data (keep last 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_mountain_status()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM mountain_status
    WHERE scraped_at < NOW() - INTERVAL '90 days';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get mountain status history
CREATE OR REPLACE FUNCTION get_mountain_history(
    p_mountain_id VARCHAR(50),
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    date DATE,
    avg_percent_open NUMERIC,
    avg_lifts_open NUMERIC,
    was_open BOOLEAN,
    sample_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(scraped_at) as date,
        ROUND(AVG(percent_open), 1) as avg_percent_open,
        ROUND(AVG(lifts_open), 1) as avg_lifts_open,
        BOOL_OR(is_open) as was_open,
        COUNT(*)::INTEGER as sample_count
    FROM mountain_status
    WHERE mountain_id = p_mountain_id
        AND scraped_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY DATE(scraped_at)
    ORDER BY date DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions (adjust for your needs)
-- GRANT SELECT, INSERT, UPDATE ON mountain_status TO shredders_app;
-- GRANT SELECT, INSERT, UPDATE ON scraper_runs TO shredders_app;

-- Insert sample data for testing
INSERT INTO scraper_runs (run_id, total_mountains, successful_count, failed_count, duration_ms, status, triggered_by, completed_at)
VALUES ('test-' || uuid_generate_v4(), 15, 15, 0, 3245, 'completed', 'manual', NOW());

COMMENT ON TABLE mountain_status IS 'Stores scraped mountain status data from resort websites';
COMMENT ON TABLE scraper_runs IS 'Tracks scraper execution metadata and statistics';
COMMENT ON VIEW latest_mountain_status IS 'Shows the most recent status for each mountain';
COMMENT ON VIEW scraper_stats IS 'Daily aggregated statistics for scraper runs';

-- Success message
SELECT 'Database schema created successfully!' as status;
