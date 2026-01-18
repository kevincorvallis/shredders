// Claude API Client for AI-generated summaries
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic();

interface ConditionsData {
  snowDepth: number;
  snowfall24h: number;
  snowfall48h: number;
  temperature: number;
  windSpeed: number;
  powderScore: number;
}

interface ForecastData {
  days: Array<{
    dayOfWeek: string;
    snowfall: number;
    high: number;
    low: number;
    conditions: string;
    precipProbability?: number;
    windDirection?: string;
  }>;
}

export interface AISummary {
  generated: string;
  headline: string;
  conditions: string;
  recommendation: string;
  bestTimeToGo: string;
}

// Enhanced summary with more detail
export interface EnhancedAISummary extends AISummary {
  uncertainty: string;
  comparison: string;
  conditionalOutlook: string;
}

export async function generateConditionsSummary(
  conditions: ConditionsData,
  forecast: ForecastData
): Promise<AISummary> {
  const forecastSummary = forecast.days
    .slice(0, 3)
    .map(d => `${d.dayOfWeek}: ${d.snowfall}" snow, ${d.high}°/${d.low}°, ${d.conditions}`)
    .join('\n');

  const prompt = `You are a ski conditions reporter for Mt. Baker ski area in Washington. Generate a brief, enthusiastic conditions report based on this data:

CURRENT CONDITIONS:
- Snow Depth: ${conditions.snowDepth} inches
- 24hr Snowfall: ${conditions.snowfall24h} inches
- 48hr Snowfall: ${conditions.snowfall48h} inches
- Temperature: ${conditions.temperature}°F
- Wind: ${conditions.windSpeed} mph
- Powder Score: ${conditions.powderScore}/10

3-DAY FORECAST:
${forecastSummary}

Respond with JSON in this exact format (no markdown, just JSON):
{
  "headline": "Short catchy headline (max 50 chars)",
  "conditions": "2-3 sentences describing current conditions and what to expect",
  "recommendation": "1-2 sentences with actionable advice for skiers",
  "bestTimeToGo": "Brief suggestion like 'First chair tomorrow' or 'Wait for the storm to clear'"
}`;

  try {
    const message = await client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 500,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    });

    // Extract the text content
    const textContent = message.content.find(block => block.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      throw new Error('No text response from Claude');
    }

    // Parse the JSON response
    const parsed = JSON.parse(textContent.text);

    return {
      generated: new Date().toISOString(),
      headline: parsed.headline,
      conditions: parsed.conditions,
      recommendation: parsed.recommendation,
      bestTimeToGo: parsed.bestTimeToGo,
    };
  } catch (error) {
    console.error('Claude API error:', error);

    // Fallback response
    return {
      generated: new Date().toISOString(),
      headline: conditions.snowfall24h > 6 ? 'Fresh Powder Alert!' : 'Current Conditions Update',
      conditions: `Mt. Baker currently has ${conditions.snowDepth}" base depth with ${conditions.snowfall24h}" of new snow in the last 24 hours. Temperature is ${conditions.temperature}°F.`,
      recommendation: conditions.powderScore >= 7
        ? 'Conditions look great - consider making the trip!'
        : 'Check back for updates on improving conditions.',
      bestTimeToGo: 'Check the forecast for the best window.',
    };
  }
}

// ============================================================
// Enhanced Regional Narrative Generation
// ============================================================

export interface RegionalNarrativeInput {
  region: string;
  regionName: string;
  mountains: Array<{
    id: string;
    name: string;
    forecast: Array<{
      date: string;
      dayOfWeek: string;
      snowfall: number;
      high: number;
      low: number;
      precipProbability: number;
      windDirection: number;
    }>;
    currentConditions?: {
      snowDepth: number;
      temperature: number;
    };
  }>;
  stormData?: {
    activeStorms: number;
    primaryWindDirection: string;
    favoredMountains: string[];
  };
  modelAgreement?: {
    confidence: 'high' | 'medium' | 'low';
    snowSpread: number;
  };
}

export interface RegionalNarrative {
  generated: string;
  headline: string;
  overview: string;
  mountainRankings: string;
  uncertainty: string;
  conditionalOutlook: string;
  recommendation: string;
}

/**
 * Generate an OpenSnow-style regional forecast narrative
 */
