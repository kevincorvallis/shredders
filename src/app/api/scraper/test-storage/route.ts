import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

/**
 * Test endpoint to diagnose storage issues
 */
export async function GET() {
  const results: Record<string, any> = {};
  const start = Date.now();

  try {
    const supabase = createAdminClient();

    // Test 1: Check scraper_runs table
    try {
      const { error: runsError } = await supabase
        .from('scraper_runs')
        .select('count')
        .limit(1);
      results.scraper_runs = runsError ? { error: runsError.message } : { ok: true };
    } catch (e) {
      results.scraper_runs = { error: e instanceof Error ? e.message : 'Unknown' };
    }

    // Test 2: Check mountain_status table
    try {
      const { error: statusError } = await supabase
        .from('mountain_status')
        .select('count')
        .limit(1);
      results.mountain_status = statusError ? { error: statusError.message } : { ok: true };
    } catch (e) {
      results.mountain_status = { error: e instanceof Error ? e.message : 'Unknown' };
    }

    // Test 3: Check scraper_failures table
    try {
      const { error: failuresError } = await supabase
        .from('scraper_failures')
        .select('count')
        .limit(1);
      results.scraper_failures = failuresError ? { error: failuresError.message } : { ok: true };
    } catch (e) {
      results.scraper_failures = { error: e instanceof Error ? e.message : 'Unknown' };
    }

    // Test 4: Check latest_mountain_status view
    try {
      const { error: viewError } = await supabase
        .from('latest_mountain_status')
        .select('count')
        .limit(1);
      results.latest_mountain_status = viewError ? { error: viewError.message } : { ok: true };
    } catch (e) {
      results.latest_mountain_status = { error: e instanceof Error ? e.message : 'Unknown' };
    }

    // Test 5: Try inserting a test run
    try {
      const testRunId = `test-${Date.now()}`;
      const { error: insertError } = await supabase.from('scraper_runs').insert({
        run_id: testRunId,
        total_mountains: 0,
        triggered_by: 'diagnostic',
        status: 'test',
      });

      if (insertError) {
        results.insert_run = { error: insertError.message };
      } else {
        // Clean up test row
        await supabase.from('scraper_runs').delete().eq('run_id', testRunId);
        results.insert_run = { ok: true };
      }
    } catch (e) {
      results.insert_run = { error: e instanceof Error ? e.message : 'Unknown' };
    }

    // Test 6: Check unique constraint on mountain_status
    try {
      const testData = {
        mountain_id: 'test-diagnostic',
        is_open: false,
        percent_open: 0,
        lifts_open: 0,
        lifts_total: 0,
        runs_open: 0,
        runs_total: 0,
        message: 'Diagnostic test',
        conditions_message: 'Diagnostic test',
        source_url: 'https://test.com',
        scraped_at: new Date().toISOString(),
      };

      const { error: upsertError } = await supabase
        .from('mountain_status')
        .upsert(testData, { onConflict: 'mountain_id,scraped_at' });

      if (upsertError) {
        results.upsert_status = { error: upsertError.message };
      } else {
        // Clean up
        await supabase
          .from('mountain_status')
          .delete()
          .eq('mountain_id', 'test-diagnostic');
        results.upsert_status = { ok: true };
      }
    } catch (e) {
      results.upsert_status = { error: e instanceof Error ? e.message : 'Unknown' };
    }

    return NextResponse.json({
      success: true,
      duration: Date.now() - start,
      results,
    });
  } catch (error) {
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration: Date.now() - start,
        results,
      },
      { status: 500 }
    );
  }
}
