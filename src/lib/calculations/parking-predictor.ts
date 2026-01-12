import { getParkingConfig, type ParkingLotInfo } from '@/data/parking';

type ParkingDifficulty = 'easy' | 'moderate' | 'challenging' | 'very-difficult';
type Confidence = 'high' | 'medium' | 'low';
type LotAvailability = 'likely' | 'limited' | 'full';

export interface ParkingPredictionInput {
  mountainId: string;
  mountainName: string;
  powderScore?: number | null;
  upcomingSnow48h?: number | null;
  isWeekend: boolean;
  isHolidayWindow: boolean;
  arrivalHour?: number; // 0-23, optional for time-based adjustment
}

export interface ParkingLotRecommendation extends ParkingLotInfo {
  availability: LotAvailability;
  arrivalTime?: string;
}

export interface ParkingPredictionResult {
  generated: string;
  difficulty: ParkingDifficulty;
  confidence: Confidence;
  headline: string;
  recommendedArrivalTime: string;
  recommendedLots: ParkingLotRecommendation[];
  tips: string[];
  reservationUrl?: string;
  reservationRequired: boolean;
}

function clampDifficulty(score: number): ParkingDifficulty {
  if (score >= 7) return 'very-difficult';
  if (score >= 5) return 'challenging';
  if (score >= 3) return 'moderate';
  return 'easy';
}

function scorePowderInterest(powderScore?: number | null, upcomingSnow48h?: number | null): number {
  let score = 0;

  // Powder score contribution (0-2 points)
  if ((powderScore ?? 0) >= 8) score += 2;
  else if ((powderScore ?? 0) >= 6) score += 1;

  // Upcoming snow contribution (0-2 points)
  if ((upcomingSnow48h ?? 0) >= 12) score += 2;
  else if ((upcomingSnow48h ?? 0) >= 6) score += 1;

  return score;
}

function getTimeAdjustment(arrivalHour?: number): number {
  if (!arrivalHour) return 0;

  // Before 6 AM: -1 (very early, better parking)
  if (arrivalHour < 6) return -1;

  // 6-7 AM: 0 (optimal arrival time)
  if (arrivalHour < 8) return 0;

  // 8-9 AM: +1 (near opening, getting crowded)
  if (arrivalHour < 10) return 1;

  // After 9 AM: +2 (late arrival, parking difficult)
  return 2;
}

function getRecommendedArrivalTime(
  difficulty: ParkingDifficulty,
  reservationRequired: boolean,
  arrivalHour?: number
): string {
  // If user specified arrival time, validate it
  if (arrivalHour !== undefined) {
    if (difficulty === 'very-difficult' && arrivalHour >= 7) {
      return 'Before 6:30 AM recommended';
    }
    if (difficulty === 'challenging' && arrivalHour >= 8) {
      return 'Before 7:30 AM recommended';
    }
  }

  // Default recommendations based on difficulty
  if (difficulty === 'very-difficult') {
    return reservationRequired
      ? 'Reserve parking ASAP, arrive by 6:30 AM'
      : 'Arrive before 6:30 AM';
  }

  if (difficulty === 'challenging') {
    return reservationRequired
      ? 'Reserve parking, arrive by 7:30 AM'
      : 'Arrive before 7:30 AM';
  }

  if (difficulty === 'moderate') {
    return reservationRequired
      ? 'Reserve parking or arrive after 10 AM'
      : 'Arrive before 8:30 AM for best spots';
  }

  return 'Standard arrival time (8-9 AM) should be fine';
}

function assessLotAvailability(
  lot: ParkingLotInfo,
  difficultyScore: number,
  isMainLot: boolean
): LotAvailability {
  // Premium/shuttle lots usually have better availability
  if (lot.type === 'premium') return 'likely';

  // Overflow lots fill last
  if (lot.type === 'overflow') {
    if (difficultyScore >= 7) return 'limited';
    return 'likely';
  }

  // Main lots based on difficulty
  if (isMainLot) {
    if (difficultyScore >= 7) return 'full';
    if (difficultyScore >= 5) return 'limited';
    if (difficultyScore >= 3) return 'limited';
    return 'likely';
  }

  // Shuttle lots
  if (difficultyScore >= 7) return 'limited';
  return 'likely';
}