export async function generateRegionalNarrative(
  input: RegionalNarrativeInput
): Promise<RegionalNarrative> {
  // Build mountain summaries
  const mountainSummaries = input.mountains.map(m => {
    const next3Days = m.forecast.slice(0, 3);
    const totalSnow = next3Days.reduce((sum, d) => sum + d.snowfall, 0);
    const avgHigh = Math.round(next3Days.reduce((sum, d) => sum + d.high, 0) / next3Days.length);
    return `${m.name}: ${totalSnow}" over 3 days, highs ~${avgHigh}°F`;
  }).join('\n');

  // Build storm context
  let stormContext = '';
  if (input.stormData) {
    const { activeStorms, primaryWindDirection, favoredMountains } = input.stormData;
    if (activeStorms > 0) {
      stormContext = `\nSTORM CONTEXT:
- ${activeStorms} active/incoming storm(s)
- Primary wind direction: ${primaryWindDirection}
- Favored mountains: ${favoredMountains.join(', ')}`;
    }
  }

  // Build confidence context
  let confidenceContext = '';
  if (input.modelAgreement) {
    const { confidence, snowSpread } = input.modelAgreement;
    confidenceContext = `\nMODEL CONFIDENCE:
- Confidence level: ${confidence}
- Snow prediction spread: ${snowSpread}" between models`;
  }

  const prompt = `You are an expert ski forecaster writing a daily regional forecast for ${input.regionName}. Write in an opinionated, editorial style like OpenSnow - be direct about which mountains are favored and why.

MOUNTAIN FORECASTS:
${mountainSummaries}
${stormContext}
${confidenceContext}

Generate a forecast with these key elements:
1. Be opinionated - say which mountains you'd target and why
2. Include uncertainty language when confidence is medium/low (e.g., "if the storm trends north...")
3. Compare mountains directly (e.g., "better than yesterday", "Crystal over Stevens today")
4. Explain WHY snow totals differ (wind direction, elevation, geography)

Respond with JSON in this exact format (no markdown, just JSON):
{
  "headline": "Catchy 5-8 word headline",
  "overview": "2-3 sentences on the overall pattern and what's happening",
  "mountainRankings": "Direct comparison of mountains for powder potential (e.g., 'Baker leads the pack today, Stevens a close second, Crystal gets less with SW flow')",
  "uncertainty": "What could change and how it would affect the forecast (e.g., 'If the storm tracks north, add 2-4 inches to Baker's totals')",
  "conditionalOutlook": "What to watch for and how conditions might evolve",
  "recommendation": "Clear, actionable advice on where and when to ski"
}`;

  try {
    const message = await client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 800,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    });

    const textContent = message.content.find(block => block.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      throw new Error('No text response from Claude');
    }

    const parsed = JSON.parse(textContent.text);

    return {
      generated: new Date().toISOString(),
      headline: parsed.headline,
      overview: parsed.overview,
      mountainRankings: parsed.mountainRankings,
      uncertainty: parsed.uncertainty,
      conditionalOutlook: parsed.conditionalOutlook,
      recommendation: parsed.recommendation,
    };
  } catch (error) {
    console.error('Claude regional narrative error:', error);

    // Fallback response
    const topMountain = input.mountains.reduce((top, m) => {
      const totalSnow = m.forecast.slice(0, 3).reduce((sum, d) => sum + d.snowfall, 0);
      const topSnow = top.forecast.slice(0, 3).reduce((sum, d) => sum + d.snowfall, 0);
      return totalSnow > topSnow ? m : top;
    }, input.mountains[0]);

    return {
      generated: new Date().toISOString(),
      headline: `${input.regionName} Snow Update`,
      overview: `Active weather pattern continues across ${input.regionName}.`,
      mountainRankings: `${topMountain?.name || 'Mountains'} showing the most snow potential.`,
      uncertainty: 'Monitor forecasts for updates as storm details become clearer.',
      conditionalOutlook: 'Conditions could improve or shift - check back for updates.',
      recommendation: 'Flexible plans recommended given forecast uncertainty.',
    };
  }
}

// ============================================================
// Mountain-Specific Narrative
// ============================================================

export interface MountainNarrativeInput {
  mountainId: string;
  mountainName: string;
  conditions: {
    snowDepth: number;
    snowfall24h: number;
    snowfall48h: number;
    temperature: number;
    windSpeed: number;
    powderScore: number;
  };
  forecast: Array<{
    date: string;
    dayOfWeek: string;
    snowfall: number;
    high: number;
    low: number;
    precipProbability: number;
    conditions: string;
  }>;
  modelConfidence?: 'high' | 'medium' | 'low';
  modelSpread?: number;
  comparisonData?: {
    betterThanYesterday: boolean;
    regionRank: number;
    totalMountainsInRegion: number;
  };
}

