/**
 * Phase 1: Scraper Verification Module
 *
 * Tests all resort scrapers to identify:
 * - Working scrapers with valid selectors
 * - Broken scrapers with categorized errors
 * - Bot protection issues (Cloudflare, Incapsula)
 * - Invalid or outdated CSS selectors
 * - Dynamic content requiring JavaScript
 *
 * UPDATED: Now uses actual scraper implementations (HTMLScraper) instead of
 * manually testing selectors. This ensures verification matches production behavior.
 */

import * as cheerio from 'cheerio';
import type {
  ScraperVerificationResult,
  VerificationConfig,
  ErrorCategory,
  VerificationStatus,
} from './types';
import { scraperConfigs } from '../scraper/configs';
import type { ScraperConfig } from '../scraper/types';
import { HTMLScraper } from '../scraper/HTMLScraper';

// ============================================================================
// Helper Functions
// ============================================================================

async function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function fetchWithRetry(
  url: string,
  config: VerificationConfig,
  attempt = 1
): Promise<{ html: string; status: number; responseTime: number }> {
  const startTime = Date.now();

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), config.timeout);

    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'no-cache',
        Pragma: 'no-cache',
      },
    });

    clearTimeout(timeoutId);

    const html = await response.text();
    const responseTime = Date.now() - startTime;

    return { html, status: response.status, responseTime };
  } catch (error: any) {
    if (attempt < config.maxRetries) {
      const retryDelay = config.retryDelay * Math.pow(2, attempt - 1); // Exponential backoff
      await delay(retryDelay);
      return fetchWithRetry(url, config, attempt + 1);
    }
    throw error;
  }
}

function categorizeError(
  error: any,
  html?: string,
  httpStatus?: number
): { category: ErrorCategory; message: string } {
  // Handle null/undefined error
  if (!error) {
    if (httpStatus && httpStatus !== 200) {
      return {
        category: 'http_error',
        message: `HTTP ${httpStatus}`,
      };
    }
    if (html) {
      // Check for bot protection even without error object
      if (
        html.includes('cloudflare') ||
        html.includes('cf-browser-verification') ||
        html.includes('Checking your browser')
      ) {
        return {
          category: 'bot_protection',
          message: 'Cloudflare bot protection detected',
        };
      }
      if (html.includes('incapsula') || html.includes('Incapsula incident ID')) {
        return {
          category: 'bot_protection',
          message: 'Incapsula bot protection detected',
        };
      }
    }
    return {
      category: 'unknown',
      message: 'Unknown error',
    };
  }

  // Network/timeout errors
  if (error.name === 'AbortError' || error.message?.includes('timeout')) {
    return {
      category: 'network_timeout',
      message: 'Request timed out',
    };
  }

  // HTTP errors
  if (httpStatus) {
    if (httpStatus === 403) {
      return {
        category: 'bot_protection',
        message: 'HTTP 403 Forbidden - Possible bot protection',
      };
    }
    if (httpStatus === 404) {
      return {
        category: 'http_error',
        message: 'HTTP 404 Not Found - URL may have changed',
      };
    }
    if (httpStatus >= 500) {
      return {
        category: 'http_error',
        message: `HTTP ${httpStatus} Server Error`,
      };
    }
  }

  // Bot protection detection
  if (html) {
    if (
      html.includes('cloudflare') ||
      html.includes('cf-browser-verification') ||
      html.includes('Checking your browser')
    ) {
      return {
        category: 'bot_protection',
        message: 'Cloudflare bot protection detected',
      };
    }
    if (html.includes('incapsula') || html.includes('Incapsula incident ID')) {
      return {
        category: 'bot_protection',
        message: 'Incapsula bot protection detected',
      };
    }
    if (
      html.includes('Access Denied') ||
      html.includes('access-denied') ||
      html.includes('security check')
    ) {
      return {
        category: 'bot_protection',
        message: 'Access denied - Possible bot protection',
      };
    }
  }

  // Dynamic content detection
  if (html && html.length < 1000 && html.includes('<script')) {
    return {
      category: 'dynamic_content',
      message: 'Minimal HTML with scripts - Likely client-side rendered',
    };
  }

  return {
    category: 'unknown',
    message: error.message || 'Unknown error',
  };
}

function testSelectors(
  $: cheerio.CheerioAPI,
  selectors: ScraperConfig['selectors']
): {
  selector: string;
  found: boolean;
  value?: string;
}[] {
  if (!selectors) return [];

  const results: {
    selector: string;
    found: boolean;
    value?: string;
  }[] = [];

  for (const [field, selector] of Object.entries(selectors)) {
    // Skip RegExp patterns - they're for text extraction, not CSS selection
    if (typeof selector !== 'string') {
      continue;
    }

    const elements = $(selector);
    const found = elements.length > 0;
    let value: string | undefined;

    if (found) {
      // Get first element's text or count if multiple
      if (elements.length === 1) {
        value = elements.first().text().trim();
      } else {
        value = `${elements.length} elements found`;
      }
    }

    results.push({
      selector: `${field}: ${selector}`,
      found,
      value,
    });
  }

  return results;
}

function assessDataQuality(
  selectorResults: {
    selector: string;
    found: boolean;
    value?: string;
  }[]
): 'excellent' | 'good' | 'fair' | 'poor' {
  const total = selectorResults.length;
  if (total === 0) return 'poor';

  const found = selectorResults.filter((r) => r.found).length;
  const percentage = (found / total) * 100;

  if (percentage >= 80) return 'excellent';
  if (percentage >= 60) return 'good';
  if (percentage >= 40) return 'fair';
  return 'poor';
}

