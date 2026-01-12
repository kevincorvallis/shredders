/**
 * Phase 1: Report Generator
 *
 * Generates comprehensive verification reports:
 * - JSON report with all verification results
 * - Human-readable markdown summary
 * - Recommendations organized by priority
 * - Error categorization and statistics
 * - Working vs broken sources summary
 */

import fs from 'fs';
import path from 'path';
import type {
  VerificationResult,
  VerificationReport,
  ErrorCategory,
} from './types';

// ============================================================================
// Report Generation Functions
// ============================================================================

export function generateReport(
  results: VerificationResult[]
): VerificationReport {
  const timestamp = new Date().toISOString();

  // Count statuses
  const successCount = results.filter((r) => r.status === 'success').length;
  const warningCount = results.filter((r) => r.status === 'warning').length;
  const errorCount = results.filter((r) => r.status === 'error').length;

  // Count by type
  const countByType = (type: VerificationResult['type']) => {
    const typeResults = results.filter((r) => r.type === type);
    return {
      total: typeResults.length,
      working: typeResults.filter((r) => r.status === 'success').length,
      broken: typeResults.filter((r) => r.status === 'error').length,
    };
  };

  // Count errors by category
  const errorsByCategory: Record<ErrorCategory, number> = {
    bot_protection: 0,
    invalid_selector: 0,
    dynamic_content: 0,
    http_error: 0,
    stale_data: 0,
    network_timeout: 0,
    validation_error: 0,
    missing_data: 0,
    api_error: 0,
    unknown: 0,
  };

  for (const result of results) {
    if (result.errorCategory) {
      errorsByCategory[result.errorCategory]++;
    }
  }

  // Generate recommendations
  const recommendations = generateRecommendations(results, errorsByCategory);

  const report: VerificationReport = {
    generatedAt: timestamp,
    totalSources: results.length,
    successCount,
    warningCount,
    errorCount,
    summary: {
      scrapers: countByType('scraper'),
      noaa: countByType('noaa'),
      snotel: countByType('snotel'),
      openMeteo: countByType('open-meteo'),
      webcams: countByType('webcam'),
    },
    results,
    recommendations,
    errorsByCategory,
  };

  return report;
}

function generateRecommendations(
  results: VerificationResult[],
  errorsByCategory: Record<ErrorCategory, number>
): VerificationReport['recommendations'] {
  const recommendations: VerificationReport['recommendations'] = [];

  // High priority: Bot protection blocking scrapers
  if (errorsByCategory.bot_protection > 0) {
    const affected = results
      .filter((r) => r.errorCategory === 'bot_protection')
      .map((r) => r.source);

    recommendations.push({
      category: 'Bot Protection',
      priority: 'high',
      affected,
      suggestion:
        'Consider implementing Puppeteer/Playwright for headless browser scraping, or look for official APIs as alternatives.',
    });
  }

  // High priority: Invalid selectors (scraper needs updating)
  if (errorsByCategory.invalid_selector > 0) {
    const affected = results
      .filter((r) => r.errorCategory === 'invalid_selector')
      .map((r) => r.source);

    recommendations.push({
      category: 'Invalid Selectors',
      priority: 'high',
      affected,
      suggestion:
        'CSS selectors need updating. Inspect the pages manually to find correct selectors or check if sites have been redesigned.',
    });
  }

  // Medium priority: Dynamic content requiring JS
  if (errorsByCategory.dynamic_content > 0) {
    const affected = results
      .filter((r) => r.errorCategory === 'dynamic_content')
      .map((r) => r.source);

    recommendations.push({
      category: 'Dynamic Content',
      priority: 'medium',
      affected,
      suggestion:
        'Switch scraper type to "dynamic" to use Puppeteer, or find API endpoints used by the frontend.',
    });
  }

  // Medium priority: API errors
  if (errorsByCategory.api_error > 0) {
    const affected = results
      .filter((r) => r.errorCategory === 'api_error')
      .map((r) => r.source);

    recommendations.push({
      category: 'API Errors',
      priority: 'medium',
      affected,
      suggestion:
        'Verify API endpoints and credentials. Check if APIs have been updated or deprecated.',
    });
  }

  // Medium priority: Stale data
  if (errorsByCategory.stale_data > 0) {
    const affected = results
      .filter((r) => r.errorCategory === 'stale_data')
      .map((r) => r.source);

    recommendations.push({
      category: 'Stale Data',
      priority: 'medium',
      affected,
      suggestion:
        'Data has not been updated recently. Check if stations/sources are operational.',
    });
  }

  // Low priority: HTTP errors (might be temporary)
  if (errorsByCategory.http_error > 0) {
    const affected = results
      .filter((r) => r.errorCategory === 'http_error')
      .map((r) => r.source);

    recommendations.push({
      category: 'HTTP Errors',
      priority: 'low',
      affected,
      suggestion:
        'URLs may have changed or servers may be temporarily down. Verify URLs are correct.',
    });
  }

  // Low priority: Network timeouts
  if (errorsByCategory.network_timeout > 0) {
    const affected = results
      .filter((r) => r.errorCategory === 'network_timeout')
      .map((r) => r.source);

    recommendations.push({
      category: 'Network Timeouts',
      priority: 'low',
      affected,
      suggestion:
        'Requests timed out. Consider increasing timeout configuration or check if sites are slow to respond.',
    });
  }

  return recommendations;
}

