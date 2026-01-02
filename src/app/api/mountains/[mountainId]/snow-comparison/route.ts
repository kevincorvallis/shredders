import { NextResponse } from 'next/server';
import { getYearOverYearComparison } from '@/lib/apis/snotel';
import { getMountain } from '@/data/mountains';

/**
 * Snow depth guidelines by elevation range
 * Based on ski industry standards and historical data
 */
const BASE_DEPTH_GUIDELINES = {
  // Low elevation (< 4000 ft)
  low: {
    minimal: 30,   // Barely skiable, rocks showing
    poor: 50,      // Limited terrain open
    fair: 75,      // Most runs open but thin
    good: 100,     // Good coverage
    excellent: 150 // Excellent coverage
  },
  // Mid elevation (4000-6000 ft)
  mid: {
    minimal: 40,
    poor: 60,
    fair: 90,
    good: 120,
    excellent: 180
  },
  // High elevation (> 6000 ft)
  high: {
    minimal: 50,
    poor: 75,
    fair: 110,
    good: 150,
    excellent: 200
  }
};

function getElevationCategory(baseElevation: number): 'low' | 'mid' | 'high' {
  if (baseElevation < 4000) return 'low';
  if (baseElevation < 6000) return 'mid';
  return 'high';
}

function getBaseDepthRating(snowDepth: number, elevationCategory: 'low' | 'mid' | 'high'): {
  rating: string;
  description: string;
  color: string;
} {
  const guidelines = BASE_DEPTH_GUIDELINES[elevationCategory];

  if (snowDepth >= guidelines.excellent) {
    return {
      rating: 'Excellent',
      description: `Outstanding base (${guidelines.excellent}"+ typical for excellent conditions)`,
      color: '#22c55e' // green
    };
  } else if (snowDepth >= guidelines.good) {
    return {
      rating: 'Good',
      description: `Solid base (${guidelines.good}"+ typical for good coverage)`,
      color: '#3b82f6' // blue
    };
  } else if (snowDepth >= guidelines.fair) {
    return {
      rating: 'Fair',
      description: `Adequate base (${guidelines.fair}"+ typical for fair coverage)`,
      color: '#eab308' // yellow
    };
  } else if (snowDepth >= guidelines.poor) {
    return {
      rating: 'Poor',
      description: `Limited base (${guidelines.poor}"+ typical for limited coverage)`,
      color: '#f97316' // orange
    };
  } else if (snowDepth >= guidelines.minimal) {
    return {
      rating: 'Minimal',
      description: `Very thin base (${guidelines.minimal}"+ barely skiable)`,
      color: '#ef4444' // red
    };
  } else {
    return {
      rating: 'Insufficient',
      description: 'Base too thin for safe skiing',
      color: '#991b1b' // dark red
    };
  }
}

/**
 * GET /api/mountains/[mountainId]/snow-comparison
 *
 * Returns year-over-year snow depth comparison and "good base" context
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  try {
    const { mountainId } = await params;

    // Find mountain configuration
    const mountain = getMountain(mountainId);
    if (!mountain) {
      return NextResponse.json(
        { error: 'Mountain not found' },
        { status: 404 }
      );
    }

    if (!mountain.snotel?.stationId) {
      return NextResponse.json(
        { error: 'No SNOTEL data available for this mountain' },
        { status: 404 }
      );
    }

    // Fetch year-over-year comparison
    const comparison = await getYearOverYearComparison(mountain.snotel.stationId);

    // Determine elevation category for base depth guidelines
    const elevationCategory = getElevationCategory(mountain.elevation.base);
    const guidelines = BASE_DEPTH_GUIDELINES[elevationCategory];

    // Get current depth rating if available
    const currentRating = comparison.currentYear
      ? getBaseDepthRating(comparison.currentYear.snowDepth, elevationCategory)
      : null;

    return NextResponse.json({
      mountain: {
        id: mountain.id,
        name: mountain.name,
        elevation: mountain.elevation,
        elevationCategory
      },
      comparison: {
        current: comparison.currentYear,
        lastYear: comparison.lastYear,
        difference: comparison.currentYear && comparison.lastYear
          ? comparison.currentYear.snowDepth - comparison.lastYear.snowDepth
          : null,
        percentChange: comparison.currentYear && comparison.lastYear && comparison.lastYear.snowDepth > 0
          ? Math.round(((comparison.currentYear.snowDepth - comparison.lastYear.snowDepth) / comparison.lastYear.snowDepth) * 100)
          : null
      },
      baseDepthGuidelines: {
        elevationCategory,
        thresholds: guidelines,
        currentRating
      }
    }, {
      headers: {
        'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=86400'
      }
    });

  } catch (error: any) {
    console.error('Error in snow-comparison endpoint:', error);
    return NextResponse.json(
      {
        error: 'Failed to fetch snow comparison data',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}
