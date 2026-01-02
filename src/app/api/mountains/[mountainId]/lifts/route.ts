import { NextResponse } from 'next/server';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';

// Initialize S3 client with explicit credentials from environment
const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-west-2',
  credentials: process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY ? {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID.trim(),
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY.trim(),
  } : undefined,
});

/**
 * GET /api/mountains/[mountainId]/lifts
 *
 * Returns GeoJSON data for ski lifts at the specified mountain.
 * Data is sourced from OpenStreetMap via OpenSnowMap and stored in S3.
 *
 * @param mountainId - Mountain identifier (e.g., 'crystal', 'baker', 'stevens', 'snoqualmie')
 * @returns GeoJSON FeatureCollection with lift polylines
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  try {
    const { mountainId } = await params;

    // Validate mountain ID
    const validMountains = ['baker', 'stevens', 'crystal', 'snoqualmie', 'whitepass', 'missionridge', '49north', 'lookout'];
    if (!validMountains.includes(mountainId)) {
      return NextResponse.json(
        { error: `Invalid mountain ID: ${mountainId}` },
        { status: 400 }
      );
    }

    // Fetch from S3 using AWS SDK
    const command = new GetObjectCommand({
      Bucket: 'shredders-lambda-deployments',
      Key: `ski-data/lifts/${mountainId}.geojson`,
    });

    const response = await s3Client.send(command);

    // Stream the response body to string
    const bodyString = await response.Body?.transformToString();
    if (!bodyString) {
      throw new Error('Empty response from S3');
    }

    const geojson = JSON.parse(bodyString);

    // Add CORS headers for potential direct access
    return NextResponse.json(geojson, {
      headers: {
        'Cache-Control': 'public, s-maxage=86400, stale-while-revalidate=604800',
        'Access-Control-Allow-Origin': '*',
      }
    });

  } catch (error: any) {
    console.error('Error fetching lift data:', error);

    // Handle specific S3 errors
    if (error.name === 'NoSuchKey') {
      return NextResponse.json(
        {
          error: 'Lifts not found',
          message: `No lift data available for ${await (await params).mountainId}. The mountain may not have lift data in OpenStreetMap yet.`
        },
        { status: 404 }
      );
    }

    return NextResponse.json(
      {
        error: 'Failed to fetch lift data',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

// OPTIONS handler for CORS preflight
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
