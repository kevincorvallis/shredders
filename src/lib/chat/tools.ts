import { tool } from 'ai';
import { z } from 'zod';
import { getAllMountains, getMountain, type MountainConfig } from '@/data/mountains';

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app';

// Parse various mountain name formats to a mountain ID
function parseMountainId(input: string): string {
  const normalized = input.toLowerCase().trim();

  // Direct ID match
  const mountains = getAllMountains();
  const directMatch = mountains.find(m => m.id === normalized);
  if (directMatch) return directMatch.id;

  // Name matching
  const nameMap: Record<string, string> = {
    // Baker variations
    'baker': 'baker',
    'mt baker': 'baker',
    'mt. baker': 'baker',
    'mount baker': 'baker',
    // Stevens variations
    'stevens': 'stevens',
    'stevens pass': 'stevens',
    // Crystal variations
    'crystal': 'crystal',
    'crystal mountain': 'crystal',
    // Snoqualmie variations
    'snoqualmie': 'snoqualmie',
    'snoqualmie pass': 'snoqualmie',
    'the summit': 'snoqualmie',
    'summit at snoqualmie': 'snoqualmie',
    // White Pass variations
    'white pass': 'whitepass',
    'whitepass': 'whitepass',
    // Hood Meadows variations
    'meadows': 'meadows',
    'mt hood meadows': 'meadows',
    'mt. hood meadows': 'meadows',
    'hood meadows': 'meadows',
    // Timberline variations
    'timberline': 'timberline',
    'timberline lodge': 'timberline',
    // Bachelor variations
    'bachelor': 'bachelor',
    'mt bachelor': 'bachelor',
    'mt. bachelor': 'bachelor',
    'mount bachelor': 'bachelor',
  };

  if (nameMap[normalized]) {
    return nameMap[normalized];
  }

  // Fuzzy match - find best match
  for (const mountain of mountains) {
    if (
      normalized.includes(mountain.id) ||
      normalized.includes(mountain.shortName.toLowerCase()) ||
      mountain.name.toLowerCase().includes(normalized)
    ) {
      return mountain.id;
    }
  }

  // Default to baker if no match
  return 'baker';
}

// Get display name for a mountain
function getMountainName(id: string): string {
  const mountain = getMountain(id);
  return mountain?.name || 'Mt. Baker';
}