export interface MountainNarrative {
  generated: string;
  headline: string;
  todayOutlook: string;
  weekAhead: string;
  uncertainty: string;
  bestDay: string;
  recommendation: string;
}

/**
 * Generate an opinionated mountain-specific forecast narrative
 */
export async function generateMountainNarrative(
  input: MountainNarrativeInput
): Promise<MountainNarrative> {
  const forecastSummary = input.forecast
    .slice(0, 7)
    .map(d => `${d.dayOfWeek}: ${d.snowfall}" (${d.precipProbability}% chance), ${d.high}°/${d.low}°`)
    .join('\n');

  // Build comparison context
  let comparisonContext = '';
  if (input.comparisonData) {
    const { betterThanYesterday, regionRank, totalMountainsInRegion } = input.comparisonData;
    comparisonContext = `\nCOMPARISON:
- vs Yesterday: ${betterThanYesterday ? 'Better conditions today' : 'Conditions unchanged or declining'}
- Regional rank: #${regionRank} of ${totalMountainsInRegion} mountains for powder potential`;
  }

  // Build confidence context
  let confidenceContext = '';
  if (input.modelConfidence) {
    confidenceContext = `\nFORECAST CONFIDENCE:
- Model agreement: ${input.modelConfidence}
${input.modelSpread ? `- Snow prediction spread: ±${input.modelSpread}"` : ''}`;
  }

  const prompt = `You are an expert ski forecaster writing the daily forecast for ${input.mountainName}. Be direct, opinionated, and helpful.

CURRENT CONDITIONS:
- Snow Depth: ${input.conditions.snowDepth}"
- Last 24h: ${input.conditions.snowfall24h}"
- Last 48h: ${input.conditions.snowfall48h}"
- Temperature: ${input.conditions.temperature}°F
- Wind: ${input.conditions.windSpeed} mph
- Powder Score: ${input.conditions.powderScore}/10

7-DAY FORECAST:
${forecastSummary}
${comparisonContext}
${confidenceContext}

Write an opinionated forecast that:
1. Tells skiers exactly when to go and when to skip
2. Includes uncertainty when confidence is not high (e.g., "could see 2-4" more if storm intensifies")
3. References yesterday if conditions changed significantly
4. Identifies the best powder day clearly

Respond with JSON (no markdown):
{
  "headline": "Catchy headline (5-8 words)",
  "todayOutlook": "What to expect if you go today (1-2 sentences)",
  "weekAhead": "Week overview - pattern, totals, trend (2-3 sentences)",
  "uncertainty": "What could change the forecast (1-2 sentences, include conditions like 'if storm tracks north...')",
  "bestDay": "The best day to ski this week and why",
  "recommendation": "Clear go/wait/watch advice"
}`;

  try {
    const message = await client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 700,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    });

    const textContent = message.content.find(block => block.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      throw new Error('No text response from Claude');
    }

    const parsed = JSON.parse(textContent.text);

    return {
      generated: new Date().toISOString(),
      headline: parsed.headline,
      todayOutlook: parsed.todayOutlook,
      weekAhead: parsed.weekAhead,
      uncertainty: parsed.uncertainty,
      bestDay: parsed.bestDay,
      recommendation: parsed.recommendation,
    };
  } catch (error) {
    console.error('Claude mountain narrative error:', error);

    // Find best day
    const bestForecastDay = input.forecast.reduce((best, day) =>
      day.snowfall > best.snowfall ? day : best
    , input.forecast[0]);

    return {
      generated: new Date().toISOString(),
      headline: input.conditions.powderScore >= 7 ? 'Powder Day Potential!' : `${input.mountainName} Update`,
      todayOutlook: `Current powder score: ${input.conditions.powderScore}/10 with ${input.conditions.snowDepth}" base.`,
      weekAhead: `${input.forecast.slice(0, 7).reduce((sum, d) => sum + d.snowfall, 0)}" expected over the next 7 days.`,
      uncertainty: 'Monitor updates as storm details become clearer.',
      bestDay: bestForecastDay ? `${bestForecastDay.dayOfWeek} looks best with ${bestForecastDay.snowfall}" expected.` : 'Check daily updates.',
      recommendation: input.conditions.powderScore >= 7 ? 'Conditions looking good!' : 'Monitor for improvements.',
    };
  }
}
