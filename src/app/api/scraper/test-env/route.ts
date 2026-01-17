import { NextResponse } from 'next/server';

/**
 * Test endpoint to check environment variables
 */
export async function GET() {
  const envKeys = Object.keys(process.env).filter(
    k => k.includes('POSTGRES') || k.includes('DATABASE') || k.includes('SUPABASE')
  );

  return NextResponse.json({
    success: true,
    timestamp: new Date().toISOString(),
    envKeys,
    hasPostgresUrl: !!process.env.POSTGRES_URL,
    hasDatabaseUrl: !!process.env.DATABASE_URL,
    hasSupabaseServiceKey: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
    hasSupabaseUrl: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
    hasSupabaseAnonKey: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    postgresUrlPrefix: process.env.POSTGRES_URL?.substring(0, 40) || null,
    supabaseUrlPrefix: process.env.NEXT_PUBLIC_SUPABASE_URL?.substring(0, 40) || null,
  });
}
