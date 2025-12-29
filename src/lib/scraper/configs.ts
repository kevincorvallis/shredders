import type { ScraperConfig } from './types';

/**
 * Scraper configurations for all PNW mountains
 * Inspired by Liftie's resort descriptor pattern
 *
 * Each config specifies:
 * - URL for users to visit
 * - Data URL for scraping (if different)
 * - Scraping method (html/api/dynamic)
 * - CSS selectors or API transformation logic
 */

export const scraperConfigs: Record<string, ScraperConfig> = {
  // Washington - Cascades
  baker: {
    id: 'baker',
    name: 'Mt. Baker',
    url: 'https://www.mtbaker.us',
    dataUrl: 'https://www.mtbaker.us/snow-report/',
    type: 'html',
    enabled: true,
    selectors: {
      // Mt. Baker uses status classes on lift table cells
      liftsOpen: '.table-lifts .status-icon.status-open',  // Count all open lifts
      status: '.title.h3',  // "OPEN FOR THE SEASON" text
      message: '.conditions-conditions_summary p',  // Daily conditions message
    },
  },

  stevens: {
    id: 'stevens',
    name: 'Stevens Pass',
    url: 'https://www.stevenspass.com',
    dataUrl: 'https://www.stevenspass.com/the-mountain/mountain-conditions.aspx',
    type: 'dynamic', // Uses JavaScript to load data
    enabled: false, // Temporarily disabled for testing (timeout issue)
    selectors: {
      liftsOpen: '.header__weather__lifts_open',
      runsOpen: '.header__weather__runs_open',
      percentOpen: '.header__weather__percent_open',
      acresOpen: '.header__weather__acres_open',
      status: '.header__weather__status',
    },
  },

  crystal: {
    id: 'crystal',
    name: 'Crystal Mountain',
    url: 'https://www.crystalmountainresort.com',
    dataUrl: 'https://www.crystalmountainresort.com/the-mountain/mountain-report/',
    type: 'dynamic',  // Requires Puppeteer - blocked by Incapsula bot protection
    enabled: false,
    selectors: {
      liftsOpen: '.lifts-open',
      runsOpen: '.runs-open',
      percentOpen: '.percent-open',
      status: '.resort-status',
    },
  },

  snoqualmie: {
    id: 'snoqualmie',
    name: 'Summit at Snoqualmie',
    url: 'https://www.summitatsnoqualmie.com',
    dataUrl: 'https://www.summitatsnoqualmie.com/mountain-report',
    type: 'dynamic',  // Uses Next.js client-side rendering - requires Puppeteer
    enabled: false,
    selectors: {
      liftsOpen: '.lift-count',
      runsOpen: '.run-count',
      status: '.operating-status',
    },
  },

  whitepass: {
    id: 'whitepass',
    name: 'White Pass',
    url: 'https://skiwhitepass.com',
    dataUrl: 'https://skiwhitepass.com/mountain-report/',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lifts-operating',
      runsOpen: '.runs-open',
      status: '.mountain-status',
    },
  },

  // Oregon
  meadows: {
    id: 'meadows',
    name: 'Mt. Hood Meadows',
    url: 'https://www.skihood.com',
    dataUrl: 'https://www.skihood.com/the-mountain/mountain-report',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lift-status',
      runsOpen: '.terrain-open',
      percentOpen: '.percent-terrain-open',
      status: '.operating-status',
    },
  },

  timberline: {
    id: 'timberline',
    name: 'Timberline Lodge',
    url: 'https://www.timberlinelodge.com',
    dataUrl: 'https://www.timberlinelodge.com/conditions',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lifts-open',
      runsOpen: '.runs-open',
      status: '.mountain-status',
    },
  },

  bachelor: {
    id: 'bachelor',
    name: 'Mt. Bachelor',
    url: 'https://www.mtbachelor.com',
    dataUrl: 'https://www.mtbachelor.com/the-mountain/conditions-weather/',
    type: 'html',
    enabled: false, // Temporarily disabled for testing (timeout issue)
    selectors: {
      liftsOpen: '.lift-status-count',
      runsOpen: '.run-count',
      acresOpen: '.acres-open',
      status: '.operating-status',
    },
  },

  // Washington - Eastern
  missionridge: {
    id: 'missionridge',
    name: 'Mission Ridge',
    url: 'https://www.missionridge.com',
    dataUrl: 'https://www.missionridge.com/mountain-report',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lifts-open',
      runsOpen: '.runs-open',
      status: '.resort-status',
    },
  },

  fortynine: {
    id: 'fortynine',
    name: '49 Degrees North',
    url: 'https://www.ski49n.com',
    dataUrl: 'https://www.ski49n.com/conditions',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lift-count',
      runsOpen: '.run-count',
      status: '.mountain-status',
    },
  },

  // Idaho
  schweitzer: {
    id: 'schweitzer',
    name: 'Schweitzer Mountain',
    url: 'https://www.schweitzer.com',
    dataUrl: 'https://www.schweitzer.com/the-mountain/mountain-report/',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lifts-operating',
      runsOpen: '.trails-open',
      percentOpen: '.terrain-open-percent',
      status: '.operating-status',
    },
  },

  lookout: {
    id: 'lookout',
    name: 'Lookout Pass',
    url: 'https://www.skilookout.com',
    dataUrl: 'https://www.skilookout.com/conditions',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lift-status',
      runsOpen: '.run-count',
      status: '.mountain-status',
    },
  },

  // Oregon - Southern
  ashland: {
    id: 'ashland',
    name: 'Mt. Ashland',
    url: 'https://www.mtashland.com',
    dataUrl: 'https://www.mtashland.com/conditions',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lifts-open',
      runsOpen: '.runs-open',
      status: '.operating-status',
    },
  },

  willamette: {
    id: 'willamette',
    name: 'Willamette Pass',
    url: 'https://www.willamettepass.com',
    dataUrl: 'https://www.willamettepass.com/conditions',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lift-count',
      runsOpen: '.run-count',
      status: '.resort-status',
    },
  },

  hoodoo: {
    id: 'hoodoo',
    name: 'Hoodoo Ski Area',
    url: 'https://www.skihoodoo.com',
    dataUrl: 'https://www.skihoodoo.com/mountain-report',
    type: 'html',
    enabled: false, // Disabled to reduce scraper timeout
    selectors: {
      liftsOpen: '.lifts-operating',
      runsOpen: '.runs-open',
      status: '.mountain-status',
    },
  },
};

/**
 * Get scraper config by mountain ID
 */
export function getScraperConfig(mountainId: string): ScraperConfig | undefined {
  return scraperConfigs[mountainId];
}

/**
 * Get all enabled scraper configs
 */
export function getEnabledConfigs(): ScraperConfig[] {
  return Object.values(scraperConfigs).filter((config) => config.enabled);
}

/**
 * Get scraper configs by type
 */
export function getConfigsByType(type: 'html' | 'api' | 'dynamic'): ScraperConfig[] {
  return Object.values(scraperConfigs).filter(
    (config) => config.type === type && config.enabled
  );
}
