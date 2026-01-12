/**
 * Phase 1: Data Source Verification API Endpoint
 *
 * GET /api/verify-sources
 *
 * Query Parameters:
 * - type: Filter by source type (scraper, noaa, snotel, open-meteo, webcam)
 * - mountain: Filter by mountain ID (e.g., baker, stevens)
 * - format: Response format (json, markdown) - default: json
 *
 * Examples:
 * - GET /api/verify-sources - Verify all sources
 * - GET /api/verify-sources?type=scraper - Verify only scrapers
 * - GET /api/verify-sources?mountain=baker - Verify only Mt. Baker
 * - GET /api/verify-sources?type=noaa&mountain=stevens - Verify NOAA for Stevens
 * - GET /api/verify-sources?format=markdown - Get markdown report
 *
 * Response:
 * - 200: Verification report (JSON or Markdown)
 * - 400: Invalid parameters
 * - 500: Verification failed
 */

import { NextRequest, NextResponse } from 'next/server';
import {
  VerificationAgent,
  runVerification,
  verifyMountain,
} from '@/lib/verification/VerificationAgent';
import { generateMarkdownReport } from '@/lib/verification/reportGenerator';
import type { VerificationConfig } from '@/lib/verification/types';

// ============================================================================
// API Route Handler
// ============================================================================

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;

  // Parse query parameters
  const typeParam = searchParams.get('type');
  const mountainParam = searchParams.get('mountain');
  const formatParam = searchParams.get('format') || 'json';

  // Validate parameters
  const validTypes = ['scraper', 'noaa', 'snotel', 'open-meteo', 'webcam'];
  if (typeParam && !validTypes.includes(typeParam)) {
    return NextResponse.json(
      {
        error: 'Invalid type parameter',
        validTypes,
      },
      { status: 400 }
    );
  }

  const validFormats = ['json', 'markdown'];
  if (!validFormats.includes(formatParam)) {
    return NextResponse.json(
      {
        error: 'Invalid format parameter',
        validFormats,
      },
      { status: 400 }
    );
  }

  try {
    console.log('\n🔍 API Request: /api/verify-sources');
    console.log(`   Type: ${typeParam || 'all'}`);
    console.log(`   Mountain: ${mountainParam || 'all'}`);
    console.log(`   Format: ${formatParam}`);

    // Build verification config
    const config: Partial<VerificationConfig> = {
      saveToFile: false, // Don't save to file when called via API
      saveToDB: false,
    };

    // Add type filter if specified
    if (typeParam) {
      config.includeTypes = [
        typeParam as 'scraper' | 'noaa' | 'snotel' | 'open-meteo' | 'webcam',
      ];
    }

    // Add mountain filter if specified
    if (mountainParam) {
      config.includeMountains = mountainParam.split(',').map((m) => m.trim());
    }

    // Run verification
    const agent = new VerificationAgent(config);
    const report = await agent.verifyAll();

    // Return based on format
    if (formatParam === 'markdown') {
      const markdown = generateMarkdownReport(report);
      return new NextResponse(markdown, {
        status: 200,
        headers: {
          'Content-Type': 'text/markdown',
          'Content-Disposition': `inline; filename="verification-report.md"`,
        },
      });
    }

    // Default: JSON
    return NextResponse.json(report, { status: 200 });
  } catch (error: any) {
    console.error('❌ Verification API Error:', error);

    return NextResponse.json(
      {
        error: 'Verification failed',
        message: error.message,
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}

// ============================================================================
// Route Configuration
// ============================================================================

export const dynamic = 'force-dynamic'; // Always run fresh, don't cache
export const runtime = 'nodejs'; // Use Node.js runtime for better compatibility
export const maxDuration = 300; // 5 minutes timeout (verification can take time)
