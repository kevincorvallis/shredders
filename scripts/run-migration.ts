/**
 * Migration script to set up the PostgreSQL schema
 * Run with: npx tsx scripts/run-migration.ts
 */

import { createClient } from '@supabase/supabase-js';

async function runMigration() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceRoleKey) {
    console.error('Missing environment variables:');
    console.error('  NEXT_PUBLIC_SUPABASE_URL:', supabaseUrl ? '✓' : '✗');
    console.error('  SUPABASE_SERVICE_ROLE_KEY:', serviceRoleKey ? '✓' : '✗');
    console.error('\nLoad from .env.local: source <(grep -v "^#" .env.local | xargs -I {} echo "export {}")');
    process.exit(1);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  console.log('Connected to Supabase:', supabaseUrl);

  // Test connection
  const { data: testData, error: testError } = await supabase
    .from('mountain_status')
    .select('count')
    .limit(1);

  if (testError) {
    console.error('Connection test failed:', testError.message);
    process.exit(1);
  }

  console.log('Connection test passed');

  // Check what's missing
  console.log('\n--- Checking schema status ---');

  // Check scraper_failures table
  const { error: failuresError } = await supabase
    .from('scraper_failures')
    .select('count')
    .limit(1);

  console.log('scraper_failures table:', failuresError ? '✗ Missing' : '✓ Exists');

  // Check latest_mountain_status view
  const { error: viewError } = await supabase
    .from('latest_mountain_status')
    .select('count')
    .limit(1);

  console.log('latest_mountain_status view:', viewError ? '✗ Missing' : '✓ Exists');

  // Check unique constraint by attempting an upsert
  const testRecord = {
    mountain_id: 'test-migration-check',
    is_open: false,
    percent_open: 0,
    lifts_open: 0,
    lifts_total: 0,
    runs_open: 0,
    runs_total: 0,
    message: 'Migration check',
    conditions_message: 'Migration check',
    source_url: 'https://test.com',
    scraped_at: new Date().toISOString(),
  };

  const { error: upsertError } = await supabase
    .from('mountain_status')
    .upsert(testRecord, { onConflict: 'mountain_id,scraped_at' });

  if (upsertError?.message?.includes('no unique or exclusion constraint')) {
    console.log('unique constraint:', '✗ Missing');
  } else {
    console.log('unique constraint:', '✓ Exists');
    // Clean up test record
    await supabase
      .from('mountain_status')
      .delete()
      .eq('mountain_id', 'test-migration-check');
  }

  console.log('\n--- Migration SQL ---');
  console.log('Run the following SQL in Supabase SQL Editor:');
  console.log('https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/sql/new\n');

  const sql = `-- 1. Add unique constraint for ON CONFLICT clause (upsert support)
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
WITH CHECK (true);`;

  console.log(sql);
}

runMigration().catch(console.error);
