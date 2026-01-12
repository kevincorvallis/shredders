import { NextResponse } from 'next/server';

/**
 * Simple ping endpoint to verify API is working
 * Does not query database - instant response
 * GET /api/scraper/ping
 */
export async function GET() {
  return NextResponse.json({
    status: 'ok',
    message: 'Scraper API is operational',
    timestamp: new Date().toISOString(),
    environment: {
      hasDatabase: !!(process.env.POSTGRES_URL || process.env.DATABASE_URL),
      hasSlackWebhook: !!process.env.SLACK_WEBHOOK_URL,
    },
  });
}
