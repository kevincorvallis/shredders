export interface MountainStatus {
  isOpen: boolean;
  percentOpen?: number;
  liftsOpen?: string;
  runsOpen?: string;
  message?: string;
  lastUpdated?: string;
}

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
  region: 'washington' | 'oregon' | 'idaho' | 'canada';
  snotel?: {
    stationId: string;
    stationName: string;
  };
  noaa?: {
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
  roadWebcams?: {
    id: string;
    name: string;
    url: string;
    highway: string;
    milepost?: string;
    agency: 'WSDOT' | 'ODOT' | 'ITD';
  }[];
  color: string;
  website: string;
  logo?: string;
  status?: MountainStatus;
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
      // Mt. Baker's official webcams have moved to a dynamic system
      // Visit https://www.mtbaker.us/snow-report/webcams for live webcams
      {
        id: 'nwcaa',
        name: 'Mt. Baker View (NWCAA)',
        url: 'https://video-monitoring.com/parks/mtbaker/static/s1latest.jpg',
        refreshUrl: 'https://video-monitoring.com/parks/mtbaker/',
      },
    ],
    color: '#3b82f6',
    website: 'https://www.mtbaker.us',
    logo: '/logos/baker.png',
    status: { isOpen: true, percentOpen: 85, liftsOpen: '8/10', runsOpen: '70/82', message: 'Great conditions!' },
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
    logo: '/logos/stevens.png',
    status: { isOpen: true, percentOpen: 90, liftsOpen: '9/10', runsOpen: '55/61', message: 'Full operations' },
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
      // Crystal uses dynamic Roundshot 360 webcams which don't have static image URLs
      // Users can view webcams at: https://www.crystalmountainresort.com/the-mountain/webcams
    ],
    color: '#8b5cf6',
    website: 'https://www.crystalmountainresort.com',
    logo: '/logos/crystal.png',
    status: { isOpen: true, percentOpen: 88, liftsOpen: '10/11', runsOpen: '50/57', message: 'Excellent skiing' },
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
      // Snoqualmie webcams have moved to a dynamic system
      // Visit https://www.summitatsnoqualmie.com/webcams for live cameras
    ],
    roadWebcams: [
      {
        id: 'i90-northbend',
        name: 'I-90 at North Bend',
        url: 'https://images.wsdot.wa.gov/sc/090VC03326.jpg',
        highway: 'I-90',
        milepost: '33',
        agency: 'WSDOT',
      },
      {
        id: 'i90-tinkham',
        name: 'I-90 at Tinkham Road',
        url: 'https://images.wsdot.wa.gov/sc/090VC04526.jpg',
        highway: 'I-90',
        milepost: '45.2',
        agency: 'WSDOT',
      },
      {
        id: 'i90-dennycreek',
        name: 'I-90 at Denny Creek',
        url: 'https://images.wsdot.wa.gov/sc/090VC04680.jpg',
        highway: 'I-90',
        milepost: '47.8',
        agency: 'WSDOT',
      },
      {
        id: 'i90-asahelcurtis',
        name: 'I-90 at Asahel Curtis',
        url: 'https://images.wsdot.wa.gov/sc/090VC04810.jpg',
        highway: 'I-90',
        milepost: '48.1',
        agency: 'WSDOT',
      },
      {
        id: 'i90-rockdale',
        name: 'I-90 at Rockdale',
        url: 'https://images.wsdot.wa.gov/sc/090VC04938.jpg',
        highway: 'I-90',
        milepost: '49',
        agency: 'WSDOT',
      },
      {
        id: 'i90-franklinfalls',
        name: 'I-90 at Franklin Falls',
        url: 'https://images.wsdot.wa.gov/sc/090VC05130.jpg',
        highway: 'I-90',
        milepost: '51.3',
        agency: 'WSDOT',
      },
      {
        id: 'i90-summit',
        name: 'I-90 at Snoqualmie Summit',
        url: 'https://images.wsdot.wa.gov/sc/090VC05200.jpg',
        highway: 'I-90',
        milepost: '52',
        agency: 'WSDOT',
      },
      {
        id: 'i90-eastsummit',
        name: 'I-90 East of Snoqualmie Summit',
        url: 'https://images.wsdot.wa.gov/sc/090VC05347.jpg',
        highway: 'I-90',
        milepost: '53.5',
        agency: 'WSDOT',
      },
      {
        id: 'i90-hyak',
        name: 'I-90 at Hyak',
        url: 'https://images.wsdot.wa.gov/sc/090VC05517.jpg',
        highway: 'I-90',
        milepost: '55.2',
        agency: 'WSDOT',
      },
      {
        id: 'i90-keechelusshed',
        name: 'I-90 at Old Keechelus Snow Shed',
        url: 'https://images.wsdot.wa.gov/sc/090VC05771.jpg',
        highway: 'I-90',
        milepost: '57.7',
        agency: 'WSDOT',
      },
      {
        id: 'i90-keechelusdam',
        name: 'I-90 at Lake Keechelus Dam',
        url: 'https://images.wsdot.wa.gov/sc/090VC06050.jpg',
        highway: 'I-90',
        milepost: '60.5',
        agency: 'WSDOT',
      },
      {
        id: 'i90-pricecreek',
        name: 'I-90 at Price Creek Animal Overcrossing',
        url: 'https://images.wsdot.wa.gov/sc/090VC06132.jpg',
        highway: 'I-90',
        milepost: '61.3',
        agency: 'WSDOT',
      },
      {
        id: 'i90-stampede',
        name: 'I-90 at Stampede Pass Exit',
        url: 'https://images.wsdot.wa.gov/sc/090VC06173.jpg',
        highway: 'I-90',
        milepost: '61.7',
        agency: 'WSDOT',
      },
      {
        id: 'i90-lakeeaston',
        name: 'I-90 at Lake Easton',
        url: 'https://images.wsdot.wa.gov/SC/090vc06978.jpg',
        highway: 'I-90',
        milepost: '69.78',
        agency: 'WSDOT',
      },
      {
        id: 'i90-easton',
        name: 'I-90 at Easton',
        url: 'https://images.wsdot.wa.gov/sc/090VC07060.jpg',
        highway: 'I-90',
        milepost: '70.6',
        agency: 'WSDOT',
      },
    ],
    color: '#f59e0b',
    website: 'https://www.summitatsnoqualmie.com',
    logo: '/logos/snoqualmie.png',
    status: { isOpen: true, percentOpen: 95, liftsOpen: '20/22', runsOpen: '64/67', message: 'All areas open' },
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
      // White Pass webcams have moved to a dynamic system
      // Visit https://skiwhitepass.com/mountain-cams for live cameras
    ],
    color: '#ec4899',
    website: 'https://skiwhitepass.com',
    logo: '/logos/whitepass.png',
    status: { isOpen: true, percentOpen: 75, liftsOpen: '4/6', runsOpen: '30/40', message: 'Good conditions' },
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
      // Mt. Hood Meadows webcams have moved to a dynamic system
      // Visit https://www.skihood.com/mountain-report/mountain-cams for live cameras
    ],
    color: '#06b6d4',
    website: 'https://www.skihood.com',
    logo: '/logos/meadows.png',
    status: { isOpen: true, percentOpen: 80, liftsOpen: '7/9', runsOpen: '65/81', message: 'Great skiing' },
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
      // Timberline webcams have moved to a dynamic system
      // Visit https://timberlinelodge.com/webcams for live cameras
    ],
    color: '#14b8a6',
    website: 'https://www.timberlinelodge.com',
    logo: '/logos/timberline.png',
    status: { isOpen: true, percentOpen: 70, liftsOpen: '4/6', runsOpen: '40/57', message: 'Spring skiing' },
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
      // Mt. Bachelor uses 13 dynamic live feed webcams
      // Visit https://www.mtbachelor.com/the-mountain/webcams for live cameras
    ],
    color: '#f97316',
    website: 'https://www.mtbachelor.com',
    logo: '/logos/bachelor.png',
    status: { isOpen: true, percentOpen: 85, liftsOpen: '10/12', runsOpen: '62/73', message: 'Excellent conditions' },
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
      // Mission Ridge webcams have moved to a dynamic system
      // Visit https://www.missionridge.com/mountain-report for live cameras
    ],
    color: '#dc2626',
    website: 'https://www.missionridge.com',
    logo: '/logos/missionridge.png',
    status: { isOpen: true, percentOpen: 80, liftsOpen: '4/5', runsOpen: '32/40', message: 'Good coverage' },
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
      // 49 Degrees North webcams have moved to a dynamic system
      // Visit https://www.ski49n.com/index.php/mountain-info/webcams for live cameras
    ],
    color: '#7c3aed',
    website: 'https://www.ski49n.com',
    logo: '/logos/fortynine.png',
    status: { isOpen: true, percentOpen: 75, liftsOpen: '5/7', runsOpen: '28/38', message: 'Good skiing' },
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
      // Schweitzer webcams have moved to a dynamic system
      // Visit https://www.schweitzer.com/mountain-info/webcam for live cameras
    ],
    color: '#0ea5e9',
    website: 'https://www.schweitzer.com',
    logo: '/logos/schweitzer.png',
    status: { isOpen: true, percentOpen: 85, liftsOpen: '8/10', runsOpen: '70/82', message: 'Great conditions' },
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
      // Lookout Pass webcams have moved to a dynamic system
      // Visit https://www.skilookout.com for current conditions
    ],
    color: '#059669',
    website: 'https://www.skilookout.com',
    logo: '/logos/lookout.png',
    status: { isOpen: true, percentOpen: 65, liftsOpen: '3/4', runsOpen: '26/40', message: 'Limited terrain' },
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
      // Mt. Ashland webcams have moved to a dynamic system
      // Visit https://www.mtashland.com for current conditions
    ],
    color: '#ea580c',
    website: 'https://www.mtashland.com',
    logo: '/logos/ashland.png',
    status: { isOpen: false, percentOpen: 0, liftsOpen: '0/4', runsOpen: '0/23', message: 'Closed for season' },
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
      // Willamette Pass webcams have moved to a dynamic system
      // Visit https://www.willamettepass.ski/weather-conditions-webcams for live cameras
    ],
    color: '#84cc16',
    website: 'https://www.willamettepass.com',
    logo: '/logos/willamette.png',
    status: { isOpen: true, percentOpen: 60, liftsOpen: '2/4', runsOpen: '18/30', message: 'Limited operations' },
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
      // Hoodoo webcams have moved to a dynamic system
      // Visit https://www.skihoodoo.com for current conditions
    ],
    color: '#f472b6',
    website: 'https://www.skihoodoo.com',
    logo: '/logos/hoodoo.png',
    status: { isOpen: true, percentOpen: 70, liftsOpen: '3/5', runsOpen: '22/32', message: 'Good conditions' },
  },

  whistler: {
    id: 'whistler',
    name: 'Whistler Blackcomb',
    shortName: 'Whistler',
    location: { lat: 50.115, lng: -122.95 },
    elevation: { base: 2214, summit: 7494 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [
      {
        id: 'village',
        name: 'Whistler Village',
        url: 'https://www.whistlerblackcomb.com/the-mountain/mountain-conditions/mountain-cams.aspx',
        refreshUrl: 'https://www.whistlerblackcomb.com/the-mountain/mountain-conditions/mountain-cams.aspx',
      },
    ],
    color: '#0066b3',
    website: 'https://www.whistlerblackcomb.com',
    logo: '/logos/whistler.png',
    status: { isOpen: true, percentOpen: 90, liftsOpen: '35/37', runsOpen: '190/200', message: 'Excellent conditions!' },
  },
};

export function getMountain(id: string): MountainConfig | undefined {
  return mountains[id];
}

export function getAllMountains(): MountainConfig[] {
  return Object.values(mountains);
}

export function getMountainsByRegion(region: 'washington' | 'oregon' | 'idaho' | 'canada'): MountainConfig[] {
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
