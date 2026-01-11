import { NextRequest, NextResponse } from 'next/server';
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

interface ArrivalTimeRecommendation {
  mountainId: string;
  mountainName: string;
  generated: string;
  recommendedArrivalTime: string; // "7:30 AM"
  arrivalWindow: {
    earliest: string;
    optimal: string;
    latest: string;
  };
  confidence: 'high' | 'medium' | 'low';
  reasoning: string[];
  factors: {
    liftOpeningTime?: string;
    expectedCrowdLevel: 'low' | 'medium' | 'high' | 'extreme';
    roadConditions: 'clear' | 'snow' | 'ice' | 'chains-required';
    weatherQuality: 'excellent' | 'good' | 'fair' | 'poor';
    powderFreshness: 'fresh' | 'tracked-out' | 'packed';
    parkingDifficulty: 'easy' | 'moderate' | 'challenging' | 'very-difficult';
  };
  alternatives: Array<{
    time: string;
    description: string;
    tradeoff: string;
  }>;
  tips: string[];
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  try {
    const resolvedParams = await params;
    const { mountainId } = resolvedParams;
    const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

    // Fetch all relevant data in parallel
    const [
      mountainDetail,
      conditions,
      forecast,
      powderScore,
      roads,
      tripAdvice,
      powderDay,
      lifts,
    ] = await Promise.allSettled([
      fetch(`${baseUrl}/api/mountains/${mountainId}`).then(r => r.ok ? r.json() : null),
      fetch(`${baseUrl}/api/mountains/${mountainId}/conditions`).then(r => r.ok ? r.json() : null),
      fetch(`${baseUrl}/api/mountains/${mountainId}/forecast`).then(r => r.ok ? r.json() : null),
      fetch(`${baseUrl}/api/mountains/${mountainId}/powder-score`).then(r => r.ok ? r.json() : null),
      fetch(`${baseUrl}/api/mountains/${mountainId}/roads`).then(r => r.ok ? r.json() : null),
      fetch(`${baseUrl}/api/mountains/${mountainId}/trip-advice`).then(r => r.ok ? r.json() : null),
      fetch(`${baseUrl}/api/mountains/${mountainId}/powder-day`).then(r => r.ok ? r.json() : null),
      fetch(`${baseUrl}/api/mountains/${mountainId}/lifts`).then(r => r.ok ? r.json() : null),
    ]);

    const mountain = mountainDetail.status === 'fulfilled' ? mountainDetail.value : null;
    const currentConditions = conditions.status === 'fulfilled' ? conditions.value : null;
    const forecastData = forecast.status === 'fulfilled' ? forecast.value : null;
    const powder = powderScore.status === 'fulfilled' ? powderScore.value : null;
    const roadData = roads.status === 'fulfilled' ? roads.value : null;
    const tripData = tripAdvice.status === 'fulfilled' ? tripAdvice.value : null;
    const powderPlan = powderDay.status === 'fulfilled' ? powderDay.value : null;
    const liftData = lifts.status === 'fulfilled' ? lifts.value : null;

    if (!mountain) {
      return NextResponse.json(
        { error: 'Mountain not found' },
        { status: 404 }
      );
    }

    // Get current date/time info
    const now = new Date();
    const dayOfWeek = now.toLocaleDateString('en-US', { weekday: 'long' });
    const isWeekend = dayOfWeek === 'Saturday' || dayOfWeek === 'Sunday';
    const currentHour = now.getHours();

    // Build context for AI
    const context = {
      mountain: {
        name: mountain.name,
        id: mountain.id,
        region: mountain.region,
      },
      timing: {
        dayOfWeek,
        isWeekend,
        currentTime: now.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }),
        date: now.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' }),
      },
      conditions: currentConditions ? {
        snowDepth: currentConditions.snowDepth,
        snowfall24h: currentConditions.snowfall24h,
        temperature: currentConditions.temperature,
        windSpeed: currentConditions.windSpeed,
        weatherDescription: currentConditions.weatherDescription,
      } : null,
      powder: powder ? {
        score: powder.score,
        rating: powder.rating,
      } : null,
      forecast: forecastData?.forecast?.[0] ? {
        todayHigh: forecastData.forecast[0].high,
        todayLow: forecastData.forecast[0].low,
        todaySnowfall: forecastData.forecast[0].snowfall,
        todayConditions: forecastData.forecast[0].conditions,
        todayPrecipProbability: forecastData.forecast[0].precipProbability,
      } : null,
      roads: roadData ? {
        conditions: roadData.roads?.[0]?.conditions || 'unknown',
        restrictions: roadData.roads?.[0]?.restrictions || [],
        chainsRequired: roadData.roads?.[0]?.chainsRequired || false,
        roadStatus: roadData.roads?.[0]?.status || 'unknown',
      } : null,
      tripAdvice: tripData ? {
        departureTimeRecommendation: tripData.departureTimeRecommendation,
        driveTimeEstimate: tripData.driveTimeEstimate,
        trafficLevel: tripData.trafficLevel,
        parkingDifficulty: tripData.parkingDifficulty,
      } : null,
      powderDay: powderPlan?.days?.[0] ? {
        verdict: powderPlan.days[0].verdict,
        predictedPowderScore: powderPlan.days[0].predictedPowderScore,
        crowdRisk: powderPlan.days[0].crowdRisk,
        bestWindow: powderPlan.days[0].bestWindow,
      } : null,
      lifts: liftData ? {
        openingTime: liftData.openingTime || '9:00 AM',
        closingTime: liftData.closingTime || '4:00 PM',
        operatingLifts: liftData.lifts?.filter((l: any) => l.status === 'open').length || 0,
        totalLifts: liftData.lifts?.length || 0,
      } : null,
    };

    // Prepare AI prompt
    const prompt = `You are an expert ski resort arrival time advisor. Analyze the following data and recommend the optimal arrival time for today.

**Mountain**: ${context.mountain.name} (${context.mountain.region})
**Date**: ${context.timing.date} (${context.timing.dayOfWeek})
**Current Time**: ${context.timing.currentTime}

**Current Conditions**:
${context.conditions ? `
- Snow Depth: ${context.conditions.snowDepth}"
- 24h Snowfall: ${context.conditions.snowfall24h}"
- Temperature: ${context.conditions.temperature}°F
- Wind Speed: ${context.conditions.windSpeed} mph
- Weather: ${context.conditions.weatherDescription}
` : '- No current conditions available'}

**Powder Score**: ${context.powder ? `${context.powder.score}/10 (${context.powder.rating})` : 'Not available'}

**Today's Forecast**:
${context.forecast ? `
- High/Low: ${context.forecast.todayHigh}°F / ${context.forecast.todayLow}°F
- Expected Snowfall: ${context.forecast.todaySnowfall}"
- Conditions: ${context.forecast.todayConditions}
- Precipitation Probability: ${context.forecast.todayPrecipProbability}%
` : '- No forecast available'}

**Road Conditions**:
${context.roads ? `
- Conditions: ${context.roads.conditions}
- Chains Required: ${context.roads.chainsRequired ? 'YES' : 'NO'}
- Restrictions: ${context.roads.restrictions.join(', ') || 'None'}
- Status: ${context.roads.roadStatus}
` : '- No road data available'}

**Trip Advice**:
${context.tripAdvice ? `
- Recommended Departure: ${context.tripAdvice.departureTimeRecommendation}
- Drive Time Estimate: ${context.tripAdvice.driveTimeEstimate}
- Traffic Level: ${context.tripAdvice.trafficLevel}
- Parking Difficulty: ${context.tripAdvice.parkingDifficulty}
` : '- No trip advice available'}

**Powder Day Forecast**:
${context.powderDay ? `
- Verdict: ${context.powderDay.verdict}
- Predicted Score: ${context.powderDay.predictedPowderScore}/10
- Crowd Risk: ${context.powderDay.crowdRisk}
- Best Window: ${context.powderDay.bestWindow}
` : '- No powder day forecast available'}

**Lift Operations**:
${context.lifts ? `
- Opening Time: ${context.lifts.openingTime}
- Closing Time: ${context.lifts.closingTime}
- Operating Lifts: ${context.lifts.operatingLifts}/${context.lifts.totalLifts}
` : '- No lift data available'}

**Weekend/Holiday Factor**: ${isWeekend ? 'Weekend (expect higher crowds)' : 'Weekday (typically lower crowds)'}

---

Based on this data, provide a comprehensive arrival time recommendation in JSON format:

{
  "recommendedArrivalTime": "7:30 AM",
  "arrivalWindow": {
    "earliest": "6:30 AM",
    "optimal": "7:30 AM",
    "latest": "8:30 AM"
  },
  "confidence": "high|medium|low",
  "reasoning": [
    "Primary reason for this time",
    "Secondary factor",
    "Additional consideration"
  ],
  "factors": {
    "expectedCrowdLevel": "low|medium|high|extreme",
    "roadConditions": "clear|snow|ice|chains-required",
    "weatherQuality": "excellent|good|fair|poor",
    "powderFreshness": "fresh|tracked-out|packed",
    "parkingDifficulty": "easy|moderate|challenging|very-difficult"
  },
  "alternatives": [
    {
      "time": "9:00 AM",
      "description": "Sleep in option",
      "tradeoff": "Avoid early morning drive but miss first tracks"
    }
  ],
  "tips": [
    "Bring tire chains",
    "Arrive early for powder days",
    "Park in upper lot for quick exit"
  ]
}

Consider these factors in your recommendation:
1. **Fresh Powder**: If significant overnight snowfall, recommend arriving before lift opening to get first tracks
2. **Road Conditions**: If chains required or icy, add 30-60 min buffer to normal arrival time
3. **Crowd Management**: Weekends and powder days = arrive earlier for parking
4. **Lift Opening**: Recommend arriving 30-60 min before lift opening on powder days, 15-30 min otherwise
5. **Weather Windows**: If storm clearing or conditions improving, recommend optimal time window
6. **Temperature**: If very cold in morning, later arrival might be more comfortable but with tradeoff

Respond with ONLY the JSON object, no markdown formatting.`;

    // Call OpenAI
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: 'You are an expert ski resort advisor specializing in arrival time optimization. Respond only with valid JSON.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.7,
      max_tokens: 1500,
    });

    const aiResponse = completion.choices[0]?.message?.content;
    if (!aiResponse) {
      throw new Error('No response from AI');
    }

    // Parse AI response
    let recommendation: Partial<ArrivalTimeRecommendation>;
    try {
      recommendation = JSON.parse(aiResponse.trim());
    } catch (parseError) {
      console.error('Failed to parse AI response:', aiResponse);
      throw new Error('Invalid AI response format');
    }

    // Build final response
    const response: ArrivalTimeRecommendation = {
      mountainId: mountain.id,
      mountainName: mountain.name,
      generated: new Date().toISOString(),
      recommendedArrivalTime: recommendation.recommendedArrivalTime || '8:00 AM',
      arrivalWindow: recommendation.arrivalWindow || {
        earliest: '7:00 AM',
        optimal: '8:00 AM',
        latest: '9:00 AM',
      },
      confidence: recommendation.confidence || 'medium',
      reasoning: recommendation.reasoning || ['Optimal time based on typical conditions'],
      factors: recommendation.factors || {
        expectedCrowdLevel: 'medium',
        roadConditions: 'clear',
        weatherQuality: 'good',
        powderFreshness: 'packed',
        parkingDifficulty: 'moderate',
      },
      alternatives: recommendation.alternatives || [],
      tips: recommendation.tips || [],
    };

    return NextResponse.json(response);
  } catch (error) {
    console.error('Error generating arrival time recommendation:', error);
    return NextResponse.json(
      { error: 'Failed to generate arrival time recommendation' },
      { status: 500 }
    );
  }
}
