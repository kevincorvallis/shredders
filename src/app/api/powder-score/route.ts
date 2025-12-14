import { NextResponse } from 'next/server';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getForecast } from '@/lib/apis/noaa';

interface PowderFactor {
  name: string;
  value: string;
  points: number;
  description: string;
}

function calculatePowderScore(
  snowfall24h: number,
  snowfall48h: number,
  temperature: number,
  windSpeed: number,
  baseDepth: number,
  upcomingSnow: number
) {
  let score = 5; // Base score
  const factors: PowderFactor[] = [];

  // Fresh snow bonus (0-3 points) - most important factor
  if (snowfall24h >= 12) {
    score += 3;
    factors.push({ name: 'Fresh Snow', value: '+3', points: 3, description: `${snowfall24h}" in 24hrs - Epic powder day!` });
  } else if (snowfall24h >= 6) {
    score += 2;
    factors.push({ name: 'Fresh Snow', value: '+2', points: 2, description: `${snowfall24h}" in 24hrs - Great conditions` });
  } else if (snowfall24h >= 2) {
    score += 1;
    factors.push({ name: 'Fresh Snow', value: '+1', points: 1, description: `${snowfall24h}" in 24hrs - Fresh snow` });
  } else if (snowfall48h >= 6) {
    score += 1;
    factors.push({ name: 'Recent Snow', value: '+1', points: 1, description: `${snowfall48h}" in 48hrs - Recent snow` });
  } else {
    factors.push({ name: 'Fresh Snow', value: '0', points: 0, description: 'No significant new snow' });
  }

  // Upcoming snow bonus (0-1 point)
  if (upcomingSnow >= 6) {
    score += 1;
    factors.push({ name: 'Incoming Storm', value: '+1', points: 1, description: `${upcomingSnow}"+ expected in next 48hrs` });
  }

  // Temperature bonus (0-2 points) - cold = light powder
  if (temperature < 20) {
    score += 2;
    factors.push({ name: 'Temperature', value: '+2', points: 2, description: `${temperature}°F - Cold & dry powder` });
  } else if (temperature < 28) {
    score += 1;
    factors.push({ name: 'Temperature', value: '+1', points: 1, description: `${temperature}°F - Good powder temps` });
  } else if (temperature > 35) {
    score -= 1;
    factors.push({ name: 'Temperature', value: '-1', points: -1, description: `${temperature}°F - Warm, wet snow` });
  } else {
    factors.push({ name: 'Temperature', value: '0', points: 0, description: `${temperature}°F - Moderate temps` });
  }

  // Wind penalty (0 to -2 points)
  if (windSpeed > 35) {
    score -= 2;
    factors.push({ name: 'Wind', value: '-2', points: -2, description: `${windSpeed}mph - Strong wind, possible closures` });
  } else if (windSpeed > 25) {
    score -= 1;
    factors.push({ name: 'Wind', value: '-1', points: -1, description: `${windSpeed}mph - Wind-affected snow` });
  } else {
    factors.push({ name: 'Wind', value: '0', points: 0, description: `${windSpeed}mph - Manageable wind` });
  }

  // Base depth bonus (0-1 point)
  if (baseDepth >= 80) {
    score += 1;
    factors.push({ name: 'Base Depth', value: '+1', points: 1, description: `${baseDepth}" base - Full coverage` });
  } else if (baseDepth >= 40) {
    factors.push({ name: 'Base Depth', value: '0', points: 0, description: `${baseDepth}" base - Good coverage` });
  } else if (baseDepth < 20) {
    score -= 1;
    factors.push({ name: 'Base Depth', value: '-1', points: -1, description: `${baseDepth}" base - Limited terrain` });
  }

  // Clamp score between 1 and 10
  score = Math.max(1, Math.min(10, score));

  return { score, factors };
}

function getScoreLabel(score: number): string {
  if (score >= 9) return 'Epic';
  if (score >= 7) return 'Great';
  if (score >= 5) return 'Good';
  if (score >= 3) return 'Fair';
  return 'Poor';
}

function getRecommendation(score: number, snowfall24h: number, upcomingSnow: number): string {
  if (score >= 9) {
    return 'Drop everything - this is a powder day! Get there early for first tracks.';
  }
  if (score >= 7) {
    return 'Excellent conditions for skiing. Well worth the trip to Mt. Baker.';
  }
  if (score >= 5) {
    if (upcomingSnow >= 6) {
      return `Decent conditions now, but ${upcomingSnow}"+ coming soon. Consider waiting for the storm.`;
    }
    return 'Good conditions for a day on the mountain. Groomed runs will be in great shape.';
  }
  if (score >= 3) {
    if (upcomingSnow >= 6) {
      return `Conditions are below average, but a storm is coming with ${upcomingSnow}"+ expected.`;
    }
    return 'Conditions are below average. Check back for updates.';
  }
  return 'Not ideal conditions right now. Keep an eye on the forecast.';
}

export async function GET() {
  try {
    // Fetch real data
    const [snotelData, forecast] = await Promise.all([
      getCurrentConditions(),
      getForecast().catch(() => []),
    ]);

    // Calculate upcoming snow from forecast (next 48hrs)
    const upcomingSnow = forecast
      .slice(0, 2)
      .reduce((sum, day) => sum + (day.snowfall || 0), 0);

    // Estimate wind from forecast
    const todayForecast = forecast[0];
    const windSpeed = todayForecast?.wind?.speed || 10;

    const { score, factors } = calculatePowderScore(
      snotelData.snowfall24h,
      snotelData.snowfall48h,
      snotelData.temperature,
      windSpeed,
      snotelData.snowDepth,
      upcomingSnow
    );

    // Calculate confidence based on data freshness
    const lastUpdate = new Date(snotelData.lastUpdated);
    const hoursOld = (Date.now() - lastUpdate.getTime()) / (1000 * 60 * 60);
    const confidence = Math.max(50, Math.round(100 - hoursOld * 2));

    return NextResponse.json({
      score,
      maxScore: 10,
      confidence,
      factors,
      calculatedAt: new Date().toISOString(),
      label: getScoreLabel(score),
      recommendation: getRecommendation(score, snotelData.snowfall24h, upcomingSnow),
      dataSource: {
        snow: 'SNOTEL Wells Creek',
        weather: 'NOAA NWS',
      },
    }, {
      headers: {
        'Cache-Control': 'public, s-maxage=1800, stale-while-revalidate=3600',
      },
    });
  } catch (error) {
    console.error('Error calculating powder score:', error);

    // Return fallback score
    return NextResponse.json({
      score: 5,
      maxScore: 10,
      confidence: 30,
      factors: [
        { name: 'Data Status', value: '?', points: 0, description: 'Unable to fetch current data' },
      ],
      calculatedAt: new Date().toISOString(),
      label: 'Unknown',
      recommendation: 'Unable to calculate conditions. Check back soon.',
      error: 'Data temporarily unavailable',
    }, {
      status: 200,
      headers: {
        'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
      },
    });
  }
}