// ============================================================================
// Main Verifier Functions
// ============================================================================

export async function verifyScraper(
  mountainId: string,
  config: VerificationConfig
): Promise<ScraperVerificationResult> {
  const scraperConfig = scraperConfigs[mountainId];

  if (!scraperConfig) {
    return {
      source: mountainId,
      type: 'scraper',
      mountainId,
      mountainName: 'Unknown',
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: 'unknown',
      errorMessage: `No scraper config found for ${mountainId}`,
      recommendations: ['Add scraper configuration for this mountain'],
    };
  }

  const startTime = Date.now();

  try {
    // Use the actual HTMLScraper implementation
    // This ensures verification matches production behavior including OnTheSnow JSON parser
    const scraper = new HTMLScraper(scraperConfig);
    const result = await scraper.scrape();

    const responseTime = Date.now() - startTime;

    if (result.success && result.data) {
      // Scraper successfully extracted data
      const data = result.data;

      // Assess data quality based on extracted fields
      const hasLifts = data.liftsTotal > 0;
      const hasRuns = data.runsTotal > 0;
      const hasStatus = data.isOpen !== undefined;

      let dataQuality: 'excellent' | 'good' | 'fair' | 'poor';
      if (hasLifts && hasRuns && hasStatus) {
        dataQuality = 'excellent';
      } else if ((hasLifts || hasRuns) && hasStatus) {
        dataQuality = 'good';
      } else if (hasLifts || hasRuns) {
        dataQuality = 'fair';
      } else {
        dataQuality = 'poor';
      }

      const status: VerificationStatus =
        dataQuality === 'excellent' || dataQuality === 'good' ? 'success' : 'warning';

      return {
        source: mountainId,
        type: 'scraper',
        mountainId,
        mountainName: scraperConfig.name,
        status,
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus: 200,
        dataFound: true,
        dataQuality,
        sampleData: {
          liftsOpen: data.liftsOpen,
          liftsTotal: data.liftsTotal,
          runsOpen: data.runsOpen,
          runsTotal: data.runsTotal,
          isOpen: data.isOpen,
          url: scraperConfig.dataUrl || scraperConfig.url,
        },
        recommendations:
          dataQuality === 'fair' || dataQuality === 'poor'
            ? ['Some data fields are missing', 'Review scraper configuration']
            : [],
      };
    } else {
      // Scraper failed
      const { category, message } = categorizeError(
        new Error(result.error || 'Scraper failed'),
        undefined,
        undefined
      );

      return {
        source: mountainId,
        type: 'scraper',
        mountainId,
        mountainName: scraperConfig.name,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        errorCategory: category,
        errorMessage: result.error || 'Scraper failed without error message',
        recommendations: getRecommendations(category, scraperConfig),
      };
    }
  } catch (error: any) {
    const responseTime = Date.now() - startTime;
    const { category, message } = categorizeError(error);

    return {
      source: mountainId,
      type: 'scraper',
      mountainId,
      mountainName: scraperConfig.name,
      status: 'error',
      timestamp: new Date().toISOString(),
      responseTime,
      errorCategory: category,
      errorMessage: message,
      recommendations: getRecommendations(category, scraperConfig),
    };
  }
}

function getRecommendations(
  errorCategory: ErrorCategory,
  config: ScraperConfig
): string[] {
  const recommendations: string[] = [];

  switch (errorCategory) {
    case 'bot_protection':
      recommendations.push(
        'Consider using Puppeteer/Playwright for headless browser scraping',
        'Add request delays and randomization',
        'Check if the resort offers an official API'
      );
      break;

    case 'dynamic_content':
      recommendations.push(
        'Switch to Puppeteer-based scraping',
        'Look for API endpoints used by the frontend',
        'Enable dynamic scraping in config'
      );
      if (config.type === 'html') {
        recommendations.push('Change scraper type from "html" to "dynamic"');
      }
      break;

    case 'invalid_selector':
      recommendations.push(
        'Inspect the page to find correct selectors',
        'Check if the site has been redesigned',
        'Update selector configuration'
      );
      break;

    case 'network_timeout':
      recommendations.push(
        'Increase timeout configuration',
        'Check if the site is down',
        'Verify network connectivity'
      );
      break;

    case 'http_error':
      recommendations.push(
        'Verify the URL is correct',
        'Check if the page has moved',
        'Inspect the site for URL changes'
      );
      break;

    default:
      recommendations.push('Investigate error manually', 'Check error logs');
  }

  return recommendations;
}

export async function verifyAllScrapers(
  config: VerificationConfig
): Promise<ScraperVerificationResult[]> {
  const mountainIds = Object.keys(scraperConfigs);
  const results: ScraperVerificationResult[] = [];

  // Filter by includeMountains if specified
  const filteredIds = config.includeMountains
    ? mountainIds.filter((id) => config.includeMountains!.includes(id))
    : mountainIds;

  console.log(`\nVerifying ${filteredIds.length} scrapers...`);

  // Process scrapers with rate limiting
  for (let i = 0; i < filteredIds.length; i++) {
    const mountainId = filteredIds[i];
    console.log(`[${i + 1}/${filteredIds.length}] Verifying ${mountainId}...`);

    const result = await verifyScraper(mountainId, config);
    results.push(result);

    // Rate limiting between requests
    if (i < filteredIds.length - 1) {
      await delay(config.delayBetweenRequests);
    }
  }

  return results;
}
