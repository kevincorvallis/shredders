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
    dataUrl: 'https://www.onthesnow.com/washington/stevens-pass-resort/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      // OnTheSnow uses "X/Y open" format which parseRatio() handles
      liftsOpen: '[data-testid="lifts-status"], .lift-status, .lifts',
      runsOpen: '[data-testid="trails-status"], .trail-status, .trails',
      status: '.conditions-header, .status',
    },
  },

  crystal: {
    id: 'crystal',
    name: 'Crystal Mountain',
    url: 'https://www.crystalmountainresort.com',
    dataUrl: 'https://www.onthesnow.com/washington/crystal-mountain-wa/skireport',  // OnTheSnow fallback (no Puppeteer needed)
    type: 'html',  // Changed from 'dynamic' - using OnTheSnow instead
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  snoqualmie: {
    id: 'snoqualmie',
    name: 'Summit at Snoqualmie',
    url: 'https://www.summitatsnoqualmie.com',
    dataUrl: 'https://www.onthesnow.com/washington/the-summit-at-snoqualmie/skireport',  // OnTheSnow fallback
    type: 'html',  // Changed from 'dynamic' - using OnTheSnow instead
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  whitepass: {
    id: 'whitepass',
    name: 'White Pass',
    url: 'https://skiwhitepass.com',
    dataUrl: 'https://www.onthesnow.com/washington/white-pass/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Oregon
  meadows: {
    id: 'meadows',
    name: 'Mt. Hood Meadows',
    url: 'https://www.skihood.com',
    dataUrl: 'https://www.onthesnow.com/oregon/mt-hood-meadows/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  timberline: {
    id: 'timberline',
    name: 'Timberline Lodge',
    url: 'https://www.timberlinelodge.com',
    dataUrl: 'https://www.onthesnow.com/oregon/timberline-lodge/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  bachelor: {
    id: 'bachelor',
    name: 'Mt. Bachelor',
    url: 'https://www.mtbachelor.com',
    dataUrl: 'https://www.onthesnow.com/oregon/mt-bachelor/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Washington - Eastern
  missionridge: {
    id: 'missionridge',
    name: 'Mission Ridge',
    url: 'https://www.missionridge.com',
    dataUrl: 'https://www.onthesnow.com/washington/mission-ridge/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  fortynine: {
    id: 'fortynine',
    name: '49 Degrees North',
    url: 'https://www.ski49n.com',
    dataUrl: 'https://www.onthesnow.com/washington/49-degrees-north/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Idaho
  schweitzer: {
    id: 'schweitzer',
    name: 'Schweitzer Mountain',
    url: 'https://www.schweitzer.com',
    dataUrl: 'https://www.onthesnow.com/idaho/schweitzer/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  lookout: {
    id: 'lookout',
    name: 'Lookout Pass',
    url: 'https://www.skilookout.com',
    dataUrl: 'https://www.onthesnow.com/idaho/lookout-pass-ski-area/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Oregon - Southern
  ashland: {
    id: 'ashland',
    name: 'Mt. Ashland',
    url: 'https://www.mtashland.com',
    dataUrl: 'https://www.onthesnow.com/oregon/mount-ashland/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  willamette: {
    id: 'willamette',
    name: 'Willamette Pass',
    url: 'https://www.willamettepass.com',
    dataUrl: 'https://www.onthesnow.com/oregon/willamette-pass/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  hoodoo: {
    id: 'hoodoo',
    name: 'Hoodoo Ski Area',
    url: 'https://www.skihoodoo.com',
    dataUrl: 'https://www.onthesnow.com/oregon/hoodoo-ski-area/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,  // Enabled with OnTheSnow fallback
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
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
