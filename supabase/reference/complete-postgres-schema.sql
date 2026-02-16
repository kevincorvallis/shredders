-- Shredders PostgreSQL Schema Completion
-- Run this in Supabase SQL Editor to complete the schema setup

-- 1. Add unique constraint for ON CONFLICT clause (upsert support)
ALTER TABLE mountain_status
ADD CONSTRAINT mountain_status_unique_scrape
UNIQUE (mountain_id, scraped_at);

-- 2. Create scraper_failures table to log individual scraper failures
CREATE TABLE IF NOT EXISTS scraper_failures (
  id BIGSERIAL PRIMARY KEY,
  run_id TEXT NOT NULL,
  mountain_id TEXT NOT NULL,
  error_message TEXT,
  source_url TEXT,
  failed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_scraper_failures_run_id ON scraper_failures(run_id);
CREATE INDEX IF NOT EXISTS idx_scraper_failures_mountain_id ON scraper_failures(mountain_id);

-- 4. Create view for latest status per mountain (used by getAll())
CREATE OR REPLACE VIEW latest_mountain_status AS
SELECT DISTINCT ON (mountain_id)
  id,
  mountain_id,
  is_open,
  percent_open,
  lifts_open,
  lifts_total,
  runs_open,
  runs_total,
  message,
  conditions_message,
  source_url,
  scraped_at
FROM mountain_status
ORDER BY mountain_id, scraped_at DESC;

-- 5. Create cleanup function to remove old records (keep 90 days)
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

-- 6. Enable RLS on scraper_failures
ALTER TABLE scraper_failures ENABLE ROW LEVEL SECURITY;

-- 7. Allow public read access to scraper_failures (for monitoring dashboard)
CREATE POLICY "Allow public read access to scraper_failures"
ON scraper_failures FOR SELECT
TO public
USING (true);

-- 8. Grant insert permission for the scraper service
CREATE POLICY "Allow insert for scraper service"
ON scraper_failures FOR INSERT
TO public
WITH CHECK (true);
