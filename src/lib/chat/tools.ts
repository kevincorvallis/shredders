import { tool } from 'ai';
import { z } from 'zod';

export const chatTools = {
  get_conditions: tool({
    description: 'Get current snow and weather conditions for a mountain. Use this when the user asks about current conditions, snow depth, temperature, or general "how is it looking" questions.',
    inputSchema: z.object({
      mountain: z.string().describe('The mountain name (e.g., "Baker", "Mt. Baker", "Stevens Pass", "Crystal Mountain")'),
    }),
    execute: async ({ mountain }) => {
      const response = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app'}/api/conditions`);
      const data = await response.json();
      return {
        type: 'conditions' as const,
        mountain: mountain || 'Mt. Baker',
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
      const response = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app'}/api/forecast`);
      const data = await response.json();
      return {
        type: 'forecast' as const,
        mountain: mountain || 'Mt. Baker',
        data: data.slice(0, days),
      };
    },
  }),

  get_powder_score: tool({
    description: 'Get the calculated powder score (1-10) with breakdown of factors. Use this when the user asks about powder conditions, whether it\'s a good day to ski, or powder score.',
    inputSchema: z.object({
      mountain: z.string().describe('The mountain name'),
    }),
    execute: async ({ mountain }) => {
      const response = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app'}/api/powder-score`);
      const data = await response.json();
      return {
        type: 'powder_score' as const,
        mountain: mountain || 'Mt. Baker',
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
      const response = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app'}/api/history?days=${days}`);
      const data = await response.json();
      return {
        type: 'chart' as const,
        mountain: mountain || 'Mt. Baker',
        chartType: 'snow_depth',
        days,
        data,
      };
    },
  }),

  get_webcam: tool({
    description: 'Get webcam feed for a mountain. Use this when the user asks to see the mountain, wants a webcam view, or asks what it looks like.',
    inputSchema: z.object({
      mountain: z.string().describe('The mountain name'),
      location: z.string().optional().describe('Specific webcam location (e.g., "base", "summit", "chair 9")'),
    }),
    execute: async ({ mountain, location }) => {
      // Mt. Baker webcam URLs
      const webcams = {
        'chair8': {
          name: 'Chair 8',
          url: 'https://www.mtbaker.us/images/webcam/C8.jpg',
          refreshUrl: 'https://www.mtbaker.us/snow-report/webcams',
        },
        'base': {
          name: 'White Salmon Base',
          url: 'https://www.mtbaker.us/images/webcam/WSday.jpg',
          refreshUrl: 'https://www.mtbaker.us/snow-report/webcams',
        },
        'pan': {
          name: 'Pan Dome',
          url: 'https://www.mtbaker.us/images/webcam/pan.jpg',
          refreshUrl: 'https://www.mtbaker.us/snow-report/webcams',
        },
      };

      const selectedCam = location?.toLowerCase().includes('base') ? webcams.base :
                          location?.toLowerCase().includes('pan') ? webcams.pan :
                          webcams.chair8;

      return {
        type: 'webcam' as const,
        mountain: mountain || 'Mt. Baker',
        ...selectedCam,
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
      // For now, we only have Baker data, so we'll return mock comparison
      const response = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app'}/api/conditions`);
      const bakerData = await response.json();

      const scoreResponse = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app'}/api/powder-score`);
      const scoreData = await scoreResponse.json();

      return {
        type: 'comparison' as const,
        mountains: [
          {
            name: mountain1 || 'Mt. Baker',
            powderScore: scoreData.score,
            snowDepth: bakerData.snowDepth,
            newSnow: bakerData.snowfall24h,
            temperature: bakerData.temperature,
            wind: bakerData.wind?.speed || 15,
          },
          {
            name: mountain2 || 'Stevens Pass',
            powderScore: Math.max(1, scoreData.score - 2),
            snowDepth: Math.round(bakerData.snowDepth * 0.7),
            newSnow: Math.round(bakerData.snowfall24h * 0.6),
            temperature: bakerData.temperature + 8,
            wind: (bakerData.wind?.speed || 15) + 10,
          },
        ],
      };
    },
  }),
};

export type ToolResult =
  | { type: 'conditions'; mountain: string; data: unknown }
  | { type: 'forecast'; mountain: string; data: unknown[] }
  | { type: 'powder_score'; mountain: string; data: unknown }
  | { type: 'chart'; mountain: string; chartType: string; days: number; data: unknown[] }
  | { type: 'webcam'; mountain: string; name: string; url: string; refreshUrl: string }
  | { type: 'comparison'; mountains: unknown[] };
