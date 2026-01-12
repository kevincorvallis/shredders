import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { findRelevantWsdotPasses, getWsdotMountainPassConditions } from '@/lib/apis/wsdot';

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

  // Only WA mountains are supported for now (WSDOT)
  if (mountain.region !== 'washington') {
    return NextResponse.json(
      {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        supported: false,
        configured: false,
        provider: null,
        passes: [],
        message: 'Road/pass data is currently supported for Washington mountains only.',
      },
      {
        headers: {
          'Cache-Control': 'public, s-maxage=1800, stale-while-revalidate=3600',
        },
      }
    );
  }

  const accessCode = process.env.WSDOT_ACCESS_CODE;
  if (!accessCode) {
    return NextResponse.json(
      {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        supported: true,
        configured: false,
        provider: 'WSDOT',
        passes: [],
        message: 'WSDOT access code is not configured. Set WSDOT_ACCESS_CODE to enable road/pass conditions.',
      },
      {
        headers: {
          'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
        },
      }
    );
  }

  try {
    const allPasses = await getWsdotMountainPassConditions(accessCode);
    const relevant = findRelevantWsdotPasses(mountainId, allPasses);

    return NextResponse.json(
      {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        supported: true,
        configured: true,
        provider: 'WSDOT',
        passes: relevant,
        lastUpdated: new Date().toISOString(),
      },
      {
        headers: {
          'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
        },
      }
    );
  } catch (error) {
    console.error('Error fetching WSDOT road data:', error);
    return NextResponse.json(
      {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        supported: true,
        configured: true,
        provider: 'WSDOT',
        passes: [],
        message: 'Failed to fetch road/pass conditions.',
      },
      {
        status: 200,
        headers: {
          'Cache-Control': 'public, s-maxage=120, stale-while-revalidate=300',
        },
      }
    );
  }
}
