import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import {
  computeParkingPrediction,
  isWeekend,
  isHolidayWindow,
  type ParkingPredictionInput,
} from '@/lib/calculations/parking-predictor';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  const { mountainId } = await params;
  const mountain = getMountain(mountainId);

  if (!mountain) {
    return NextResponse.json(
      { error: `Mountain '${mountainId}' not found` },
      { status: 404 }
    );
  }

  try {
    // Fetch powder score for powder interest calculation
    let powderScore: number | null = null;
    let upcomingSnow48h: number | null = null;

    try {
      const powderResponse = await fetch(
        `${process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000'}/api/mountains/${mountainId}/powder-score`,
        {
          next: { revalidate: 1800 }, // 30 min cache
        }
      );

      if (powderResponse.ok) {
        const powderData = await powderResponse.json();
        powderScore = powderData.score ?? null;
        upcomingSnow48h = powderData.conditions?.upcomingSnow ?? null;
      }
    } catch (error) {
      console.error(`Failed to fetch powder score for ${mountain.name}:`, error);
      // Continue with prediction even without powder score
    }

    // Determine current day/time context
    const now = new Date();
    const currentIsWeekend = isWeekend(now);
    const currentIsHolidayWindow = isHolidayWindow(now);
    const currentHour = now.getHours();

    // Build prediction input
    const input: ParkingPredictionInput = {
      mountainId: mountain.id,
      mountainName: mountain.name,
      powderScore,
      upcomingSnow48h,
      isWeekend: currentIsWeekend,
      isHolidayWindow: currentIsHolidayWindow,
      arrivalHour: currentHour,
    };

    // Compute prediction
    const prediction = computeParkingPrediction(input);

    // Build response matching the plan format
    const response = {
      mountain: {
        id: mountain.id,
        name: mountain.name,
        shortName: mountain.shortName,
      },
      generated: prediction.generated,
      difficulty: prediction.difficulty,
      confidence: prediction.confidence,
      recommendedArrivalTime: prediction.recommendedArrivalTime,
      recommendedLots: prediction.recommendedLots,
      tips: prediction.tips,
      reservationUrl: prediction.reservationUrl || null,
      reservationRequired: prediction.reservationRequired,
      headline: prediction.headline,
      // Include context for debugging
      context: {
        powderScore,
        upcomingSnow48h,
        isWeekend: currentIsWeekend,
        isHolidayWindow: currentIsHolidayWindow,
        currentHour,
      },
    };

    return NextResponse.json(response, {
      headers: {
        'Cache-Control': 'public, s-maxage=1800, stale-while-revalidate=3600', // 30 min cache
      },
    });
  } catch (error) {
    console.error('Error generating parking prediction:', error);
    return NextResponse.json(
      {
        error: 'Failed to generate parking prediction',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
