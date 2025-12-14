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
  }>;
}

export interface AISummary {
  generated: string;
  headline: string;
  conditions: string;
  recommendation: string;
  bestTimeToGo: string;
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
