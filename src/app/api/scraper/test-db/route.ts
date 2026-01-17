import { NextResponse } from 'next/server';
import { createClient } from '@vercel/postgres';

/**
 * Test endpoint to verify database connection
 */
export async function GET() {
  const start = Date.now();

  try {
    const connectionString = process.env.POSTGRES_URL || process.env.DATABASE_URL;

    // Check if connection string exists
    if (!connectionString) {
      return NextResponse.json({
        success: false,
        duration: Date.now() - start,
        error: 'No POSTGRES_URL or DATABASE_URL environment variable set',
        envKeys: Object.keys(process.env).filter(k => k.includes('POSTGRES') || k.includes('DATABASE')),
      }, { status: 500 });
    }

    // Try to create client and run simple query
    const db = createClient({ connectionString });
    const result = await db.sql`SELECT 1 as test`;

    return NextResponse.json({
      success: true,
      duration: Date.now() - start,
      result: result.rows[0],
      message: 'Database connection successful',
      connectionStringPrefix: connectionString.substring(0, 30) + '...',
    });
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack?.split('\n').slice(0, 3) : undefined,
      duration: Date.now() - start,
    }, { status: 500 });
  }
}
