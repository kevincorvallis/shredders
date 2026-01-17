import { NextResponse } from 'next/server';

/**
 * Minimal test endpoint to verify function works without heavy dependencies
 */
export async function GET(request: Request) {
  const start = Date.now();

  try {
    // Just do a simple fetch to OnTheSnow
    const response = await fetch('https://www.onthesnow.com/washington/stevens-pass-resort/skireport');
    const html = await response.text();

    // Extract JSON from page
    const match = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.+?)<\/script>/);

    if (!match) {
      return NextResponse.json({
        success: false,
        error: 'Could not find __NEXT_DATA__',
        duration: Date.now() - start,
      });
    }

    const data = JSON.parse(match[1]);
    const fullResort = data?.props?.pageProps?.fullResort;

    return NextResponse.json({
      success: true,
      duration: Date.now() - start,
      lifts: fullResort?.lifts,
      runs: fullResort?.runs || fullResort?.trails,
      message: 'Test scrape successful',
    });
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start,
    }, { status: 500 });
  }
}
