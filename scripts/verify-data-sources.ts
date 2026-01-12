#!/usr/bin/env tsx

/**
 * Phase 1: Data Source Verification CLI Script
 *
 * Usage:
 *   npm run verify                    # Verify all sources
 *   npm run verify -- --type=scraper  # Verify only scrapers
 *   npm run verify -- --mountain=baker # Verify only Mt. Baker
 *   npm run verify -- --quick         # Quick test (Mt. Baker only)
 *
 * This script tests all data sources and generates a comprehensive report.
 */

import { runVerification, verifyMountain, verifyOnlyScrapers } from '../src/lib/verification';
import type { VerificationConfig } from '../src/lib/verification/types';

// ============================================================================
// CLI Argument Parsing
// ============================================================================

function parseArgs() {
  const args = process.argv.slice(2);
  const options: {
    type?: string;
    mountain?: string;
    quick?: boolean;
    help?: boolean;
  } = {};

  for (const arg of args) {
    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--quick' || arg === '-q') {
      options.quick = true;
    } else if (arg.startsWith('--type=')) {
      options.type = arg.split('=')[1];
    } else if (arg.startsWith('--mountain=')) {
      options.mountain = arg.split('=')[1];
    }
  }

  return options;
}

function printHelp() {
  console.log(`
📊 Data Source Verification Tool - Phase 1

Usage:
  npm run verify                    # Verify all sources
  npm run verify -- --type=scraper  # Verify only scrapers
  npm run verify -- --mountain=baker # Verify only Mt. Baker
  npm run verify -- --quick         # Quick test (Mt. Baker only)
  npm run verify -- --help          # Show this help

Options:
  --type=TYPE         Filter by source type (scraper, noaa, snotel, open-meteo, webcam)
  --mountain=ID       Filter by mountain ID (baker, stevens, crystal, etc.)
  --quick, -q         Quick verification of Mt. Baker only
  --help, -h          Show this help message

Examples:
  npm run verify -- --type=scraper
  npm run verify -- --mountain=baker
  npm run verify -- --type=noaa --mountain=stevens

Output:
  - JSON report saved to ./verification-reports/
  - Markdown summary saved to ./verification-reports/
  - Console summary with statistics
`);
}

// ============================================================================
// Main Function
// ============================================================================

async function main() {
  const options = parseArgs();

  if (options.help) {
    printHelp();
    process.exit(0);
  }

  try {
    // Build config
    const config: Partial<VerificationConfig> = {
      delayBetweenRequests: 1000,
      maxRetries: 3,
      timeout: 10000,
      staleDataThreshold: 48,
      saveToFile: true,
      outputDir: './verification-reports',
    };

    // Quick mode - just test Mt. Baker
    if (options.quick) {
      console.log('🚀 Running quick verification (Mt. Baker only)...\n');
      await verifyMountain('baker', config);
      process.exit(0);
    }

    // Type filter
    if (options.type) {
      const validTypes = ['scraper', 'noaa', 'snotel', 'open-meteo', 'webcam'];
      if (!validTypes.includes(options.type)) {
        console.error(`❌ Invalid type: ${options.type}`);
        console.error(`Valid types: ${validTypes.join(', ')}`);
        process.exit(1);
      }
      config.includeTypes = [options.type as any];
    }

    // Mountain filter
    if (options.mountain) {
      config.includeMountains = [options.mountain];
    }

    // Run verification
    console.log('🚀 Starting data source verification...\n');
    await runVerification(config);

    console.log('\n✅ Verification complete! Check ./verification-reports/ for detailed results.');
    process.exit(0);
  } catch (error: any) {
    console.error('\n❌ Verification failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run
main();