export const chatTools = {
  get_conditions: tool({
    description: 'Get current snow and weather conditions for a mountain. Use this when the user asks about current conditions, snow depth, temperature, or general "how is it looking" questions.',
    inputSchema: z.object({
      mountain: z.string().describe('The mountain name (e.g., "Baker", "Mt. Baker", "Stevens Pass", "Crystal Mountain", "Bachelor")'),
    }),
    execute: async ({ mountain }) => {
      const mountainId = parseMountainId(mountain);
      const response = await fetch(`${BASE_URL}/api/mountains/${mountainId}/conditions`);
      const data = await response.json();
      return {
        type: 'conditions' as const,
        mountain: getMountainName(mountainId),
        mountainId,
        data,
      };
    },
  }),

  get_forecast: tool({
    description: 'Get the 7-day weather forecast for a mountain. Use this when the user asks about upcoming weather, future conditions, or weekend forecasts.',
    inputSchema: z.object({
      mountain: z.string().describe('The mountain name'),
      days: z.number().optional().describe('Number of days to forecast (default 7)'),
    }),
    execute: async ({ mountain, days = 7 }) => {
      const mountainId = parseMountainId(mountain);
      const response = await fetch(`${BASE_URL}/api/mountains/${mountainId}/forecast`);
      const data = await response.json();
      return {
        type: 'forecast' as const,
        mountain: getMountainName(mountainId),
        mountainId,
        data: (data.forecast || []).slice(0, days),
      };
    },
  }),

  get_powder_score: tool({
    description: 'Get the calculated powder score (1-10) with breakdown of factors. Use this when the user asks about powder conditions, whether it\'s a good day to ski, or powder score.',
    inputSchema: z.object({
      mountain: z.string().describe('The mountain name'),
    }),
    execute: async ({ mountain }) => {
      const mountainId = parseMountainId(mountain);
      const response = await fetch(`${BASE_URL}/api/mountains/${mountainId}/powder-score`);
      const data = await response.json();
      return {
        type: 'powder_score' as const,
        mountain: getMountainName(mountainId),
        mountainId,
        data,
      };
    },
  }),

  get_history: tool({
    description: 'Get historical snow depth data for charts. Use this when the user asks about snow history, trends, or wants to see how the snowpack has changed.',
    inputSchema: z.object({
      mountain: z.string().describe('The mountain name'),
      days: z.number().optional().describe('Number of days of history (default 30)'),
    }),
    execute: async ({ mountain, days = 30 }) => {
      const mountainId = parseMountainId(mountain);
      const response = await fetch(`${BASE_URL}/api/mountains/${mountainId}/history?days=${days}`);
      const data = await response.json();
      return {
        type: 'chart' as const,
        mountain: getMountainName(mountainId),
        mountainId,
        chartType: 'snow_depth',
        days,
        data: data.history || [],
      };
    },
  }),

  get_webcam: tool({
    description: 'Get webcam feed for a mountain. Use this when the user asks to see the mountain, wants a webcam view, or asks what it looks like.',
    inputSchema: z.object({
      mountain: z.string().describe('The mountain name'),
      location: z.string().optional().describe('Specific webcam location (e.g., "base", "summit")'),
    }),
    execute: async ({ mountain, location }) => {
      const mountainId = parseMountainId(mountain);
      const mountainData = getMountain(mountainId);

      if (!mountainData || mountainData.webcams.length === 0) {
        return {
          type: 'webcam' as const,
          mountain: getMountainName(mountainId),
          mountainId,
          name: 'No webcam available',
          url: '',
          refreshUrl: mountainData?.website || '',
          error: 'No webcam data available for this mountain',
        };
      }

      // Try to match requested location to a webcam
      let selectedCam = mountainData.webcams[0];
      if (location) {
        const locLower = location.toLowerCase();
        const match = mountainData.webcams.find(
          cam => cam.name.toLowerCase().includes(locLower) || cam.id.toLowerCase().includes(locLower)
        );
        if (match) selectedCam = match;
      }

      return {
        type: 'webcam' as const,
        mountain: getMountainName(mountainId),
        mountainId,
        name: selectedCam.name,
        url: selectedCam.url,
        refreshUrl: selectedCam.refreshUrl || mountainData.website,
        allWebcams: mountainData.webcams.map(w => ({ id: w.id, name: w.name })),
      };
    },
  }),

  compare_mountains: tool({
    description: 'Compare conditions between two mountains. Use this when the user wants to compare mountains or decide between them.',
    inputSchema: z.object({
      mountain1: z.string().describe('First mountain to compare'),
      mountain2: z.string().describe('Second mountain to compare'),
    }),
    execute: async ({ mountain1, mountain2 }) => {
      const id1 = parseMountainId(mountain1);
      const id2 = parseMountainId(mountain2);

      // Fetch data for both mountains in parallel
      const [conditions1, conditions2, score1, score2] = await Promise.all([
        fetch(`${BASE_URL}/api/mountains/${id1}/conditions`).then(r => r.json()).catch(() => null),
        fetch(`${BASE_URL}/api/mountains/${id2}/conditions`).then(r => r.json()).catch(() => null),
        fetch(`${BASE_URL}/api/mountains/${id1}/powder-score`).then(r => r.json()).catch(() => null),
        fetch(`${BASE_URL}/api/mountains/${id2}/powder-score`).then(r => r.json()).catch(() => null),
      ]);

      return {
        type: 'comparison' as const,
        mountains: [
          {
            id: id1,
            name: getMountainName(id1),
            powderScore: score1?.score ?? null,
            snowDepth: conditions1?.snowDepth ?? null,
            newSnow: conditions1?.snowfall24h ?? 0,
            temperature: conditions1?.temperature ?? null,
            wind: conditions1?.wind?.speed ?? null,
            verdict: score1?.verdict ?? 'Data unavailable',
          },
          {
            id: id2,
            name: getMountainName(id2),
            powderScore: score2?.score ?? null,
            snowDepth: conditions2?.snowDepth ?? null,
            newSnow: conditions2?.snowfall24h ?? 0,
            temperature: conditions2?.temperature ?? null,
            wind: conditions2?.wind?.speed ?? null,
            verdict: score2?.verdict ?? 'Data unavailable',
          },
        ],
      };
    },
  }),

  list_mountains: tool({
    description: 'List all available mountains with their basic info. Use this when the user asks what mountains are available or wants to see all options.',
    inputSchema: z.object({}),
    execute: async () => {
      const mountains = getAllMountains();
      return {
        type: 'mountain_list' as const,
        mountains: mountains.map(m => ({
          id: m.id,
          name: m.name,
          shortName: m.shortName,
          region: m.region,
          elevation: m.elevation.summit,
          hasSnotel: !!m.snotel,
        })),
      };
    },
  }),
};

export type ToolResult =
  | { type: 'conditions'; mountain: string; mountainId: string; data: unknown }
  | { type: 'forecast'; mountain: string; mountainId: string; data: unknown[] }
  | { type: 'powder_score'; mountain: string; mountainId: string; data: unknown }
  | { type: 'chart'; mountain: string; mountainId: string; chartType: string; days: number; data: unknown[] }
  | { type: 'webcam'; mountain: string; mountainId: string; name: string; url: string; refreshUrl: string; allWebcams?: { id: string; name: string }[]; error?: string }
  | { type: 'comparison'; mountains: unknown[] }
  | { type: 'mountain_list'; mountains: unknown[] };
