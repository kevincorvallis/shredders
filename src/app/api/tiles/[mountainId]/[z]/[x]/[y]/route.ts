import { NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * GET /api/tiles/[mountainId]/[z]/[x]/[y]
 *
 * Serves map tiles for ski lift overlays.
 * Generates tiles on-demand if they don't exist.
 *
 * @param mountainId - Mountain identifier (e.g., 'crystal', 'baker')
 * @param z - Zoom level (10-16)
 * @param x - Tile X coordinate
 * @param y - Tile Y coordinate (without .png extension)
 *
 * @returns PNG image tile
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string; z: string; x: string; y: string }> }
) {
  try {
    const { mountainId, z, x, y } = await params;

    // Remove .png extension if present
    const yValue = y.replace('.png', '');

    // Validate parameters
    const zoom = parseInt(z);
    const tileX = parseInt(x);
    const tileY = parseInt(yValue);

    if (isNaN(zoom) || isNaN(tileX) || isNaN(tileY)) {
      return NextResponse.json({ error: 'Invalid tile coordinates' }, { status: 400 });
    }

    if (zoom < 10 || zoom > 16) {
      return NextResponse.json({ error: 'Zoom level must be between 10 and 16' }, { status: 400 });
    }

    // Construct tile path
    const tilePath = path.join(
      process.cwd(),
      'public',
      'tiles',
      mountainId,
      z,
      x,
      `${yValue}.png`
    );

    // Check if tile exists
    try {
      const tileData = await fs.readFile(tilePath);

      // Return the tile with appropriate headers
      return new NextResponse(tileData, {
        headers: {
          'Content-Type': 'image/png',
          'Cache-Control': 'public, max-age=31536000, immutable',
          'Access-Control-Allow-Origin': '*',
        },
      });
    } catch (error: any) {
      if (error.code !== 'ENOENT') {
        throw error;
      }

      // Tile doesn't exist - generate it
      console.log(`Generating missing tile: ${mountainId}/${z}/${x}/${yValue}`);

      try {
        // Run tile generation script for this specific zoom level
        const scriptPath = path.join(process.cwd(), 'scripts', 'generate-lift-tiles.py');
        const venvPython = path.join(process.cwd(), '.venv', 'bin', 'python3');

        await execAsync(
          `${venvPython} ${scriptPath} ${mountainId} --zoom-min ${zoom} --zoom-max ${zoom}`,
          { timeout: 30000 }
        );

        // Try reading the tile again
        const tileData = await fs.readFile(tilePath);

        return new NextResponse(tileData, {
          headers: {
            'Content-Type': 'image/png',
            'Cache-Control': 'public, max-age=31536000, immutable',
            'Access-Control-Allow-Origin': '*',
          },
        });
      } catch (genError) {
        console.error('Failed to generate tile:', genError);

        // Return empty transparent tile as fallback
        const emptyTile = Buffer.from(
          'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEgAACxIB0t1+/AAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAALgSURBVHic7cEBDQAAAMKg909tDjegAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAeAMyvAACcQOL8QAAAABJRU5ErkJggg==',
          'base64'
        );

        return new NextResponse(emptyTile, {
          headers: {
            'Content-Type': 'image/png',
            'Cache-Control': 'public, max-age=300', // Cache empty tiles for 5 minutes only
            'Access-Control-Allow-Origin': '*',
          },
        });
      }
    }
  } catch (error: any) {
    console.error('Error serving tile:', error);

    return NextResponse.json(
      {
        error: 'Failed to serve tile',
        details: error instanceof Error ? error.message : 'Unknown error',
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
