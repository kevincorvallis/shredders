import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

/**
 * Test endpoint to verify database connection using Supabase
 */
export async function GET() {
  const start = Date.now();

  try {
    // Use Supabase client instead of @vercel/postgres
    const supabase = createAdminClient();

    // Simple query to test connection
    const { data, error } = await supabase
      .from('scraper_runs')
      .select('count')
      .limit(1);

    if (error) {
      return NextResponse.json({
        success: false,
        duration: Date.now() - start,
        error: error.message,
        code: error.code,
      }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      duration: Date.now() - start,
      message: 'Supabase connection successful',
      tableExists: true,
    });
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start,
    }, { status: 500 });
  }
}