// ============================================================================
// Markdown Report Generation
// ============================================================================

export function generateMarkdownReport(report: VerificationReport): string {
  const lines: string[] = [];

  lines.push('# Data Source Verification Report');
  lines.push('');
  lines.push(`**Generated:** ${new Date(report.generatedAt).toLocaleString()}`);
  lines.push('');

  // Executive Summary
  lines.push('## Executive Summary');
  lines.push('');
  lines.push(`- **Total Sources Tested:** ${report.totalSources}`);
  lines.push(`- **✅ Working:** ${report.successCount} (${((report.successCount / report.totalSources) * 100).toFixed(1)}%)`);
  lines.push(`- **⚠️ Warning:** ${report.warningCount}`);
  lines.push(`- **❌ Broken:** ${report.errorCount} (${((report.errorCount / report.totalSources) * 100).toFixed(1)}%)`);
  lines.push('');

  // Breakdown by Source Type
  lines.push('## Breakdown by Source Type');
  lines.push('');

  const addTypeSection = (
    name: string,
    stats: { total: number; working: number; broken: number }
  ) => {
    if (stats.total === 0) return;

    const percentage = ((stats.working / stats.total) * 100).toFixed(1);
    lines.push(`### ${name}`);
    lines.push('');
    lines.push(`- Total: ${stats.total}`);
    lines.push(`- ✅ Working: ${stats.working} (${percentage}%)`);
    lines.push(`- ❌ Broken: ${stats.broken}`);
    lines.push('');
  };

  addTypeSection('Resort Scrapers', report.summary.scrapers);
  addTypeSection('NOAA Weather API', report.summary.noaa);
  addTypeSection('SNOTEL Stations', report.summary.snotel);
  addTypeSection('Open-Meteo API', report.summary.openMeteo);
  addTypeSection('Webcams', report.summary.webcams);

  // Errors by Category
  lines.push('## Error Categories');
  lines.push('');
  const errorEntries = Object.entries(report.errorsByCategory).filter(
    ([_, count]) => count > 0
  );

  if (errorEntries.length === 0) {
    lines.push('*No errors!*');
  } else {
    errorEntries
      .sort(([, a], [, b]) => b - a)
      .forEach(([category, count]) => {
        lines.push(`- **${category}:** ${count}`);
      });
  }
  lines.push('');

  // Recommendations
  lines.push('## Recommendations');
  lines.push('');

  if (report.recommendations.length === 0) {
    lines.push('*All sources working! No recommendations.*');
  } else {
    // Sort by priority
    const priorityOrder = { high: 0, medium: 1, low: 2 };
    const sortedRecs = [...report.recommendations].sort(
      (a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]
    );

    for (const rec of sortedRecs) {
      const icon =
        rec.priority === 'high' ? '🔴' : rec.priority === 'medium' ? '🟡' : '🟢';
      lines.push(`### ${icon} ${rec.category} (${rec.priority} priority)`);
      lines.push('');
      lines.push(`**Suggestion:** ${rec.suggestion}`);
      lines.push('');
      lines.push(`**Affected sources (${rec.affected.length}):**`);
      rec.affected.forEach((source) => {
        lines.push(`- ${source}`);
      });
      lines.push('');
    }
  }

  // Detailed Results
  lines.push('## Detailed Results');
  lines.push('');

  // Group by type
  const byType: Record<string, VerificationResult[]> = {};
  for (const result of report.results) {
    if (!byType[result.type]) {
      byType[result.type] = [];
    }
    byType[result.type].push(result);
  }

  for (const [type, results] of Object.entries(byType)) {
    lines.push(`### ${type.toUpperCase()}`);
    lines.push('');

    for (const result of results) {
      const icon = result.status === 'success' ? '✅' : result.status === 'warning' ? '⚠️' : '❌';
      lines.push(`#### ${icon} ${result.source}`);

      if (result.status === 'error') {
        lines.push(`- **Error:** ${result.errorMessage}`);
        lines.push(`- **Category:** ${result.errorCategory}`);
        if (result.recommendations && result.recommendations.length > 0) {
          lines.push(`- **Recommendations:**`);
          result.recommendations.forEach((rec) => {
            lines.push(`  - ${rec}`);
          });
        }
      } else {
        lines.push(`- **Status:** ${result.status}`);
        if (result.dataQuality) {
          lines.push(`- **Data Quality:** ${result.dataQuality}`);
        }
        if (result.responseTime) {
          lines.push(`- **Response Time:** ${result.responseTime}ms`);
        }
      }

      lines.push('');
    }
  }

  return lines.join('\n');
}

