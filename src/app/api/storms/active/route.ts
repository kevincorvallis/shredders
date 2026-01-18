import { NextResponse } from 'next/server';
import { getAllMountains, getMountainsByRegion, type MountainConfig } from '@shredders/shared';
import { getExtendedForecast, type ExtendedDailyForecast } from '@/lib/apis/open-meteo';
import {
  detectStorms,
  analyzeStorm,
  type StormEvent,
  type StormAnalysis,
} from '@/lib/calculations/storm-analyzer';

export interface ActiveStormsResponse {
  storms: StormAnalysis[];
  summary: string;
  totalStormsNext7Days: number;
  mostFavoredMountain: string | null;
  mostFavoredRegion: string | null;
  generatedAt: string;
}

// Use a representative mountain from each region to detect storms
const REPRESENTATIVE_MOUNTAINS = [
  'baker',    // WA North
  'crystal',  // WA Central
  'meadows',  // OR North
  'bachelor', // OR Central
  'schweitzer', // ID
  'whistler', // BC
];

export async function GET(request: Request) {
  const url = new URL(request.url);
  const region = url.searchParams.get('region');

  try {
    // Determine which mountains to analyze
    let mountainsToAnalyze: MountainConfig[];

    if (region) {
      // Filter by region
      const validRegions = ['washington', 'oregon', 'idaho', 'canada'];
      if (!validRegions.includes(region)) {
        return NextResponse.json(
          { error: `Invalid region: ${region}. Valid regions: ${validRegions.join(', ')}` },
          { status: 400 }
        );
      }
      mountainsToAnalyze = getMountainsByRegion(region as 'washington' | 'oregon' | 'idaho' | 'canada');
    } else {
      // All mountains
      mountainsToAnalyze = getAllMountains();
    }

    // Get representative mountains for storm detection
    const representativeMountains = region
      ? mountainsToAnalyze.slice(0, 2)
      : getAllMountains().filter(m => REPRESENTATIVE_MOUNTAINS.includes(m.id));

    if (representativeMountains.length === 0) {
      return NextResponse.json({
        storms: [],
        summary: 'No mountains available for analysis',
        totalStormsNext7Days: 0,
        mostFavoredMountain: null,
        mostFavoredRegion: null,
        generatedAt: new Date().toISOString(),
      });
    }

    // Fetch forecast from first representative mountain to detect storms
    const repMountain = representativeMountains[0];
    const forecast = await getExtendedForecast(
      repMountain.location.lat,
      repMountain.location.lng,
      10
    );

    // Detect storms
    const storms = detectStorms(forecast);

    if (storms.length === 0) {
      return NextResponse.json({
        storms: [],
        summary: 'No significant storm systems detected in the next 10 days.',
        totalStormsNext7Days: 0,
        mostFavoredMountain: null,
        mostFavoredRegion: null,
        generatedAt: new Date().toISOString(),
      });
    }

    // Analyze each storm against all mountains
    const stormAnalyses = storms.map(storm => analyzeStorm(storm, mountainsToAnalyze));

    // Calculate aggregate stats
    const mountainScores = new Map<string, number>();
    const regionScores = new Map<string, number>();

    for (const analysis of stormAnalyses) {
      for (const impact of analysis.impacts) {
        const currentScore = mountainScores.get(impact.mountainId) || 0;
        mountainScores.set(impact.mountainId, currentScore + impact.impactScore);

        const mountain = mountainsToAnalyze.find(m => m.id === impact.mountainId);
        if (mountain) {
          const regionScore = regionScores.get(mountain.region) || 0;
          regionScores.set(mountain.region, regionScore + impact.impactScore);
        }
      }
    }

    // Find most favored mountain and region
    let mostFavoredMountain: string | null = null;
    let maxMountainScore = 0;
    for (const [mountainId, score] of mountainScores.entries()) {
      if (score > maxMountainScore) {
        maxMountainScore = score;
        const mountain = mountainsToAnalyze.find(m => m.id === mountainId);
        mostFavoredMountain = mountain?.name || mountainId;
      }
    }

    let mostFavoredRegion: string | null = null;
    let maxRegionScore = 0;
    for (const [regionId, score] of regionScores.entries()) {
      if (score > maxRegionScore) {
        maxRegionScore = score;
        mostFavoredRegion = regionId.charAt(0).toUpperCase() + regionId.slice(1);
      }
    }

    // Generate summary
    let summary: string;
    if (storms.length === 1) {
      const storm = stormAnalyses[0];
      summary = `One storm system approaching: ${storm.storm.name}. ${storm.favorsText}.`;
    } else {
      const totalSnow = storms.reduce((sum, s) => sum + s.expectedSnow, 0);
      summary = `${storms.length} storm systems expected over the next 10 days bringing ${Math.round(totalSnow)}" total potential snowfall. Overall pattern favors ${mostFavoredRegion}.`;
    }

    const response: ActiveStormsResponse = {
      storms: stormAnalyses,
      summary,
      totalStormsNext7Days: storms.filter(s => {
        const startDate = new Date(s.startDate);
        const now = new Date();
        const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        return startDate <= sevenDaysFromNow;
      }).length,
      mostFavoredMountain,
      mostFavoredRegion,
      generatedAt: new Date().toISOString(),
    };

    return NextResponse.json(response, {
      headers: {
        'Cache-Control': 'public, max-age=1800', // 30 min cache
      },
    });
  } catch (error) {
    console.error('Error fetching active storms:', error);
    return NextResponse.json(
      { error: 'Failed to fetch active storms' },
      { status: 500 }
    );
  }
}
