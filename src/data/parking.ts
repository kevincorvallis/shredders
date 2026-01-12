/**
 * Parking configurations for all mountains
 * Used by parking-predictor.ts to generate predictions
 */

export interface ParkingLotInfo {
  name: string;
  type: 'main' | 'overflow' | 'premium' | 'shuttle';
  capacity: 'large' | 'medium' | 'small';
  distanceToLift: string;
  notes?: string;
}

export interface MountainParkingConfig {
  mountainId: string;
  requiresReservation: boolean;
  reservationUrl?: string;
  paidParking: boolean;
  parkingCost?: string;
  shuttleAvailable: boolean;
  shuttleLotName?: string;
  lots: ParkingLotInfo[];
  specialNotes?: string[];
  // Bias factor for difficulty calculation (0-2)
  // Higher = more crowded/difficult parking
  difficultyBias: number;
}

export const parkingConfigs: Record<string, MountainParkingConfig> = {
  snoqualmie: {
    mountainId: 'snoqualmie',
    requiresReservation: false,
    paidParking: true,
    parkingCost: '$15-25',
    shuttleAvailable: true,
    shuttleLotName: 'Summit East',
    lots: [
      {
        name: 'Summit West',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
        notes: '$15 on peak days (7am-3pm)',
      },
      {
        name: 'Summit Central',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
        notes: '$15 on peak days (7am-3pm)',
      },
      {
        name: 'Summit East',
        type: 'overflow',
        capacity: 'large',
        distanceToLift: '0.3 mi',
        notes: '$15 on peak days, free shuttle to lifts',
      },
      {
        name: 'Alpental',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.1 mi',
        notes: '$25 on peak days (7am-3pm)',
      },
    ],
    specialNotes: [
      'Free parking for 3+ carpool in designated lots (first-come basis)',
      'Season passholders park free all season',
      'Paid parking on weekends, holidays Nov 29 - closing',
      'Payment via QR code or solar kiosks',
    ],
    difficultyBias: 2.0, // Highest - very busy on powder days
  },

  stevens: {
    mountainId: 'stevens',
    requiresReservation: true,
    reservationUrl: 'https://www.parkstevenspass.com',
    paidParking: true,
    parkingCost: '$20',
    shuttleAvailable: false,
    lots: [
      {
        name: 'Lot G',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
        notes: 'Reservation required until 10am on weekends/holidays',
      },
      {
        name: 'Lot A',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.2 mi',
        notes: 'Reservation required until 10am on weekends/holidays',
      },
      {
        name: 'Lot B',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.3 mi',
        notes: 'Reservation required until 10am on weekends/holidays',
      },
      {
        name: 'Lot E',
        type: 'overflow',
        capacity: 'medium',
        distanceToLift: '0.4 mi',
        notes: 'Reservation required until 10am on weekends/holidays',
      },
    ],
    specialNotes: [
      'Reserve N Ski: $20 reservation or free after 10am',
      'Free reservations: 4+ carpool, 1 adult + 2 kids, ADA, lesson participants',
      'Book at parkstevenspass.com',
      'Free parking weekdays (no reservation needed)',
    ],
    difficultyBias: 1.5, // High - Epic Pass resort, popular
  },

  crystal: {
    mountainId: 'crystal',
    requiresReservation: true,
    reservationUrl: 'https://parking.crystalmountainresort.com',
    paidParking: true,
    parkingCost: '$10 or free',
    shuttleAvailable: true,
    shuttleLotName: 'C Lot',
    lots: [
      {
        name: 'A-Lot',
        type: 'premium',
        capacity: 'medium',
        distanceToLift: '0.1 mi',
        notes: 'Premium lot, front parking, season pass available',
      },
      {
        name: 'B-Lot',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.2 mi',
        notes: 'Main parking area',
      },
      {
        name: 'C-Lot',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.3 mi',
        notes: '100 carpool spots (south end), shuttle available',
      },
      {
        name: 'Overflow Lots',
        type: 'overflow',
        capacity: 'medium',
        distanceToLift: '0.5 mi',
        notes: 'Shuttle to base area',
      },
    ],
    specialNotes: [
      'Reservations required Sat/Sun/Holidays before noon',
      '$10 advance or free with 7-day rolling window + lift ticket',
      'Free after noon on reservation days',
      'A-Lot pass holders exempt from reservations',
      '100 carpool spots added for 25/26 season',
    ],
    difficultyBias: 1.0, // Moderate - Ikon resort but manages well
  },

  baker: {
    mountainId: 'baker',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'White Salmon Day Lodge',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.1 mi',
        notes: 'Lower base area, Milepost 52',
      },
      {
        name: 'Heather Meadows Day Lodge',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.1 mi',
        notes: 'Upper base area, Milepost 54',
      },
      {
        name: 'Hwy 542 Roadside',
        type: 'overflow',
        capacity: 'small',
        distanceToLift: '0.2 mi',
        notes: '7am-7pm only at Heather Meadows',
      },
    ],
    specialNotes: [
      'Limited parking spaces - arrive early on powder days',
      'Free parking, no reservations',
      'Overnight parking requires advance reservation',
      'Check Tips page for daily lot status updates',
      'Chains required on vehicles past milepost 44',
    ],
    difficultyBias: 0.8, // Moderate-low - small area but limited parking
  },

  whistler: {
    mountainId: 'whistler',
    requiresReservation: true,
    reservationUrl: 'https://www.whistlerblackcombparking.com',
    paidParking: false,
    shuttleAvailable: true,
    shuttleLotName: 'Village lots',
    lots: [
      {
        name: 'Creekside P1',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
        notes: 'Reservation required 6am-11am on peak days',
      },
      {
        name: 'Creekside P2',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.2 mi',
        notes: 'Reservation required 6am-11am on peak days',
      },
      {
        name: 'Upper Lot 6',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
        notes: 'Whistler Village, reservation required 6am-11am',
      },
      {
        name: 'Upper Lot 7',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.2 mi',
        notes: 'Whistler Village, reservation required 6am-11am',
      },
      {
        name: 'Village Day Lots',
        type: 'overflow',
        capacity: 'large',
        distanceToLift: '0.3 mi',
        notes: 'Free, no reservation required at any time',
      },
    ],
    specialNotes: [
      'FREE Reserve N Ski parking reservations',
      'Reservations required 6am-11am weekends/holidays/Dec 27-31',
      'Free parking after 11am (no reservation needed)',
      'Cancel up to 8am day-of',
      'Alternative free lots available first-come, first-served',
    ],
    difficultyBias: 1.2, // Moderate-high - major resort, good capacity
  },

  bachelor: {
    mountainId: 'bachelor',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: true,
    shuttleLotName: 'Interlodge shuttle between all lots',
    lots: [
      {
        name: 'West Village',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
        notes: 'Main base area, closest to lifts',
      },
      {
        name: 'Sunrise Lodge',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.2 mi',
        notes: 'East side base area',
      },
      {
        name: 'Pine Marten',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.3 mi',
        notes: 'Mid-mountain access',
      },
      {
        name: 'Premium Parking',
        type: 'premium',
        capacity: 'small',
        distanceToLift: '0.05 mi',
        notes: 'Paid premium spots available for purchase',
      },
    ],
    specialNotes: [
      'Free parking, no reservations required',
      'Premium parking available for purchase',
      'Free Interlodge shuttle connects all lots and base areas',
      'Rarely fills up, even on powder days',
      'Shuttle from Bend available via Cascades East Transit',
    ],
    difficultyBias: 0.3, // Low - rarely has parking issues
  },

  // Remaining 10 mountains with basic configs (to be researched)
  whitepass: {
    mountainId: 'whitepass',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking', 'Rarely fills up'],
    difficultyBias: 0.2,
  },

  missionridge: {
    mountainId: 'missionridge',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking', 'Arrives early on powder days recommended'],
    difficultyBias: 0.4,
  },

  fortynine: {
    mountainId: 'fortynine',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'small',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking', 'Small area, rarely fills'],
    difficultyBias: 0.2,
  },

  meadows: {
    mountainId: 'meadows',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: true,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
      },
      {
        name: 'Overflow Lot',
        type: 'overflow',
        capacity: 'medium',
        distanceToLift: '0.3 mi',
      },
    ],
    specialNotes: ['Free parking', 'Shuttle from overflow on busy days'],
    difficultyBias: 0.6,
  },

  timberline: {
    mountainId: 'timberline',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking', 'Year-round operation'],
    difficultyBias: 0.5,
  },

  ashland: {
    mountainId: 'ashland',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'small',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking', 'Small community area'],
    difficultyBias: 0.1,
  },

  willamette: {
    mountainId: 'willamette',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking'],
    difficultyBias: 0.3,
  },

  hoodoo: {
    mountainId: 'hoodoo',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'medium',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking'],
    difficultyBias: 0.3,
  },

  schweitzer: {
    mountainId: 'schweitzer',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'large',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking', 'Ikon resort - can be busy on powder days'],
    difficultyBias: 0.7,
  },

  lookout: {
    mountainId: 'lookout',
    requiresReservation: false,
    paidParking: false,
    shuttleAvailable: false,
    lots: [
      {
        name: 'Main Lot',
        type: 'main',
        capacity: 'small',
        distanceToLift: '0.1 mi',
      },
    ],
    specialNotes: ['Free parking', 'Small area, rarely fills'],
    difficultyBias: 0.2,
  },
};

export function getParkingConfig(mountainId: string): MountainParkingConfig | null {
  return parkingConfigs[mountainId] || null;
}
