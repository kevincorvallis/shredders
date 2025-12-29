import { NextResponse } from 'next/server';

/**
 * Get scraped status data
 * GET /api/scraper/status?mountain=baker
 * GET /api/scraper/status (all mountains)
 */
export async function GET(request: Request) {
  // Use PostgreSQL storage if DATABASE_URL is set, otherwise use in-memory
  const usePostgres = !!process.env.DATABASE_URL;
  const storage = usePostgres
    ? await import('@/lib/scraper/storage-postgres').then((m) => m.scraperStorage)
    : await import('@/lib/scraper/storage').then((m) => m.scraperStorage);
  try {
    const { searchParams } = new URL(request.url);
    const mountainId = searchParams.get('mountain');

    if (mountainId) {
      // Get status for specific mountain
      const status = usePostgres && 'get' in storage
        ? await storage.get(mountainId)
        : 'get' in storage
        ? storage.get(mountainId)
        : null;

      if (!status) {
        return NextResponse.json(
          {
            success: false,
            error: `No data found for mountain: ${mountainId}`,
          },
          { status: 404 }
        );
      }

      return NextResponse.json({
        success: true,
        data: status,
      });
    } else {
      // Get all statuses
      let allStatus: any[] = [];
      let stats: any = {};

      if (usePostgres && 'getAll' in storage) {
        allStatus = await storage.getAll() as any[];
        stats = 'getStats' in storage ? await storage.getStats() : {};
      } else if ('getAll' in storage) {
        const result = storage.getAll();
        allStatus = Array.isArray(result) ? result : [];
        stats = 'getStats' in storage ? storage.getStats() : {};
      }

      return NextResponse.json({
        success: true,
        count: allStatus.length,
        data: allStatus,
        stats,
        storage: usePostgres ? 'postgresql' : 'in-memory',
      });
    }
  } catch (error) {
    console.error('[API] Error fetching scraper status:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
