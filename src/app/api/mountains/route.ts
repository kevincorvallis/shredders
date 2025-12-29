import { NextResponse } from 'next/server';
import { getAllMountains, getMountainsByRegion } from '@/data/mountains';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const region = searchParams.get('region') as 'washington' | 'oregon' | null;

  const mountains = region ? getMountainsByRegion(region) : getAllMountains();

  return NextResponse.json({
    mountains: mountains.map((m) => ({
      id: m.id,
      name: m.name,
      shortName: m.shortName,
      location: m.location,
      elevation: m.elevation,
      region: m.region,
      color: m.color,
      website: m.website,
      hasSnotel: !!m.snotel,
      webcamCount: m.webcams.length,
      logo: m.logo,
      status: m.status,
    })),
  });
}
