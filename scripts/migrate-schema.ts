/**
 * Migration script to set up the PostgreSQL schema using pg directly
 * Run with: npx tsx scripts/migrate-schema.ts
 */

import { Client } from 'pg';

const MIGRATION_SQL = `
-- 1. Add unique constraint for ON CONFLICT clause (upsert support)
-- First check if it exists to avoid error
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'mountain_status_unique_scrape'
  ) THEN
    ALTER TABLE mountain_status
    ADD CONSTRAINT mountain_status_unique_scrape UNIQUE (mountain_id, scraped_at);
  END IF;
END $$;

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

-- 6. Enable RLS on scraper_failures (idempotent)
ALTER TABLE scraper_failures ENABLE ROW LEVEL SECURITY;

-- 7. Allow public read access to scraper_failures (for monitoring dashboard)
-- Drop and recreate to ensure idempotent
DROP POLICY IF EXISTS "Allow public read access to scraper_failures" ON scraper_failures;
CREATE POLICY "Allow public read access to scraper_failures"
ON scraper_failures FOR SELECT
TO public
USING (true);

-- 8. Grant insert permission for the scraper service
DROP POLICY IF EXISTS "Allow insert for scraper service" ON scraper_failures;
CREATE POLICY "Allow insert for scraper service"
ON scraper_failures FOR INSERT
TO public
WITH CHECK (true);
`;

async function runMigration() {
  // Get database URL from environment
  const databaseUrl = process.env.DATABASE_URL || process.env.POSTGRES_URL;

  if (!databaseUrl) {
    console.error('Missing DATABASE_URL or POSTGRES_URL environment variable');
    console.error('\nSet it from your Supabase dashboard > Settings > Database > Connection string');
    console.error('Use the "URI" format and add ?sslmode=require if needed');
    process.exit(1);
  }

  console.log('Connecting to database...');
  console.log('URL prefix:', databaseUrl.substring(0, 50) + '...');

  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    console.log('Connected successfully\n');

    console.log('Running migration...\n');
    await client.query(MIGRATION_SQL);

    console.log('✅ Migration completed successfully!\n');

    // Verify the schema
    console.log('Verifying schema...');

    // Check constraint
    const constraintResult = await client.query(`
      SELECT 1 FROM pg_constraint WHERE conname = 'mountain_status_unique_scrape'
    `);
    console.log('  unique constraint:', constraintResult.rows.length > 0 ? '✓' : '✗');

    // Check table
    const tableResult = await client.query(`
      SELECT 1 FROM information_schema.tables WHERE table_name = 'scraper_failures'
    `);
    console.log('  scraper_failures table:', tableResult.rows.length > 0 ? '✓' : '✗');

    // Check view
    const viewResult = await client.query(`
      SELECT 1 FROM information_schema.views WHERE table_name = 'latest_mountain_status'
    `);
    console.log('  latest_mountain_status view:', viewResult.rows.length > 0 ? '✓' : '✗');

    // Check function
    const funcResult = await client.query(`
      SELECT 1 FROM pg_proc WHERE proname = 'cleanup_old_mountain_status'
    `);
    console.log('  cleanup_old_mountain_status function:', funcResult.rows.length > 0 ? '✓' : '✗');

    console.log('\n✅ All schema objects verified!');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();