export function computeParkingPrediction(input: ParkingPredictionInput): ParkingPredictionResult {
  const config = getParkingConfig(input.mountainId);

  // If no parking config, return default low-confidence prediction
  if (!config) {
    return {
      generated: new Date().toISOString(),
      difficulty: 'moderate',
      confidence: 'low',
      headline: 'Parking information unavailable',
      recommendedArrivalTime: 'Arrive early for best parking',
      recommendedLots: [],
      tips: ['Check resort website for current parking status'],
      reservationRequired: false,
    };
  }

  // Calculate parking difficulty score
  const powderInterest = scorePowderInterest(input.powderScore, input.upcomingSnow48h);
  let difficultyScore = 0;

  // Powder interest (0-4 points)
  difficultyScore += powderInterest;

  // Weekend/Holiday (0-3 points)
  if (input.isWeekend) difficultyScore += 1.5;
  if (input.isHolidayWindow) difficultyScore += 1.5;

  // Mountain-specific bias (0-2 points)
  difficultyScore += config.difficultyBias;

  // Time adjustment (-1 to +2 points)
  difficultyScore += getTimeAdjustment(input.arrivalHour);

  const difficulty = clampDifficulty(difficultyScore);

  // Confidence based on data availability
  let confidence: Confidence = 'high';
  if (!input.powderScore && !input.upcomingSnow48h) {
    confidence = 'medium';
  }

  // Generate lot recommendations
  const recommendedLots: ParkingLotRecommendation[] = config.lots.map((lot, index) => ({
    ...lot,
    availability: assessLotAvailability(lot, difficultyScore, index < 2),
    arrivalTime: lot.type === 'main' ? 'Before 8 AM' : 'After 9 AM often available',
  }));

  // Sort lots by availability (likely first)
  recommendedLots.sort((a, b) => {
    const order = { likely: 0, limited: 1, full: 2 };
    return order[a.availability] - order[b.availability];
  });

  // Generate tips
  const tips: string[] = [];

  if (config.requiresReservation) {
    tips.push(`Make a parking reservation at ${config.reservationUrl || 'resort website'}`);
  }

  if (config.paidParking && config.parkingCost) {
    tips.push(`Paid parking: ${config.parkingCost} on peak days`);
  }

  if (difficulty === 'very-difficult') {
    tips.push('Expect full lots - arrive very early or consider carpooling');
  } else if (difficulty === 'challenging') {
    tips.push('Lots may fill up - aim for early arrival');
  }

  if (input.isWeekend && !config.requiresReservation) {
    tips.push('Weekend: Main lots typically fill by 9 AM on powder days');
  }

  if (powderInterest >= 3) {
    tips.push('Fresh powder expected - parking will be at a premium');
  }

  if (config.shuttleAvailable && config.shuttleLotName) {
    tips.push(`Free shuttle available from ${config.shuttleLotName}`);
  }

  // Add mountain-specific special notes (max 2)
  if (config.specialNotes && config.specialNotes.length > 0) {
    tips.push(...config.specialNotes.slice(0, 2));
  }

  // Generate headline
  let headline = '';
  if (difficulty === 'very-difficult') {
    headline = config.requiresReservation
      ? 'Reservations strongly recommended'
      : 'Very limited parking expected';
  } else if (difficulty === 'challenging') {
    headline = config.requiresReservation
      ? 'Reserve parking or arrive early'
      : 'Limited parking expected';
  } else if (difficulty === 'moderate') {
    headline = 'Moderate parking availability';
  } else {
    headline = 'Parking should be available';
  }

  return {
    generated: new Date().toISOString(),
    difficulty,
    confidence,
    headline,
    recommendedArrivalTime: getRecommendedArrivalTime(
      difficulty,
      config.requiresReservation,
      input.arrivalHour
    ),
    recommendedLots,
    tips: tips.slice(0, 5), // Limit to 5 tips
    reservationUrl: config.reservationUrl,
    reservationRequired: config.requiresReservation,
  };
}

// Re-export helper functions from trip-advice for consistency
export { isWeekend, isHolidayWindow } from './trip-advice';
