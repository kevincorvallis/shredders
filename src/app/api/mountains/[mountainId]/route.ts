import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';

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

  // Mountains are relatively static - cache for 1 hour
  return NextResponse.json(mountain, {
    headers: {
      'Cache-Control': 'public, max-age=3600, stale-while-revalidate=7200',
    },
  });
}