// ============================================================================
// File Output Functions
// ============================================================================

export async function saveReportToFile(
  report: VerificationReport,
  outputDir: string
): Promise<{ jsonPath: string; markdownPath: string }> {
  // Ensure output directory exists
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const timestamp = new Date()
    .toISOString()
    .replace(/[:.]/g, '-')
    .split('T')[0];

  // Save JSON report
  const jsonPath = path.join(outputDir, `verification-report-${timestamp}.json`);
  fs.writeFileSync(jsonPath, JSON.stringify(report, null, 2), 'utf-8');

  // Save Markdown report
  const markdown = generateMarkdownReport(report);
  const markdownPath = path.join(
    outputDir,
    `verification-report-${timestamp}.md`
  );
  fs.writeFileSync(markdownPath, markdown, 'utf-8');

  return { jsonPath, markdownPath };
}

export function printReportSummary(report: VerificationReport): void {
  console.log('\n' + '='.repeat(60));
  console.log('VERIFICATION REPORT SUMMARY');
  console.log('='.repeat(60));
  console.log(`\nTotal Sources: ${report.totalSources}`);
  console.log(`✅ Working: ${report.successCount} (${((report.successCount / report.totalSources) * 100).toFixed(1)}%)`);
  console.log(`⚠️  Warning: ${report.warningCount}`);
  console.log(`❌ Broken: ${report.errorCount} (${((report.errorCount / report.totalSources) * 100).toFixed(1)}%)`);

  console.log('\nBy Source Type:');
  console.log(`  Scrapers: ${report.summary.scrapers.working}/${report.summary.scrapers.total} working`);
  console.log(`  NOAA API: ${report.summary.noaa.working}/${report.summary.noaa.total} working`);
  console.log(`  SNOTEL: ${report.summary.snotel.working}/${report.summary.snotel.total} working`);
  console.log(`  Open-Meteo: ${report.summary.openMeteo.working}/${report.summary.openMeteo.total} working`);
  console.log(`  Webcams: ${report.summary.webcams.working}/${report.summary.webcams.total} working`);

  if (report.recommendations.length > 0) {
    console.log('\nTop Recommendations:');
    report.recommendations.slice(0, 3).forEach((rec) => {
      const icon = rec.priority === 'high' ? '🔴' : rec.priority === 'medium' ? '🟡' : '🟢';
      console.log(`  ${icon} ${rec.category}: ${rec.affected.length} sources`);
    });
  }

  console.log('\n' + '='.repeat(60) + '\n');
}
