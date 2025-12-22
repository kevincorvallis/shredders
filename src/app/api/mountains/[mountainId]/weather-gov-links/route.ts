import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getWeatherGovUrls } from '@/lib/apis/noaa';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  const { mountainId } = await params;
  const mountain = getMountain(mountainId);

  if (!mountain) {
    return NextResponse.json(
      { error: `Mountain '${mountainId}' not found` },
      { status: 404 }
    );
  }

  const urls = getWeatherGovUrls(
    mountain.location.lat,
    mountain.location.lng,
    mountain.noaa
  );

  return NextResponse.json({
    mountain: {
      id: mountain.id,
      name: mountain.name,
      shortName: mountain.shortName,
    },
    weatherGov: urls,
    location: mountain.location,
  });
}
