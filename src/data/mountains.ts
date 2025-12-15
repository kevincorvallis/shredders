export interface MountainConfig {
  id: string;
  name: string;
  shortName: string;
  location: {
    lat: number;
    lng: number;
  };
  elevation: {
    base: number;
    summit: number;
  };
  region: 'washington' | 'oregon' | 'idaho';
  snotel?: {
    stationId: string;
    stationName: string;
  };
  noaa: {
    gridOffice: string;
    gridX: number;
    gridY: number;
  };
  webcams: {
    id: string;
    name: string;
    url: string;
    refreshUrl?: string;
  }[];
  color: string;
  website: string;
}

export const mountains: Record<string, MountainConfig> = {
  baker: {
    id: 'baker',
    name: 'Mt. Baker',
    shortName: 'Baker',
    location: { lat: 48.857, lng: -121.669 },
    elevation: { base: 3500, summit: 5089 },
    region: 'washington',
    snotel: {
      stationId: '910:WA:SNTL',
      stationName: 'Wells Creek',
    },
    noaa: { gridOffice: 'SEW', gridX: 157, gridY: 123 },
    webcams: [
      {
        id: 'chair8',
        name: 'Chair 8',
        url: 'https://www.mtbaker.us/images/webcam/C8.jpg',
        refreshUrl: 'https://www.mtbaker.us/snow-report/webcams',
      },
      {
        id: 'base',
        name: 'White Salmon Base',
        url: 'https://www.mtbaker.us/images/webcam/WSday.jpg',
        refreshUrl: 'https://www.mtbaker.us/snow-report/webcams',
      },
      {
        id: 'pan',
        name: 'Pan Dome',
        url: 'https://www.mtbaker.us/images/webcam/pan.jpg',
        refreshUrl: 'https://www.mtbaker.us/snow-report/webcams',
      },
    ],
    color: '#3b82f6',
    website: 'https://www.mtbaker.us',
  },

  stevens: {
    id: 'stevens',
    name: 'Stevens Pass',
    shortName: 'Stevens',
    location: { lat: 47.745, lng: -121.089 },
    elevation: { base: 4061, summit: 5845 },
    region: 'washington',
    snotel: {
      stationId: '791:WA:SNTL',
      stationName: 'Stevens Pass',
    },
    noaa: { gridOffice: 'SEW', gridX: 163, gridY: 108 },
    webcams: [
      {
        id: 'base',
        name: 'Base Area',
        url: 'https://www.stevenspass.com/site/webcams/base-area.jpg',
        refreshUrl: 'https://www.stevenspass.com/the-mountain/conditions-weather/webcams',
      },
    ],
    color: '#10b981',
    website: 'https://www.stevenspass.com',
  },

  crystal: {
    id: 'crystal',
    name: 'Crystal Mountain',
    shortName: 'Crystal',
    location: { lat: 46.935, lng: -121.474 },
    elevation: { base: 4400, summit: 7012 },
    region: 'washington',
    snotel: {
      stationId: '679:WA:SNTL',
      stationName: 'Morse Lake',
    },
    noaa: { gridOffice: 'SEW', gridX: 142, gridY: 90 },
    webcams: [
      {
        id: 'summit',
        name: 'Summit House',
        url: 'https://www.crystalmountainresort.com/webcam/summit.jpg',
        refreshUrl: 'https://www.crystalmountainresort.com/the-mountain/webcams',
      },
    ],
    color: '#8b5cf6',
    website: 'https://www.crystalmountainresort.com',
  },

  snoqualmie: {
    id: 'snoqualmie',
    name: 'Summit at Snoqualmie',
    shortName: 'Snoqualmie',
    location: { lat: 47.428, lng: -121.413 },
    elevation: { base: 3000, summit: 5400 },
    region: 'washington',
    snotel: {
      stationId: '777:WA:SNTL',
      stationName: 'Snoqualmie Pass',
    },
    noaa: { gridOffice: 'SEW', gridX: 152, gridY: 97 },
    webcams: [
      {
        id: 'central',
        name: 'Central Base',
        url: 'https://www.summitatsnoqualmie.com/webcam/central.jpg',
        refreshUrl: 'https://www.summitatsnoqualmie.com/conditions-weather/webcams',
      },
    ],
    color: '#f59e0b',
    website: 'https://www.summitatsnoqualmie.com',
  },

  whitepass: {
    id: 'whitepass',
    name: 'White Pass',
    shortName: 'White Pass',
    location: { lat: 46.637, lng: -121.391 },
    elevation: { base: 4500, summit: 6500 },
    region: 'washington',
    snotel: {
      stationId: '898:WA:SNTL',
      stationName: 'White Pass ES',
    },
    noaa: { gridOffice: 'PDT', gridX: 131, gridY: 80 },
    webcams: [
      {
        id: 'base',
        name: 'Base Lodge',
        url: 'https://skiwhitepass.com/webcam/base.jpg',
        refreshUrl: 'https://skiwhitepass.com/conditions',
      },
    ],
    color: '#ec4899',
    website: 'https://skiwhitepass.com',
  },

  meadows: {
    id: 'meadows',
    name: 'Mt. Hood Meadows',
    shortName: 'Meadows',
    location: { lat: 45.331, lng: -121.665 },
    elevation: { base: 4523, summit: 7300 },
    region: 'oregon',
    snotel: {
      stationId: '651:OR:SNTL',
      stationName: 'Mt Hood Test Site',
    },
    noaa: { gridOffice: 'PQR', gridX: 138, gridY: 105 },
    webcams: [
      {
        id: 'vista',
        name: 'Vista Express',
        url: 'https://www.skihood.com/webcam/vista.jpg',
        refreshUrl: 'https://www.skihood.com/conditions/webcams',
      },
    ],
    color: '#06b6d4',
    website: 'https://www.skihood.com',
  },

  timberline: {
    id: 'timberline',
    name: 'Timberline Lodge',
    shortName: 'Timberline',
    location: { lat: 45.331, lng: -121.711 },
    elevation: { base: 4540, summit: 8540 },
    region: 'oregon',
    snotel: {
      stationId: '651:OR:SNTL',
      stationName: 'Mt Hood Test Site',
    },
    noaa: { gridOffice: 'PQR', gridX: 136, gridY: 103 },
    webcams: [
      {
        id: 'lodge',
        name: 'Timberline Lodge',
        url: 'https://www.timberlinelodge.com/webcam/lodge.jpg',
        refreshUrl: 'https://www.timberlinelodge.com/conditions',
      },
    ],
    color: '#14b8a6',
    website: 'https://www.timberlinelodge.com',
  },

  bachelor: {
    id: 'bachelor',
    name: 'Mt. Bachelor',
    shortName: 'Bachelor',
    location: { lat: 43.979, lng: -121.688 },
    elevation: { base: 5700, summit: 9065 },
    region: 'oregon',
    snotel: {
      stationId: '366:OR:SNTL',
      stationName: 'Dutchman Flat',
    },
    noaa: { gridOffice: 'PDT', gridX: 118, gridY: 43 },
    webcams: [
      {
        id: 'summit',
        name: 'Summit',
        url: 'https://www.mtbachelor.com/webcam/summit.jpg',
        refreshUrl: 'https://www.mtbachelor.com/conditions/webcams',
      },
    ],
    color: '#f97316',
    website: 'https://www.mtbachelor.com',
  },

  // Washington - Eastern
  missionridge: {
    id: 'missionridge',
    name: 'Mission Ridge',
    shortName: 'Mission Ridge',
    location: { lat: 47.293, lng: -120.398 },
    elevation: { base: 4570, summit: 6820 },
    region: 'washington',
    snotel: {
      stationId: '349:WA:SNTL',
      stationName: 'Blewett Pass',
    },
    noaa: { gridOffice: 'OTX', gridX: 53, gridY: 107 },
    webcams: [
      {
        id: 'base',
        name: 'Base Area',
        url: 'https://www.missionridge.com/webcam.jpg',
      },
    ],
    color: '#dc2626',
    website: 'https://www.missionridge.com',
  },

  fortynine: {
    id: 'fortynine',
    name: '49 Degrees North',
    shortName: '49°N',
    location: { lat: 48.795, lng: -117.565 },
    elevation: { base: 3923, summit: 5774 },
    region: 'washington',
    snotel: {
      stationId: '699:WA:SNTL',
      stationName: 'Pope Ridge',
    },
    noaa: { gridOffice: 'OTX', gridX: 118, gridY: 135 },
    webcams: [
      {
        id: 'base',
        name: 'Base Lodge',
        url: 'https://www.ski49n.com/webcam.jpg',
      },
    ],
    color: '#7c3aed',
    website: 'https://www.ski49n.com',
  },

  // Idaho
  schweitzer: {
    id: 'schweitzer',
    name: 'Schweitzer Mountain',
    shortName: 'Schweitzer',
    location: { lat: 48.368, lng: -116.622 },
    elevation: { base: 4000, summit: 6400 },
    region: 'idaho',
    snotel: {
      stationId: '738:ID:SNTL',
      stationName: 'Schweitzer Basin',
    },
    noaa: { gridOffice: 'OTX', gridX: 131, gridY: 123 },
    webcams: [
      {
        id: 'summit',
        name: 'Summit',
        url: 'https://www.schweitzer.com/webcam.jpg',
      },
    ],
    color: '#0ea5e9',
    website: 'https://www.schweitzer.com',
  },

  lookout: {
    id: 'lookout',
    name: 'Lookout Pass',
    shortName: 'Lookout',
    location: { lat: 47.454, lng: -115.713 },
    elevation: { base: 4150, summit: 5650 },
    region: 'idaho',
    snotel: {
      stationId: '579:ID:SNTL',
      stationName: 'Lookout',
    },
    noaa: { gridOffice: 'MSO', gridX: 159, gridY: 82 },
    webcams: [
      {
        id: 'base',
        name: 'Base Area',
        url: 'https://www.skilookout.com/webcam.jpg',
      },
    ],
    color: '#059669',
    website: 'https://www.skilookout.com',
  },

  // Oregon - Southern
  ashland: {
    id: 'ashland',
    name: 'Mt. Ashland',
    shortName: 'Ashland',
    location: { lat: 42.086, lng: -122.715 },
    elevation: { base: 6350, summit: 7533 },
    region: 'oregon',
    snotel: {
      stationId: '341:OR:SNTL',
      stationName: 'Big Red Mountain',
    },
    noaa: { gridOffice: 'MFR', gridX: 89, gridY: 62 },
    webcams: [
      {
        id: 'lodge',
        name: 'Lodge',
        url: 'https://www.mtashland.com/webcam.jpg',
      },
    ],
    color: '#ea580c',
    website: 'https://www.mtashland.com',
  },

  willamette: {
    id: 'willamette',
    name: 'Willamette Pass',
    shortName: 'Willamette',
    location: { lat: 43.596, lng: -122.039 },
    elevation: { base: 5128, summit: 6683 },
    region: 'oregon',
    snotel: {
      stationId: '388:OR:SNTL',
      stationName: 'Cascade Summit',
    },
    noaa: { gridOffice: 'PQR', gridX: 112, gridY: 69 },
    webcams: [
      {
        id: 'base',
        name: 'Base Area',
        url: 'https://www.willamettepass.com/webcam.jpg',
      },
    ],
    color: '#84cc16',
    website: 'https://www.willamettepass.com',
  },

  hoodoo: {
    id: 'hoodoo',
    name: 'Hoodoo Ski Area',
    shortName: 'Hoodoo',
    location: { lat: 44.408, lng: -121.870 },
    elevation: { base: 4668, summit: 5703 },
    region: 'oregon',
    snotel: {
      stationId: '801:OR:SNTL',
      stationName: 'Summit Lake',
    },
    noaa: { gridOffice: 'PDT', gridX: 107, gridY: 65 },
    webcams: [
      {
        id: 'base',
        name: 'Base Lodge',
        url: 'https://www.skihoodoo.com/webcam.jpg',
      },
    ],
    color: '#f472b6',
    website: 'https://www.skihoodoo.com',
  },
};

export function getMountain(id: string): MountainConfig | undefined {
  return mountains[id];
}

export function getAllMountains(): MountainConfig[] {
  return Object.values(mountains);
}

export function getMountainsByRegion(region: 'washington' | 'oregon' | 'idaho'): MountainConfig[] {
  return getAllMountains().filter((m) => m.region === region);
}

export function getDefaultMountain(): MountainConfig {
  return mountains.baker;
}

// Calculate distance between two points in miles
export function calculateDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 3959; // Earth's radius in miles
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export function getMountainsSortedByDistance(
  userLat: number,
  userLng: number
): (MountainConfig & { distance: number })[] {
  return getAllMountains()
    .map((mountain) => ({
      ...mountain,
      distance: calculateDistance(
        userLat,
        userLng,
        mountain.location.lat,
        mountain.location.lng
      ),
    }))
    .sort((a, b) => a.distance - b.distance);
}
