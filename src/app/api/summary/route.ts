import { NextResponse } from 'next/server';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getForecast } from '@/lib/apis/noaa';
import { generateConditionsSummary } from '@/lib/apis/claude';

export async function GET() {
  try {
    // Fetch current data
    const [snotelData, forecast] = await Promise.all([
      getCurrentConditions(),
      getForecast(),
    ]);

    // Calculate powder score for context
    const upcomingSnow = forecast.slice(0, 2).reduce((sum, d) => sum + d.snowfall, 0);
    let powderScore = 5;
    if (snotelData.snowfall24h >= 12) powderScore += 3;
    else if (snotelData.snowfall24h >= 6) powderScore += 2;
    else if (snotelData.snowfall24h >= 2) powderScore += 1;
    if (snotelData.temperature < 28) powderScore += 1;
    if (snotelData.snowDepth >= 80) powderScore += 1;
    powderScore = Math.min(10, Math.max(1, powderScore));

    // Generate AI summary
    const summary = await generateConditionsSummary(
      {
        snowDepth: snotelData.snowDepth,
        snowfall24h: snotelData.snowfall24h,
        snowfall48h: snotelData.snowfall48h,
        temperature: snotelData.temperature,
        windSpeed: forecast[0]?.wind?.speed || 10,
        powderScore,
      },
      {
        days: forecast.slice(0, 3).map(d => ({
          dayOfWeek: d.dayOfWeek,
          snowfall: d.snowfall,
          high: d.high,
          low: d.low,
          conditions: d.conditions,
        })),
      }
    );

    return NextResponse.json(summary, {
      headers: {
        'Cache-Control': 'public, s-maxage=1800, stale-while-revalidate=3600',
      },
    });
  } catch (error) {
    console.error('Error generating summary:', error);

    // Return fallback summary
    return NextResponse.json({
      generated: new Date().toISOString(),
      headline: 'Conditions Update',
      conditions: 'Unable to generate AI summary at this time. Check the conditions and forecast tabs for current data.',
      recommendation: 'Check the detailed conditions for the latest information.',
      bestTimeToGo: 'Review the forecast to plan your visit.',
      error: 'AI summary temporarily unavailable',
    }, {
      status: 200,
      headers: {
        'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
      },
    });
  }
}
