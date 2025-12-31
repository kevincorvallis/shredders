const mountainConfigs = {
  crystal: {
    id: 'crystal',
    name: 'Crystal Mountain',
    url: 'https://www.crystalmountainresort.com/the-mountain/mountain-report',
    type: 'http',  // Uses HTTP + Cheerio (no Puppeteer needed)
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/washington/crystal-mountain-wa/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  snoqualmie: {
    id: 'snoqualmie',
    name: 'Summit at Snoqualmie',
    url: 'https://www.summitatsnoqualmie.com/mountain-report',
    type: 'puppeteer',  // Requires JavaScript rendering
    enabled: true,
    selectors: {
      liftsOpen: 'span[aria-label*="Numerator value"]',
      runsOpen: 'span[aria-label*="Numerator value"]',
      status: 'h1, h2',
      message: '[class*="daily"], [class*="conditions"]',
    },
    puppeteerConfig: {
      timeout: 30000,
      scrollDelay: 1000,
    },
  },

  baker: {
    id: 'baker',
    name: 'Mt. Baker',
    url: 'https://www.mtbaker.us/snow-report/',
    type: 'http',  // Uses HTTP + CSS selectors
    enabled: true,
    selectors: {
      liftsOpen: '.lift-status.status .status-open',
      liftsClosed: '.lift-status.status .status-closed',
      // No run selectors available on their site
    },
  },

  whitepass: {
    id: 'whitepass',
    name: 'White Pass',
    url: 'https://skiwhitepass.com/the-mountain/conditions/',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/washington/white-pass/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  alpental: {
    id: 'alpental',
    name: 'Alpental',
    url: 'https://www.summitatsnoqualmie.com/the-mountains/alpental/',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/washington/alpental/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  missionridge: {
    id: 'missionridge',
    name: 'Mission Ridge',
    url: 'https://www.missionridge.com/conditions/',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/washington/mission-ridge/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  fortynine: {
    id: 'fortynine',
    name: '49 Degrees North',
    url: 'https://www.ski49n.com/the-mountain/mountain-report/',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/washington/49-degrees-north/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  // ========== BATCH 1: MAJOR RESORTS (5 mountains) ==========

  whistler: {
    id: 'whistler',
    name: 'Whistler Blackcomb',
    url: 'https://www.whistlerblackcomb.com/the-mountain/mountain-conditions/terrain-and-lift-status.aspx',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/british-columbia/whistler-blackcomb/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  palisades: {
    id: 'palisades',
    name: 'Palisades Tahoe',
    url: 'https://www.palisadestahoe.com/mountain-info/lift-status',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/california/palisades-tahoe/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  northstar: {
    id: 'northstar',
    name: 'Northstar California',
    url: 'https://www.northstarcalifornia.com/the-mountain/mountain-conditions/terrain-and-lift-status.aspx',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/california/northstar-california/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  sunvalley: {
    id: 'sunvalley',
    name: 'Sun Valley',
    url: 'https://www.sunvalley.com/mountain-report',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/idaho/sun-valley/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  bigwhite: {
    id: 'bigwhite',
    name: 'Big White',
    url: 'https://www.bigwhite.com/conditions',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/british-columbia/big-white/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  // ========== BATCH 2: REGIONAL FAVORITES (6 mountains) ==========

  sunpeaks: {
    id: 'sunpeaks',
    name: 'Sun Peaks',
    url: 'https://www.sunpeaksresort.com/mountain-report',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/british-columbia/sun-peaks/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  kirkwood: {
    id: 'kirkwood',
    name: 'Kirkwood',
    url: 'https://www.kirkwood.com/the-mountain/mountain-conditions/terrain-and-lift-status.aspx',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/california/kirkwood/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  sierraattahoe: {
    id: 'sierraattahoe',
    name: 'Sierra-at-Tahoe',
    url: 'https://www.sierraattahoe.com/mountain-report/',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/california/sierra-at-tahoe/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  schweitzer: {
    id: 'schweitzer',
    name: 'Schweitzer',
    url: 'https://www.schweitzer.com/the-mountain/lift-and-terrain-status/',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/idaho/schweitzer/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  grouse: {
    id: 'grouse',
    name: 'Grouse Mountain',
    url: 'https://www.grousemountain.com/snow-report',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/british-columbia/grouse-mountain/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },

  cypress: {
    id: 'cypress',
    name: 'Cypress Mountain',
    url: 'https://www.cypressmountain.com/conditions',
    type: 'http',  // Uses OnTheSnow
    enabled: true,
    dataUrl: 'https://www.onthesnow.com/british-columbia/cypress-mountain/skireport',
    selectors: {
      liftsPattern: /(\d+)\s+of\s+(\d+)\s+lifts?/gi,
      runsPattern: /(\d+)\s+of\s+(\d+)\s+trails?/gi,
    },
  },
};

function getEnabledConfigs() {
  return Object.values(mountainConfigs).filter(c => c.enabled);
}

module.exports = { mountainConfigs, getEnabledConfigs };
