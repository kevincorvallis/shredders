/**
 * Phase 1: Main Verification Agent
 *
 * Orchestrates verification of all data sources:
 * 1. Resort scrapers (15 configs)
 * 2. NOAA Weather API (68 endpoints: 17 mountains × 4 endpoints)
 * 3. SNOTEL stations (17 stations)
 * 4. Open-Meteo API (26 mountains)
 * 5. Webcams (40+ webcams)
 *
 * Total: 150+ data sources verified
 *
 * Outputs:
 * - Comprehensive JSON report
 * - Human-readable markdown summary
 * - Console summary with key statistics
 * - Optional database storage
 */

import type {
  VerificationConfig,
  VerificationResult,
  VerificationReport,
} from './types';
import { DEFAULT_VERIFICATION_CONFIG } from './types';
import { verifyAllScrapers } from './scraperVerifier';
import { verifyAllNOAA } from './noaaVerifier';
import { verifyAllSNOTEL } from './snotelVerifier';
import { verifyAllOpenMeteo } from './openMeteoVerifier';
import { verifyAllWebcams } from './webcamVerifier';
import {
  generateReport,
  saveReportToFile,
  printReportSummary,
} from './reportGenerator';

// ============================================================================
// Main Verification Agent Class
// ============================================================================

export class VerificationAgent {
  private config: VerificationConfig;

  constructor(config?: Partial<VerificationConfig>) {
    // Merge with default config
    this.config = {
      ...DEFAULT_VERIFICATION_CONFIG,
      ...config,
    } as VerificationConfig;
  }

  /**
   * Run full verification of all data sources
   */
  async verifyAll(): Promise<VerificationReport> {
    console.log('\n' + '='.repeat(60));
    console.log('DATA SOURCE VERIFICATION AGENT - PHASE 1');
    console.log('='.repeat(60));
    console.log(`\nStarting verification at ${new Date().toLocaleString()}`);
    console.log(`Configuration:`);
    console.log(`  - Rate limit: ${this.config.delayBetweenRequests}ms between requests`);
    console.log(`  - Timeout: ${this.config.timeout}ms per request`);
    console.log(`  - Max retries: ${this.config.maxRetries}`);
    console.log(`  - Stale threshold: ${this.config.staleDataThreshold} hours`);

    const allResults: VerificationResult[] = [];
    const startTime = Date.now();

    // Determine which types to verify
    const includeTypes = this.config.includeTypes || [
      'scraper',
      'noaa',
      'snotel',
      'open-meteo',
      'webcam',
    ];

    try {
      // 1. Verify Scrapers
      if (includeTypes.includes('scraper')) {
        console.log('\n--- Phase 1/5: Verifying Resort Scrapers ---');
        const scraperResults = await verifyAllScrapers(this.config);
        allResults.push(...scraperResults);
        console.log(`✓ Completed: ${scraperResults.length} scrapers verified`);
      }

      // 2. Verify NOAA APIs
      if (includeTypes.includes('noaa')) {
        console.log('\n--- Phase 2/5: Verifying NOAA Weather APIs ---');
        const noaaResults = await verifyAllNOAA(this.config);
        allResults.push(...noaaResults);
        console.log(`✓ Completed: ${noaaResults.length} NOAA endpoints verified`);
      }

      // 3. Verify SNOTEL Stations
      if (includeTypes.includes('snotel')) {
        console.log('\n--- Phase 3/5: Verifying SNOTEL Stations ---');
        const snotelResults = await verifyAllSNOTEL(this.config);
        allResults.push(...snotelResults);
        console.log(`✓ Completed: ${snotelResults.length} SNOTEL stations verified`);
      }

      // 4. Verify Open-Meteo APIs
      if (includeTypes.includes('open-meteo')) {
        console.log('\n--- Phase 4/5: Verifying Open-Meteo APIs ---');
        const openMeteoResults = await verifyAllOpenMeteo(this.config);
        allResults.push(...openMeteoResults);
        console.log(`✓ Completed: ${openMeteoResults.length} Open-Meteo endpoints verified`);
      }

      // 5. Verify Webcams
      if (includeTypes.includes('webcam')) {
        console.log('\n--- Phase 5/5: Verifying Webcams ---');
        const webcamResults = await verifyAllWebcams(this.config);
        allResults.push(...webcamResults);
        console.log(`✓ Completed: ${webcamResults.length} webcams verified`);
      }

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log(`\n✓ All verifications completed in ${duration}s`);

      // Generate report
      console.log('\nGenerating report...');
      const report = generateReport(allResults);

      // Save to file if configured
      if (this.config.saveToFile && this.config.outputDir) {
        const { jsonPath, markdownPath } = await saveReportToFile(
          report,
          this.config.outputDir
        );
        console.log(`\n✓ Reports saved:`);
        console.log(`  JSON: ${jsonPath}`);
        console.log(`  Markdown: ${markdownPath}`);
      }

      // Save to database if configured
      if (this.config.saveToDB) {
        console.log('\n⚠️  Database storage not yet implemented');
        // TODO: Implement database storage
      }

      // Print summary
      printReportSummary(report);

      return report;
    } catch (error: any) {
      console.error('\n❌ Verification failed:', error.message);
      throw error;
    }
  }

  /**
   * Verify only specific source types
   */
  async verifyType(
    type: 'scraper' | 'noaa' | 'snotel' | 'open-meteo' | 'webcam'
  ): Promise<VerificationReport> {
    console.log(`\n🔍 Verifying only: ${type}`);
    this.config.includeTypes = [type];
    return this.verifyAll();
  }

  /**
   * Verify only specific mountains
   */
  async verifyMountains(mountainIds: string[]): Promise<VerificationReport> {
    console.log(`\n🔍 Verifying mountains: ${mountainIds.join(', ')}`);
    this.config.includeMountains = mountainIds;
    return this.verifyAll();
  }

  /**
   * Quick verification (single mountain, all types)
   */
  async quickVerify(mountainId: string): Promise<VerificationReport> {
    console.log(`\n🔍 Quick verification for: ${mountainId}`);
    this.config.includeMountains = [mountainId];
    return this.verifyAll();
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/**
 * Run full verification with default config
 */
export async function runVerification(
  config?: Partial<VerificationConfig>
): Promise<VerificationReport> {
  const agent = new VerificationAgent(config);
  return agent.verifyAll();
}

/**
 * Verify a single mountain
 */
export async function verifyMountain(
  mountainId: string,
  config?: Partial<VerificationConfig>
): Promise<VerificationReport> {
  const agent = new VerificationAgent(config);
  return agent.quickVerify(mountainId);
}

/**
 * Verify only scrapers
 */
export async function verifyOnlyScrapers(
  config?: Partial<VerificationConfig>
): Promise<VerificationReport> {
  const agent = new VerificationAgent(config);
  return agent.verifyType('scraper');
}

/**
 * Verify only APIs (NOAA + SNOTEL + Open-Meteo)
 */
export async function verifyOnlyAPIs(
  config?: Partial<VerificationConfig>
): Promise<VerificationReport> {
  const agent = new VerificationAgent({
    ...config,
    includeTypes: ['noaa', 'snotel', 'open-meteo'],
  });
  return agent.verifyAll();
}

/**
 * Verify only webcams
 */
export async function verifyOnlyWebcams(
  config?: Partial<VerificationConfig>
): Promise<VerificationReport> {
  const agent = new VerificationAgent(config);
  return agent.verifyType('webcam');
}
