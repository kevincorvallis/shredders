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
  // Washington - Cascades (Batch 1)
  baker: {
    id: 'baker',
    name: 'Mt. Baker',
    url: 'https://www.mtbaker.us',
    dataUrl: 'https://www.mtbaker.us/snow-report/',
    type: 'html',
    enabled: true,
    batch: 1,
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
    enabled: true,
    batch: 1,
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
    type: 'html',
    enabled: true,
    batch: 1,
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
    type: 'html',
    enabled: true,
    batch: 1,
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
    enabled: true,
    batch: 1,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Oregon (Batch 2)
  meadows: {
    id: 'meadows',
    name: 'Mt. Hood Meadows',
    url: 'https://www.skihood.com',
    dataUrl: 'https://www.onthesnow.com/oregon/mt-hood-meadows/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,
    batch: 2,
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
    enabled: true,
    batch: 2,
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
    enabled: true,
    batch: 2,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Washington - Eastern (Batch 2)
  missionridge: {
    id: 'missionridge',
    name: 'Mission Ridge',
    url: 'https://www.missionridge.com',
    dataUrl: 'https://www.onthesnow.com/washington/mission-ridge/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,
    batch: 2,
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
    enabled: true,
    batch: 2,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Idaho (Batch 3)
  schweitzer: {
    id: 'schweitzer',
    name: 'Schweitzer Mountain',
    url: 'https://www.schweitzer.com',
    dataUrl: 'https://www.onthesnow.com/idaho/schweitzer/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,
    batch: 3,
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
    enabled: true,
    batch: 3,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Oregon - Southern (Batch 3)
  ashland: {
    id: 'ashland',
    name: 'Mt. Ashland',
    url: 'https://www.mtashland.com',
    dataUrl: 'https://www.onthesnow.com/oregon/mount-ashland/skireport',  // OnTheSnow fallback
    type: 'html',
    enabled: true,
    batch: 3,
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
    enabled: true,
    batch: 3,
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
    enabled: true,
    batch: 3,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Idaho - Additional (Batch 4)
  sunvalley: {
    id: 'sunvalley',
    name: 'Sun Valley Resort',
    url: 'https://www.sunvalley.com',
    dataUrl: 'https://www.onthesnow.com/idaho/sun-valley-resort/skireport',
    type: 'html',
    enabled: true,
    batch: 4,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  brundage: {
    id: 'brundage',
    name: 'Brundage Mountain',
    url: 'https://www.brundage.com',
    dataUrl: 'https://www.onthesnow.com/idaho/brundage-mountain/skireport',
    type: 'html',
    enabled: true,
    batch: 4,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Oregon - Additional (Batch 4)
  anthonylakes: {
    id: 'anthonylakes',
    name: 'Anthony Lakes Mountain Resort',
    url: 'https://anthonylakes.com',
    dataUrl: 'https://www.onthesnow.com/oregon/anthony-lakes/skireport',
    type: 'html',
    enabled: true,
    batch: 4,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Canada - BC (Batch 4)
  whistler: {
    id: 'whistler',
    name: 'Whistler Blackcomb',
    url: 'https://www.whistlerblackcomb.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/whistler-blackcomb/skireport',
    type: 'html',
    enabled: true,
    batch: 4,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  revelstoke: {
    id: 'revelstoke',
    name: 'Revelstoke Mountain Resort',
    url: 'https://www.revelstokemountainresort.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/revelstoke-mountain-resort/skireport',
    type: 'html',
    enabled: true,
    batch: 4,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Canada - BC (Batch 5)
  cypress: {
    id: 'cypress',
    name: 'Cypress Mountain',
    url: 'https://www.cypressmountain.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/cypress-mountain/skireport',
    type: 'html',
    enabled: true,
    batch: 5,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  sunpeaks: {
    id: 'sunpeaks',
    name: 'Sun Peaks Resort',
    url: 'https://www.sunpeaksresort.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/sun-peaks-resort/skireport',
    type: 'html',
    enabled: true,
    batch: 5,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  bigwhite: {
    id: 'bigwhite',
    name: 'Big White Ski Resort',
    url: 'https://www.bigwhite.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/big-white/skireport',
    type: 'html',
    enabled: true,
    batch: 5,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  red: {
    id: 'red',
    name: 'RED Mountain Resort',
    url: 'https://www.redresort.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/red-mountain-resort/skireport',
    type: 'html',
    enabled: true,
    batch: 5,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  panorama: {
    id: 'panorama',
    name: 'Panorama Mountain Resort',
    url: 'https://www.panoramaresort.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/panorama-mountain-village/skireport',
    type: 'html',
    enabled: true,
    batch: 5,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  // Canada - BC (Batch 6)
  silverstar: {
    id: 'silverstar',
    name: 'SilverStar Mountain Resort',
    url: 'https://www.skisilverstar.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/silver-star/skireport',
    type: 'html',
    enabled: true,
    batch: 6,
    selectors: {
      liftsOpen: '[data-testid="lifts-status"], .lift-status',
      runsOpen: '[data-testid="trails-status"], .trail-status',
      status: '.conditions-header, .status',
    },
  },

  apex: {
    id: 'apex',
    name: 'Apex Mountain Resort',
    url: 'https://www.apexresort.com',
    dataUrl: 'https://www.onthesnow.com/british-columbia/apex-mountain-resort/skireport',
    type: 'html',
    enabled: true,
    batch: 6,
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

/**
 * Get scraper configs by batch number
 * Used for distributed scraping to avoid Vercel function timeouts
 */
export function getConfigsByBatch(batch: number): ScraperConfig[] {
  return Object.values(scraperConfigs).filter(
    (config) => config.enabled && config.batch === batch
  );
}

/**
 * Get all batch numbers that have enabled configs
 */
export function getAvailableBatches(): number[] {
  const batches = new Set<number>();
  for (const config of Object.values(scraperConfigs)) {
    if (config.enabled && config.batch) {
      batches.add(config.batch);
    }
  }
  return Array.from(batches).sort((a, b) => a - b);
}
