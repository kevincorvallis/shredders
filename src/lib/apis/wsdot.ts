import { z } from 'zod';

const WSDOT_BASE = 'https://wsdot.wa.gov/Traffic/api';

const TravelRestrictionSchema = z
  .object({
    TravelDirection: z.string().optional().nullable(),
    RestrictionText: z.string().optional().nullable(),
  })
  .nullable()
  .optional();

const PassConditionSchema = z.object({
  MountainPassId: z.number(),
  MountainPassName: z.string(),
  DateUpdated: z.string().optional().nullable(),
  TemperatureInFahrenheit: z.number().optional().nullable(),
  ElevationInFeet: z.number().optional().nullable(),
  WeatherCondition: z.string().optional().nullable(),
  RoadCondition: z.string().optional().nullable(),
  TravelAdvisoryActive: z.boolean().optional().nullable(),
  RestrictionOne: TravelRestrictionSchema,
  RestrictionTwo: TravelRestrictionSchema,
});

const PassConditionsResponseSchema = z.array(PassConditionSchema);

export type WsdotPassCondition = z.infer<typeof PassConditionSchema>;

export type WsdotPassSummary = {
  id: number;
  name: string;
  dateUpdated?: string | null;
  roadCondition?: string | null;
  weatherCondition?: string | null;
  temperatureF?: number | null;
  travelAdvisoryActive?: boolean | null;
  restrictions: Array<{ direction?: string | null; text?: string | null }>;
};

function mapPassToSummary(pass: WsdotPassCondition): WsdotPassSummary {
  const restrictions = [pass.RestrictionOne, pass.RestrictionTwo]
    .filter(Boolean)
    .map((r) => ({
      direction: r?.TravelDirection ?? null,
      text: r?.RestrictionText ?? null,
    }))
    .filter((r) => (r.direction && r.direction.trim()) || (r.text && r.text.trim()));

  return {
    id: pass.MountainPassId,
    name: pass.MountainPassName,
    dateUpdated: pass.DateUpdated ?? null,
    roadCondition: pass.RoadCondition ?? null,
    weatherCondition: pass.WeatherCondition ?? null,
    temperatureF: pass.TemperatureInFahrenheit ?? null,
    travelAdvisoryActive: pass.TravelAdvisoryActive ?? null,
    restrictions,
  };
}

export async function getWsdotMountainPassConditions(accessCode: string): Promise<WsdotPassSummary[]> {
  const url = `${WSDOT_BASE}/MountainPassConditions/MountainPassConditionsREST.svc/GetMountainPassConditionsAsJson?AccessCode=${encodeURIComponent(accessCode)}`;

  const response = await fetch(url, {
    // WSDOT updates frequently; cache briefly at the platform layer
    next: { revalidate: 300 },
    headers: {
      'User-Agent': 'shredders (mountain conditions app)',
      Accept: 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`WSDOT request failed: ${response.status}`);
  }

  const json = await response.json();
  const passes = PassConditionsResponseSchema.parse(json);
  return passes.map(mapPassToSummary);
}

const PASS_KEYWORDS_BY_MOUNTAIN: Record<string, string[]> = {
  // WA
  snoqualmie: ['Snoqualmie'],
  stevens: ['Stevens'],
  whitepass: ['White Pass', 'Whitepass'],
  crystal: ['Chinook', 'Cayuse'],
};

export function findRelevantWsdotPasses(mountainId: string, allPasses: WsdotPassSummary[]): WsdotPassSummary[] {
  const keywords = PASS_KEYWORDS_BY_MOUNTAIN[mountainId];
  if (!keywords || keywords.length === 0) return [];

  const matches: WsdotPassSummary[] = [];
  for (const keyword of keywords) {
    const keywordLower = keyword.toLowerCase();
    const found = allPasses.filter((p) => p.name.toLowerCase().includes(keywordLower));
    for (const pass of found) {
      if (!matches.some((m) => m.id === pass.id)) matches.push(pass);
    }
  }

  return matches;
}
