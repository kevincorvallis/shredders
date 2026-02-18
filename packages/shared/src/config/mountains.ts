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
  region: 'washington' | 'oregon' | 'idaho' | 'canada' | 'utah' | 'colorado' | 'california' | 'wyoming' | 'montana' | 'vermont' | 'newmexico';
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
  webcamPageUrl?: string;
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
  passType?: 'epic' | 'ikon' | 'independent';
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
    webcamPageUrl: 'https://www.mtbaker.us/snow-report/webcams',
    color: '#3b82f6',
    website: 'https://www.mtbaker.us',
    logo: '/logos/baker.png',
    status: { isOpen: true, percentOpen: 85, liftsOpen: '8/10', runsOpen: '70/82', message: 'Great conditions!' },
    passType: 'independent',
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
      // Stevens Pass webcams have moved to a dynamic system
      // Visit https://www.stevenspass.com/the-mountain/mountain-conditions/mountain-cams.aspx for live webcams
    ],
    webcamPageUrl: 'https://www.stevenspass.com/the-mountain/mountain-conditions/mountain-cams.aspx',
    roadWebcams: [
      {
        id: 'us2-skykomish',
        name: 'US-2 at Skykomish',
        url: 'https://images.wsdot.wa.gov/nw/002vc04558.jpg',
        highway: 'US-2',
        milepost: '45.6',
        agency: 'WSDOT',
      },
      {
        id: 'us2-oldfaithful',
        name: 'US-2 Old Faithful Avalanche Zone',
        url: 'https://images.wsdot.wa.gov/nc/002vc06190.jpg',
        highway: 'US-2',
        milepost: '61.9',
        agency: 'WSDOT',
      },
      {
        id: 'us2-bigwindy',
        name: 'US-2 at Big Windy',
        url: 'https://images.wsdot.wa.gov/nc/002vc06300.jpg',
        highway: 'US-2',
        milepost: '63',
        agency: 'WSDOT',
      },
      {
        id: 'us2-weststevensskilodge',
        name: 'US-2 West Stevens Pass - Ski Lodge',
        url: 'https://images.wsdot.wa.gov/nc/002vc06430.jpg',
        highway: 'US-2',
        milepost: '64.3',
        agency: 'WSDOT',
      },
      {
        id: 'us2-eaststevenssummit',
        name: 'US-2 East Stevens Pass Summit',
        url: 'https://images.wsdot.wa.gov/nc/002vc06458.jpg',
        highway: 'US-2',
        milepost: '64.6',
        agency: 'WSDOT',
      },
    ],
    color: '#10b981',
    website: 'https://www.stevenspass.com',
    logo: '/logos/stevens.png',
    status: { isOpen: true, percentOpen: 90, liftsOpen: '9/10', runsOpen: '55/61', message: 'Full operations' },
    passType: 'epic',
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
    noaa: { gridOffice: 'SEW', gridX: 145, gridY: 31 },
    webcams: [
      // Crystal uses dynamic Roundshot 360 webcams which don't have static image URLs
      // Users can view webcams at: https://www.crystalmountainresort.com/the-mountain/webcams
    ],
    webcamPageUrl: 'https://www.crystalmountainresort.com/the-mountain/webcams',
    color: '#8b5cf6',
    website: 'https://www.crystalmountainresort.com',
    logo: '/logos/crystal.png',
    status: { isOpen: true, percentOpen: 88, liftsOpen: '10/11', runsOpen: '50/57', message: 'Excellent skiing' },
    passType: 'ikon',
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
    webcamPageUrl: 'https://www.summitatsnoqualmie.com/webcams',
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
    passType: 'ikon',
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
    noaa: { gridOffice: 'SEW', gridX: 145, gridY: 17 },
    webcams: [
      // White Pass webcams have moved to a dynamic system
      // Visit https://skiwhitepass.com/mountain-cams for live cameras
    ],
    webcamPageUrl: 'https://skiwhitepass.com/mountain-cams',
    roadWebcams: [
      {
        id: 'us12-whitepasssummit',
        name: 'US-12 White Pass Summit',
        url: 'https://images.wsdot.wa.gov/sc/012vc15095.jpg',
        highway: 'US-12',
        milepost: '150.9',
        agency: 'WSDOT',
      },
    ],
    color: '#ec4899',
    website: 'https://skiwhitepass.com',
    logo: '/logos/whitepass.png',
    status: { isOpen: true, percentOpen: 75, liftsOpen: '4/6', runsOpen: '30/40', message: 'Good conditions' },
    passType: 'independent',
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
    webcamPageUrl: 'https://www.skihood.com/mountain-report/mountain-cams',
    color: '#06b6d4',
    website: 'https://www.skihood.com',
    logo: '/logos/meadows.png',
    status: { isOpen: true, percentOpen: 80, liftsOpen: '7/9', runsOpen: '65/81', message: 'Great skiing' },
    passType: 'independent',
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
    webcamPageUrl: 'https://www.timberlinelodge.com/webcams',
    color: '#14b8a6',
    website: 'https://www.timberlinelodge.com',
    logo: '/logos/timberline.png',
    status: { isOpen: true, percentOpen: 70, liftsOpen: '4/6', runsOpen: '40/57', message: 'Spring skiing' },
    passType: 'independent',
  },

  bachelor: {
    id: 'bachelor',
    name: 'Mt. Bachelor',
    shortName: 'Bachelor',
    location: { lat: 43.979, lng: -121.688 },
    elevation: { base: 5700, summit: 9065 },
    region: 'oregon',
    snotel: {
      stationId: '815:OR:SNTL',
      stationName: 'Three Creeks Meadow',
    },
    noaa: { gridOffice: 'PDT', gridX: 23, gridY: 40 },
    webcams: [
      // Mt. Bachelor uses 13 dynamic live feed webcams
      // Visit https://www.mtbachelor.com/the-mountain/webcams for live cameras
    ],
    webcamPageUrl: 'https://www.mtbachelor.com/the-mountain/webcams',
    color: '#f97316',
    website: 'https://www.mtbachelor.com',
    logo: '/logos/bachelor.png',
    status: { isOpen: true, percentOpen: 85, liftsOpen: '10/12', runsOpen: '62/73', message: 'Excellent conditions' },
    passType: 'ikon',
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
      stationId: '648:WA:SNTL',
      stationName: 'Mount Crag',
    },
    noaa: { gridOffice: 'OTX', gridX: 53, gridY: 107 },
    webcams: [
      // Mission Ridge webcams have moved to a dynamic system
      // Visit https://www.missionridge.com/mountain-report for live cameras
    ],
    webcamPageUrl: 'https://www.missionridge.com/mountain-report',
    color: '#dc2626',
    website: 'https://www.missionridge.com',
    logo: '/logos/missionridge.png',
    status: { isOpen: true, percentOpen: 80, liftsOpen: '4/5', runsOpen: '32/40', message: 'Good coverage' },
    passType: 'independent',
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
    webcamPageUrl: 'https://www.ski49n.com/index.php/mountain-info/webcams',
    color: '#7c3aed',
    website: 'https://www.ski49n.com',
    logo: '/logos/fortynine.png',
    status: { isOpen: true, percentOpen: 75, liftsOpen: '5/7', runsOpen: '28/38', message: 'Good skiing' },
    passType: 'independent',
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
    webcamPageUrl: 'https://www.schweitzer.com/mountain-info/webcam',
    color: '#0ea5e9',
    website: 'https://www.schweitzer.com',
    logo: '/logos/schweitzer.png',
    status: { isOpen: true, percentOpen: 85, liftsOpen: '8/10', runsOpen: '70/82', message: 'Great conditions' },
    passType: 'ikon',
  },

  lookout: {
    id: 'lookout',
    name: 'Lookout Pass',
    shortName: 'Lookout',
    location: { lat: 47.454, lng: -115.713 },
    elevation: { base: 4150, summit: 5650 },
    region: 'idaho',
    snotel: {
      stationId: '594:ID:SNTL',
      stationName: 'Lookout',
    },
    noaa: { gridOffice: 'OTX', gridX: 193, gridY: 71 },
    webcams: [
      // Lookout Pass webcams have moved to a dynamic system
      // Visit https://www.skilookout.com for current conditions
    ],
    webcamPageUrl: 'https://www.skilookout.com/the-mountain/web-cams',
    color: '#059669',
    website: 'https://www.skilookout.com',
    logo: '/logos/lookout.png',
    status: { isOpen: true, percentOpen: 65, liftsOpen: '3/4', runsOpen: '26/40', message: 'Limited terrain' },
    passType: 'independent',
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
    noaa: { gridOffice: 'MFR', gridX: 108, gridY: 61 },
    webcams: [
      // Mt. Ashland webcams have moved to a dynamic system
      // Visit https://www.mtashland.com for current conditions
    ],
    webcamPageUrl: 'https://www.mtashland.com/conditions',
    color: '#ea580c',
    website: 'https://www.mtashland.com',
    logo: '/logos/ashland.png',
    status: { isOpen: false, percentOpen: 0, liftsOpen: '0/4', runsOpen: '0/23', message: 'Closed for season' },
    passType: 'independent',
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
    noaa: { gridOffice: 'MFR', gridX: 145, gridY: 125 },
    webcams: [
      // Willamette Pass webcams have moved to a dynamic system
      // Visit https://www.willamettepass.ski/weather-conditions-webcams for live cameras
    ],
    webcamPageUrl: 'https://www.willamettepass.ski/weather-conditions-webcams',
    color: '#84cc16',
    website: 'https://www.willamettepass.com',
    logo: '/logos/willamette.png',
    status: { isOpen: true, percentOpen: 60, liftsOpen: '2/4', runsOpen: '18/30', message: 'Limited operations' },
    passType: 'independent',
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
    noaa: { gridOffice: 'PQR', gridX: 128, gridY: 47 },
    webcams: [
      // Hoodoo webcams have moved to a dynamic system
      // Visit https://www.skihoodoo.com for current conditions
    ],
    webcamPageUrl: 'https://www.skihoodoo.com/conditions',
    color: '#f472b6',
    website: 'https://www.skihoodoo.com',
    logo: '/logos/hoodoo.png',
    status: { isOpen: true, percentOpen: 70, liftsOpen: '3/5', runsOpen: '22/32', message: 'Good conditions' },
    passType: 'independent',
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
        id: 'roundhouse',
        name: 'Roundhouse Lodge, Whistler Mountain',
        url: 'https://ots-webcams.s3.amazonaws.com/493/19901/2025-12-20_2303/xl.jpg',
        refreshUrl: 'https://ots-webcams.s3.amazonaws.com/493/19901/2025-12-20_2303/xl.jpg',
      },
      {
        id: 'whistler-peak',
        name: 'Whistler Peak',
        url: 'https://ots-webcams.s3.amazonaws.com/493/25393/2025-12-20_2304/xl.jpg',
        refreshUrl: 'https://ots-webcams.s3.amazonaws.com/493/25393/2025-12-20_2304/xl.jpg',
      },
      {
        id: 'rendezvous',
        name: 'Rendezvous Lodge, Blackcomb Mountain',
        url: 'https://ots-webcams.s3.amazonaws.com/493/25394/2025-12-31_0004/xl.jpg',
        refreshUrl: 'https://ots-webcams.s3.amazonaws.com/493/25394/2025-12-31_0004/xl.jpg',
      },
      {
        id: '7th-heaven',
        name: '7th Heaven, Blackcomb Mountain',
        url: 'https://ots-webcams.s3.amazonaws.com/493/25203/2025-12-31_0004/xl.jpg',
        refreshUrl: 'https://ots-webcams.s3.amazonaws.com/493/25203/2025-12-31_0004/xl.jpg',
      },
      {
        id: 'creekside',
        name: 'Creekside Village',
        url: 'https://ots-webcams.s3.amazonaws.com/493/25399/2025-12-31_0004/xl.jpg',
        refreshUrl: 'https://ots-webcams.s3.amazonaws.com/493/25399/2025-12-31_0004/xl.jpg',
      },
      {
        id: 'blackcomb-base',
        name: 'Blackcomb Base, Upper Village',
        url: 'https://ots-webcams.s3.amazonaws.com/493/25397/2025-12-20_1804/xl.jpg',
        refreshUrl: 'https://ots-webcams.s3.amazonaws.com/493/25397/2025-12-20_1804/xl.jpg',
      },
    ],
    webcamPageUrl: 'https://www.whistlerblackcomb.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#0066b3',
    website: 'https://www.whistlerblackcomb.com',
    logo: '/logos/whistler.png',
    passType: 'epic',
  },

  sunvalley: {
    id: 'sunvalley',
    name: 'Sun Valley Resort',
    shortName: 'Sun Valley',
    location: { lat: 43.699, lng: -114.361 },
    elevation: { base: 5920, summit: 9150 },
    region: 'idaho',
    snotel: {
      stationId: '895:ID:SNTL',
      stationName: 'Chocolate Gulch',
    },
    noaa: { gridOffice: 'BOI', gridX: 110, gridY: 96 },
    webcams: [],
    webcamPageUrl: 'https://www.sunvalley.com/mountain-info/webcams',
    color: '#d946ef',
    website: 'https://www.sunvalley.com',
    logo: '/logos/sunvalley.png',
    passType: 'ikon',
  },

  revelstoke: {
    id: 'revelstoke',
    name: 'Revelstoke Mountain Resort',
    shortName: 'Revelstoke',
    location: { lat: 50.9, lng: -118.2 },
    elevation: { base: 1620, summit: 8058 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [],
    webcamPageUrl: 'https://www.revelstokemountainresort.com/conditions/webcams',
    color: '#fb923c',
    website: 'https://www.revelstokemountainresort.com',
    logo: '/logos/revelstoke.png',
    passType: 'ikon',
  },

  cypress: {
    id: 'cypress',
    name: 'Cypress Mountain',
    shortName: 'Cypress',
    location: { lat: 49.396, lng: -123.207 },
    elevation: { base: 2743, summit: 4751 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [],
    webcamPageUrl: 'https://www.cypressmountain.com/mountain-info/webcams',
    color: '#4ade80',
    website: 'https://www.cypressmountain.com',
    logo: '/logos/cypress.png',
    passType: 'ikon',
  },

  sunpeaks: {
    id: 'sunpeaks',
    name: 'Sun Peaks Resort',
    shortName: 'Sun Peaks',
    location: { lat: 50.885, lng: -119.885 },
    elevation: { base: 3930, summit: 7060 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [],
    webcamPageUrl: 'https://www.sunpeaksresort.com/ski-ride/snow-report/webcams',
    color: '#facc15',
    website: 'https://www.sunpeaksresort.com',
    logo: '/logos/sunpeaks.png',
    passType: 'ikon',
  },

  bigwhite: {
    id: 'bigwhite',
    name: 'Big White Ski Resort',
    shortName: 'Big White',
    location: { lat: 49.7219, lng: -118.9289 },
    elevation: { base: 5758, summit: 7608 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [],
    webcamPageUrl: 'https://www.bigwhite.com/mountain/webcams',
    color: '#c084fc',
    website: 'https://www.bigwhite.com',
    logo: '/logos/bigwhite.png',
    passType: 'independent',
  },

  brundage: {
    id: 'brundage',
    name: 'Brundage Mountain',
    shortName: 'Brundage',
    location: { lat: 45.0, lng: -116.17 },
    elevation: { base: 6000, summit: 7640 },
    region: 'idaho',
    snotel: {
      stationId: '370:ID:SNTL',
      stationName: 'Brundage Reservoir',
    },
    noaa: { gridOffice: 'BOI', gridX: 145, gridY: 149 },
    webcams: [],
    webcamPageUrl: 'https://www.brundage.com/the-mountain/webcams',
    color: '#fb7185',
    website: 'https://www.brundage.com',
    logo: '/logos/brundage.png',
    passType: 'independent',
  },

  anthonylakes: {
    id: 'anthonylakes',
    name: 'Anthony Lakes Mountain Resort',
    shortName: 'Anthony Lakes',
    location: { lat: 44.96, lng: -118.23 },
    elevation: { base: 7100, summit: 8000 },
    region: 'oregon',
    snotel: {
      stationId: '361:OR:SNTL',
      stationName: 'Bourne',
    },
    noaa: { gridOffice: 'PDT', gridX: 39, gridY: 122 },
    webcams: [],
    webcamPageUrl: 'https://anthonylakes.com/snow-report',
    color: '#38bdf8',
    website: 'https://anthonylakes.com',
    logo: '/logos/anthonylakes.png',
    passType: 'independent',
  },

  red: {
    id: 'red',
    name: 'RED Mountain Resort',
    shortName: 'RED',
    location: { lat: 50.87, lng: -117.75 },
    elevation: { base: 3900, summit: 6807 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [],
    webcamPageUrl: 'https://www.redresort.com/conditions/webcams',
    color: '#fbbf24',
    website: 'https://www.redresort.com',
    logo: '/logos/red.png',
    passType: 'ikon',
  },

  panorama: {
    id: 'panorama',
    name: 'Panorama Mountain Resort',
    shortName: 'Panorama',
    location: { lat: 50.4603, lng: -116.2403 },
    elevation: { base: 3773, summit: 8038 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [],
    webcamPageUrl: 'https://www.panoramaresort.com/conditions/webcams',
    color: '#22d3ee',
    website: 'https://www.panoramaresort.com',
    logo: '/logos/panorama.png',
    passType: 'ikon',
  },

  silverstar: {
    id: 'silverstar',
    name: 'SilverStar Mountain Resort',
    shortName: 'SilverStar',
    location: { lat: 50.36, lng: -119.06 },
    elevation: { base: 5279, summit: 6283 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [],
    webcamPageUrl: 'https://www.skisilverstar.com/conditions/webcams',
    color: '#a78bfa',
    website: 'https://www.skisilverstar.com',
    logo: '/logos/silverstar.png',
    passType: 'independent',
  },

  apex: {
    id: 'apex',
    name: 'Apex Mountain Resort',
    shortName: 'Apex',
    location: { lat: 49.3907, lng: -119.9039 },
    elevation: { base: 5197, summit: 7198 },
    region: 'canada',
    // No SNOTEL data (Canada)
    // No NOAA grid (using Open-Meteo for Canadian weather)
    webcams: [],
    webcamPageUrl: 'https://www.apexresort.com/mountain-info/webcams',
    color: '#34d399',
    website: 'https://www.apexresort.com',
    logo: '/logos/apex.png',
    passType: 'independent',
  },

  // Utah
  parkcity: {
    id: 'parkcity',
    name: 'Park City Mountain',
    shortName: 'Park City',
    location: { lat: 40.6508, lng: -111.5075 },
    elevation: { base: 6800, summit: 10026 },
    region: 'utah',
    snotel: {
      stationId: '814:UT:SNTL',
      stationName: 'Thaynes Canyon',
    },
    noaa: { gridOffice: 'SLC', gridX: 113, gridY: 169 },
    webcams: [],
    webcamPageUrl: 'https://www.parkcitymountain.com/the-mountain/webcams.aspx',
    color: '#2563eb',
    website: 'https://www.parkcitymountain.com',
    logo: '/logos/parkcity.png',
    passType: 'epic',
  },

  snowbird: {
    id: 'snowbird',
    name: 'Snowbird',
    shortName: 'Snowbird',
    location: { lat: 40.5756, lng: -111.6561 },
    elevation: { base: 7760, summit: 11000 },
    region: 'utah',
    snotel: {
      stationId: '766:UT:SNTL',
      stationName: 'Snowbird',
    },
    noaa: { gridOffice: 'SLC', gridX: 107, gridY: 166 },
    webcams: [],
    webcamPageUrl: 'https://www.snowbird.com/mountain-report/',
    color: '#0891b2',
    website: 'https://www.snowbird.com',
    logo: '/logos/snowbird.png',
    passType: 'ikon',
  },

  alta: {
    id: 'alta',
    name: 'Alta Ski Area',
    shortName: 'Alta',
    location: { lat: 40.5808, lng: -111.6372 },
    elevation: { base: 8530, summit: 11068 },
    region: 'utah',
    snotel: {
      stationId: '766:UT:SNTL',
      stationName: 'Snowbird',
    },
    noaa: { gridOffice: 'SLC', gridX: 108, gridY: 166 },
    webcams: [],
    webcamPageUrl: 'https://www.alta.com/conditions',
    color: '#1d4ed8',
    website: 'https://www.alta.com',
    logo: '/logos/alta.png',
    passType: 'ikon',
  },

  brighton: {
    id: 'brighton',
    name: 'Brighton Resort',
    shortName: 'Brighton',
    location: { lat: 40.5987, lng: -111.5833 },
    elevation: { base: 8755, summit: 10500 },
    region: 'utah',
    snotel: {
      stationId: '366:UT:SNTL',
      stationName: 'Brighton',
    },
    noaa: { gridOffice: 'SLC', gridX: 110, gridY: 167 },
    webcams: [],
    webcamPageUrl: 'https://brightonresort.com/conditions',
    color: '#16a34a',
    website: 'https://brightonresort.com',
    logo: '/logos/brighton.png',
    passType: 'ikon',
  },

  solitude: {
    id: 'solitude',
    name: 'Solitude Mountain Resort',
    shortName: 'Solitude',
    location: { lat: 40.6151, lng: -111.5889 },
    elevation: { base: 7994, summit: 10488 },
    region: 'utah',
    snotel: {
      stationId: '366:UT:SNTL',
      stationName: 'Brighton',
    },
    noaa: { gridOffice: 'SLC', gridX: 110, gridY: 168 },
    webcams: [],
    webcamPageUrl: 'https://www.solitudemountain.com/conditions',
    color: '#7c3aed',
    website: 'https://www.solitudemountain.com',
    logo: '/logos/solitude.png',
    passType: 'ikon',
  },

  deervalley: {
    id: 'deervalley',
    name: 'Deer Valley Resort',
    shortName: 'Deer Valley',
    location: { lat: 40.6151, lng: -111.4870 },
    elevation: { base: 6530, summit: 9570 },
    region: 'utah',
    snotel: {
      stationId: '814:UT:SNTL',
      stationName: 'Thaynes Canyon',
    },
    noaa: { gridOffice: 'SLC', gridX: 113, gridY: 167 },
    webcams: [],
    webcamPageUrl: 'https://www.deervalley.com/explore-the-mountain/webcams',
    color: '#b45309',
    website: 'https://www.deervalley.com',
    logo: '/logos/deervalley.png',
    passType: 'ikon',
  },

  snowbasin: {
    id: 'snowbasin',
    name: 'Snowbasin Resort',
    shortName: 'Snowbasin',
    location: { lat: 41.2160, lng: -111.8570 },
    elevation: { base: 6391, summit: 9350 },
    region: 'utah',
    snotel: {
      stationId: '332:UT:SNTL',
      stationName: 'Ben Lomond Peak',
    },
    noaa: { gridOffice: 'SLC', gridX: 104, gridY: 196 },
    webcams: [],
    webcamPageUrl: 'https://www.snowbasin.com/mountain-report',
    color: '#be123c',
    website: 'https://www.snowbasin.com',
    logo: '/logos/snowbasin.png',
    passType: 'independent',
  },

  powdermountain: {
    id: 'powdermountain',
    name: 'Powder Mountain',
    shortName: 'Powder Mtn',
    location: { lat: 41.3800, lng: -111.7803 },
    elevation: { base: 6900, summit: 9422 },
    region: 'utah',
    snotel: {
      stationId: '1300:UT:SNTL',
      stationName: 'Powder Mountain',
    },
    noaa: { gridOffice: 'SLC', gridX: 108, gridY: 203 },
    webcams: [],
    webcamPageUrl: 'https://www.powdermountain.com/mountain-report',
    color: '#0d9488',
    website: 'https://www.powdermountain.com',
    logo: '/logos/powdermountain.png',
    passType: 'independent',
  },

  // Colorado (Batch 9-10)
  vail: {
    id: 'vail',
    name: 'Vail Mountain',
    shortName: 'Vail',
    location: { lat: 39.6403, lng: -106.3742 },
    elevation: { base: 8120, summit: 11570 },
    region: 'colorado',
    snotel: { stationId: '842:CO:SNTL', stationName: 'Vail Mountain' },
    noaa: { gridOffice: 'GJT', gridX: 174, gridY: 121 },
    webcams: [],
    webcamPageUrl: 'https://www.vail.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#1e40af',
    website: 'https://www.vail.com',
    logo: '/logos/vail.png',
    passType: 'epic',
  },

  breckenridge: {
    id: 'breckenridge',
    name: 'Breckenridge Ski Resort',
    shortName: 'Breckenridge',
    location: { lat: 39.4817, lng: -106.0678 },
    elevation: { base: 9600, summit: 12998 },
    region: 'colorado',
    snotel: { stationId: '531:CO:SNTL', stationName: 'Hoosier Pass' },
    noaa: { gridOffice: 'BOU', gridX: 25, gridY: 53 },
    webcams: [],
    webcamPageUrl: 'https://www.breckenridge.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#0369a1',
    website: 'https://www.breckenridge.com',
    logo: '/logos/breckenridge.png',
    passType: 'epic',
  },

  beavercreek: {
    id: 'beavercreek',
    name: 'Beaver Creek Resort',
    shortName: 'Beaver Creek',
    location: { lat: 39.6042, lng: -106.5165 },
    elevation: { base: 8100, summit: 11440 },
    region: 'colorado',
    snotel: { stationId: '1041:CO:SNTL', stationName: 'Beaver Ck Village' },
    noaa: { gridOffice: 'GJT', gridX: 168, gridY: 120 },
    webcams: [],
    webcamPageUrl: 'https://www.beavercreek.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#b91c1c',
    website: 'https://www.beavercreek.com',
    logo: '/logos/beavercreek.png',
    passType: 'epic',
  },

  keystone: {
    id: 'keystone',
    name: 'Keystone Resort',
    shortName: 'Keystone',
    location: { lat: 39.6086, lng: -105.9428 },
    elevation: { base: 9280, summit: 12408 },
    region: 'colorado',
    snotel: { stationId: '505:CO:SNTL', stationName: 'Grizzly Peak' },
    noaa: { gridOffice: 'BOU', gridX: 29, gridY: 58 },
    webcams: [],
    webcamPageUrl: 'https://www.keystoneresort.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#047857',
    website: 'https://www.keystoneresort.com',
    logo: '/logos/keystone.png',
    passType: 'epic',
  },

  crestedbutte: {
    id: 'crestedbutte',
    name: 'Crested Butte Mountain Resort',
    shortName: 'Crested Butte',
    location: { lat: 38.8972, lng: -106.9656 },
    elevation: { base: 9375, summit: 12162 },
    region: 'colorado',
    snotel: { stationId: '380:CO:SNTL', stationName: 'Butte' },
    noaa: { gridOffice: 'GJT', gridX: 150, gridY: 89 },
    webcams: [],
    webcamPageUrl: 'https://www.skicb.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#7e22ce',
    website: 'https://www.skicb.com',
    logo: '/logos/crestedbutte.png',
    passType: 'epic',
  },

  aspen: {
    id: 'aspen',
    name: 'Aspen Snowmass',
    shortName: 'Aspen',
    location: { lat: 39.1913, lng: -106.8231 },
    elevation: { base: 7945, summit: 12510 },
    region: 'colorado',
    snotel: { stationId: '542:CO:SNTL', stationName: 'Independence Pass' },
    noaa: { gridOffice: 'GJT', gridX: 156, gridY: 102 },
    webcams: [],
    webcamPageUrl: 'https://www.aspensnowmass.com/four-mountains/mountain-conditions/webcams',
    color: '#ca8a04',
    website: 'https://www.aspensnowmass.com',
    logo: '/logos/aspen.png',
    passType: 'ikon',
  },

  steamboat: {
    id: 'steamboat',
    name: 'Steamboat Resort',
    shortName: 'Steamboat',
    location: { lat: 40.4572, lng: -106.8040 },
    elevation: { base: 6900, summit: 10568 },
    region: 'colorado',
    snotel: { stationId: '457:CO:SNTL', stationName: 'Dry Lake' },
    noaa: { gridOffice: 'GJT', gridX: 162, gridY: 159 },
    webcams: [],
    webcamPageUrl: 'https://www.steamboat.com/the-mountain/mountain-report/webcams',
    color: '#0f766e',
    website: 'https://www.steamboat.com',
    logo: '/logos/steamboat.png',
    passType: 'ikon',
  },

  winterpark: {
    id: 'winterpark',
    name: 'Winter Park Resort',
    shortName: 'Winter Park',
    location: { lat: 39.8869, lng: -105.7631 },
    elevation: { base: 9000, summit: 12060 },
    region: 'colorado',
    snotel: { stationId: '335:CO:SNTL', stationName: 'Berthoud Summit' },
    noaa: { gridOffice: 'BOU', gridX: 37, gridY: 70 },
    webcams: [],
    webcamPageUrl: 'https://www.winterparkresort.com/the-mountain/mountain-report/webcams',
    color: '#4338ca',
    website: 'https://www.winterparkresort.com',
    logo: '/logos/winterpark.png',
    passType: 'ikon',
  },

  // California (Batch 10-11)
  heavenly: {
    id: 'heavenly',
    name: 'Heavenly Mountain Resort',
    shortName: 'Heavenly',
    location: { lat: 38.9353, lng: -119.9400 },
    elevation: { base: 6540, summit: 10067 },
    region: 'california',
    snotel: { stationId: '518:CA:SNTL', stationName: 'Heavenly Valley' },
    noaa: { gridOffice: 'REV', gridX: 36, gridY: 81 },
    webcams: [],
    webcamPageUrl: 'https://www.skiheavenly.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#0284c7',
    website: 'https://www.skiheavenly.com',
    logo: '/logos/heavenly.png',
    passType: 'epic',
  },

  northstar: {
    id: 'northstar',
    name: 'Northstar California',
    shortName: 'Northstar',
    location: { lat: 39.2742, lng: -120.1219 },
    elevation: { base: 6330, summit: 8610 },
    region: 'california',
    snotel: { stationId: '784:CA:SNTL', stationName: 'Palisades Tahoe' },
    noaa: { gridOffice: 'REV', gridX: 32, gridY: 97 },
    webcams: [],
    webcamPageUrl: 'https://www.northstarcalifornia.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#15803d',
    website: 'https://www.northstarcalifornia.com',
    logo: '/logos/northstar.png',
    passType: 'epic',
  },

  kirkwood: {
    id: 'kirkwood',
    name: 'Kirkwood Mountain Resort',
    shortName: 'Kirkwood',
    location: { lat: 38.6844, lng: -120.0655 },
    elevation: { base: 7800, summit: 9800 },
    region: 'california',
    snotel: { stationId: '1067:CA:SNTL', stationName: 'Carson Pass' },
    noaa: { gridOffice: 'STO', gridX: 91, gridY: 63 },
    webcams: [],
    webcamPageUrl: 'https://www.kirkwood.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#a16207',
    website: 'https://www.kirkwood.com',
    logo: '/logos/kirkwood.png',
    passType: 'epic',
  },

  palisades: {
    id: 'palisades',
    name: 'Palisades Tahoe',
    shortName: 'Palisades',
    location: { lat: 39.1969, lng: -120.2356 },
    elevation: { base: 6200, summit: 9050 },
    region: 'california',
    snotel: { stationId: '784:CA:SNTL', stationName: 'Palisades Tahoe' },
    noaa: { gridOffice: 'REV', gridX: 28, gridY: 94 },
    webcams: [],
    webcamPageUrl: 'https://www.palisadestahoe.com/mountain-information/conditions-and-cams',
    color: '#c2410c',
    website: 'https://www.palisadestahoe.com',
    logo: '/logos/palisades.png',
    passType: 'ikon',
  },

  mammoth: {
    id: 'mammoth',
    name: 'Mammoth Mountain',
    shortName: 'Mammoth',
    location: { lat: 37.6308, lng: -119.0326 },
    elevation: { base: 7953, summit: 11053 },
    region: 'california',
    snotel: { stationId: '846:CA:SNTL', stationName: 'Virginia Lakes Ridge' },
    noaa: { gridOffice: 'REV', gridX: 57, gridY: 17 },
    webcams: [],
    webcamPageUrl: 'https://www.mammothmountain.com/mountain-information/webcams',
    color: '#e11d48',
    website: 'https://www.mammothmountain.com',
    logo: '/logos/mammoth.png',
    passType: 'ikon',
  },

  // Wyoming (Batch 11)
  jacksonhole: {
    id: 'jacksonhole',
    name: 'Jackson Hole Mountain Resort',
    shortName: 'Jackson Hole',
    location: { lat: 43.5875, lng: -110.8277 },
    elevation: { base: 6311, summit: 10450 },
    region: 'wyoming',
    snotel: { stationId: '689:WY:SNTL', stationName: 'Phillips Bench' },
    noaa: { gridOffice: 'RIW', gridX: 40, gridY: 144 },
    webcams: [],
    webcamPageUrl: 'https://www.jacksonhole.com/mountain-cams',
    color: '#92400e',
    website: 'https://www.jacksonhole.com',
    logo: '/logos/jacksonhole.png',
    passType: 'ikon',
  },

  // Montana (Batch 11)
  bigsky: {
    id: 'bigsky',
    name: 'Big Sky Resort',
    shortName: 'Big Sky',
    location: { lat: 45.2860, lng: -111.4016 },
    elevation: { base: 7500, summit: 11166 },
    region: 'montana',
    snotel: { stationId: '590:MT:SNTL', stationName: 'Lone Mountain' },
    noaa: { gridOffice: 'TFX', gridX: 82, gridY: 41 },
    webcams: [],
    webcamPageUrl: 'https://www.bigskyresort.com/the-mountain/mountain-report/webcams',
    color: '#6d28d9',
    website: 'https://www.bigskyresort.com',
    logo: '/logos/bigsky.png',
    passType: 'ikon',
  },

  // Vermont (Batch 12)
  stowe: {
    id: 'stowe',
    name: 'Stowe Mountain Resort',
    shortName: 'Stowe',
    location: { lat: 44.5253, lng: -72.7814 },
    elevation: { base: 1559, summit: 4395 },
    region: 'vermont',
    // No SNOTEL in Vermont
    noaa: { gridOffice: 'BTV', gridX: 102, gridY: 61 },
    webcams: [],
    webcamPageUrl: 'https://www.stowe.com/the-mountain/mountain-conditions/webcams.aspx',
    color: '#166534',
    website: 'https://www.stowe.com',
    logo: '/logos/stowe.png',
    passType: 'epic',
  },

  killington: {
    id: 'killington',
    name: 'Killington Resort',
    shortName: 'Killington',
    location: { lat: 43.6045, lng: -72.8201 },
    elevation: { base: 1165, summit: 4241 },
    region: 'vermont',
    // No SNOTEL in Vermont
    noaa: { gridOffice: 'BTV', gridX: 108, gridY: 19 },
    webcams: [],
    webcamPageUrl: 'https://www.killington.com/mountain-info/webcams',
    color: '#065f46',
    website: 'https://www.killington.com',
    logo: '/logos/killington.png',
    passType: 'ikon',
  },

  // New Mexico (Batch 12)
  taos: {
    id: 'taos',
    name: 'Taos Ski Valley',
    shortName: 'Taos',
    location: { lat: 36.5953, lng: -105.4514 },
    elevation: { base: 9207, summit: 12481 },
    region: 'newmexico',
    snotel: { stationId: '1168:NM:SNTL', stationName: 'Taos Powderhorn' },
    noaa: { gridOffice: 'ABQ', gridX: 147, gridY: 185 },
    webcams: [],
    webcamPageUrl: 'https://www.skitaos.com/mountain-info/webcams',
    color: '#9f1239',
    website: 'https://www.skitaos.com',
    logo: '/logos/taos.png',
    passType: 'ikon',
  },
};

export function getMountain(id: string): MountainConfig | undefined {
  return mountains[id];
}

export function getAllMountains(): MountainConfig[] {
  return Object.values(mountains);
}

export function getMountainsByRegion(region: 'washington' | 'oregon' | 'idaho' | 'canada' | 'utah' | 'colorado' | 'california' | 'wyoming' | 'montana' | 'vermont' | 'newmexico'): MountainConfig[] {
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
