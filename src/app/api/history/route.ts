import { NextRequest, NextResponse } from 'next/server';
import { getHistoricalData } from '@/lib/apis/snotel';

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const days = Math.min(90, Math.max(7, parseInt(searchParams.get('days') || '30', 10)));

  try {
    const history = await getHistoricalData(days);

    if (history.length === 0) {
      throw new Error('No historical data available');
    }

    // Calculate summary stats
    const depths = history.map(h => h.snowDepth).filter(d => d > 0);
    const snowfalls = history.map(h => h.snowfall);

    return NextResponse.json({
      location: {
        name: 'Mt. Baker',
        snotelStation: 'Wells Creek (910:WA:SNTL)',
      },
      period: {
        days,
        start: history[0]?.date,
        end: history[history.length - 1]?.date,
      },
      summary: {
        currentDepth: history[history.length - 1]?.snowDepth || 0,
        maxDepth: depths.length > 0 ? Math.max(...depths) : 0,
        minDepth: depths.length > 0 ? Math.min(...depths) : 0,
        totalSnowfall: snowfalls.reduce((a, b) => a + b, 0),
        avgDailySnowfall: (snowfalls.reduce((a, b) => a + b, 0) / days).toFixed(1),
      },
      history,
      source: 'SNOTEL NRCS',
    }, {
      headers: {
        'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=7200',
      },
    });
  } catch (error) {
    console.error('Error fetching history:', error);

    return NextResponse.json({
      location: {
        name: 'Mt. Baker',
        snotelStation: 'Wells Creek (910:WA:SNTL)',
      },
      period: { days, start: null, end: null },
      summary: {
        currentDepth: 0,
        maxDepth: 0,
        minDepth: 0,
        totalSnowfall: 0,
        avgDailySnowfall: '0',
      },
      history: [],
      error: 'Historical data temporarily unavailable',
    }, {
      status: 200,
      headers: {
        'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
      },
    });
  }
}
