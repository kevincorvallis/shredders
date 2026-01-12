/**
 * Phase 1: SNOTEL Verification Module
 *
 * Tests all SNOTEL (SNOwpack TELemetry) stations to verify:
 * - Station accessibility
 * - Data availability (snow depth, SWE, temperature)
 * - Data recency (freshness within 24-48 hours)
 * - Data quality and completeness
 *
 * SNOTEL stations provide critical snowpack data for mountain forecasting.
 */

import type {
  SNOTELVerificationResult,
  VerificationConfig,
  ErrorCategory,
  VerificationStatus,
} from './types';
import { mountains } from '@shredders/shared';

// ============================================================================
// SNOTEL API Types
// ============================================================================

interface SNOTELConfig {
  stationId: string;
  stationName: string;
}

interface SNOTELDataPoint {
  dateTime: string;
  value: number | null;
}

// ============================================================================
// Helper Functions
// ============================================================================

async function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function buildSNOTELUrl(stationId: string): string {
  // USDA NRCS SNOTEL API
  // Example: https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1/data
  // Query parameters:
  // - stationTriplets: station ID (e.g., "910:WA:SNTL")
  // - elements: WTEQ (Snow Water Equivalent), SNWD (Snow Depth), TOBS (Temperature)
  // - ordinal: 1 (current day)
  // - duration: DAILY

  const baseUrl = 'https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1/data';

  // Get multiple data elements in one request
  const elementsList = ['WTEQ', 'SNWD', 'TOBS']; // SWE, Snow Depth, Temperature
  const elementsParam = elementsList.join(',');

  const params = new URLSearchParams({
    stationTriplets: stationId,
    elements: elementsParam, // Correct parameter name is 'elements' not 'elementCd'
    ordinal: '1',
    duration: 'DAILY',
    getFlags: 'false',
    alwaysReturnDailyFeb29: 'false',
  });

  return `${baseUrl}?${params.toString()}`;
}

async function fetchWithRetry(
  url: string,
  config: VerificationConfig,
  attempt = 1
): Promise<{ data: any; status: number; responseTime: number }> {
  const startTime = Date.now();

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), config.timeout);

    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'PowderTracker (contact: app@powdertracker.com)',
        Accept: 'application/json',
      },
    });

    clearTimeout(timeoutId);

    const data = await response.json();
    const responseTime = Date.now() - startTime;

    return { data, status: response.status, responseTime };
  } catch (error: any) {
    if (attempt < config.maxRetries) {
      const retryDelay = config.retryDelay * Math.pow(2, attempt - 1);
      await delay(retryDelay);
      return fetchWithRetry(url, config, attempt + 1);
    }
    throw error;
  }
}

function categorizeError(
  error: any,
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
    return {
      category: 'unknown',
      message: 'Unknown error',
    };
  }

  if (error.name === 'AbortError' || error.message?.includes('timeout')) {
    return {
      category: 'network_timeout',
      message: 'Request timed out',
    };
  }

  if (httpStatus) {
    if (httpStatus === 404) {
      return {
        category: 'api_error',
        message: 'Station not found - Station ID may be invalid',
      };
    }
    if (httpStatus === 500 || httpStatus === 503) {
      return {
        category: 'api_error',
        message: `SNOTEL API server error (${httpStatus})`,
      };
    }
    if (httpStatus !== 200) {
      return {
        category: 'http_error',
        message: `HTTP ${httpStatus}`,
      };
    }
  }

  return {
    category: 'unknown',
    message: error.message || 'Unknown error',
  };
}

function validateSNOTELData(
  data: any,
  staleThreshold: number
): {
  valid: boolean;
  snowDepth?: number;
  snowWaterEquivalent?: number;
  dataRecency?: string;
  stale?: boolean;
  error?: string;
} {
  try {
    if (!Array.isArray(data) || data.length === 0) {
      return { valid: false, error: 'No data returned from SNOTEL API' };
    }

    // SNOTEL returns array with station data
    let snowDepth: number | undefined;
    let snowWaterEquivalent: number | undefined;
    let mostRecentDate: Date | undefined;

    // Iterate through each station (usually just one)
    for (const station of data) {
      if (!station.stationTriplet || !station.data || !Array.isArray(station.data)) {
        continue;
      }

      // Iterate through each element (SNWD, WTEQ, TOBS)
      for (const elementData of station.data) {
        if (!elementData.stationElement || !elementData.values || !Array.isArray(elementData.values)) {
          continue;
        }

        const elementCode = elementData.stationElement.elementCode;
        const values = elementData.values;

        if (values.length === 0) {
          continue;
        }

        // Get most recent data point
        const latest = values[values.length - 1];

        if (latest.date) {
          const date = new Date(latest.date);
          if (!mostRecentDate || date > mostRecentDate) {
            mostRecentDate = date;
          }
        }

        // Extract values based on element code
        if (elementCode === 'SNWD' && latest.value != null) {
          snowDepth = latest.value; // inches
        } else if (elementCode === 'WTEQ' && latest.value != null) {
          snowWaterEquivalent = latest.value; // inches
        }
      }
    }

    if (!mostRecentDate) {
      return { valid: false, error: 'No valid data timestamps found' };
    }

    // Check data staleness
    const hoursSinceUpdate =
      (Date.now() - mostRecentDate.getTime()) / (1000 * 60 * 60);
    const isStale = hoursSinceUpdate > staleThreshold;

    // At least one measurement should be present
    if (snowDepth === undefined && snowWaterEquivalent === undefined) {
      return {
        valid: false,
        error: 'No snow measurements found in response',
      };
    }

    return {
      valid: true,
      snowDepth,
      snowWaterEquivalent,
      dataRecency: mostRecentDate.toISOString(),
      stale: isStale,
    };
  } catch (error: any) {
    return { valid: false, error: error.message };
  }
}

// ============================================================================
// Main Verifier Functions
// ============================================================================

export async function verifySNOTEL(
  mountainId: string,
  config: VerificationConfig
): Promise<SNOTELVerificationResult> {
  const mountain = mountains[mountainId];

  if (!mountain) {
    return {
      source: `${mountainId}-snotel`,
      type: 'snotel',
      mountainId,
      mountainName: 'Unknown',
      stationId: 'unknown',
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: 'unknown',
      errorMessage: `No mountain config found for ${mountainId}`,
    };
  }

  if (!mountain.snotel) {
    return {
      source: `${mountainId}-snotel`,
      type: 'snotel',
      mountainId,
      mountainName: mountain.name,
      stationId: 'none',
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: 'missing_data',
      errorMessage: 'No SNOTEL configuration for this mountain',
      recommendations: ['Add SNOTEL station ID to mountain config'],
    };
  }

  const snotelConfig = mountain.snotel;
  const url = buildSNOTELUrl(snotelConfig.stationId);

  try {
    const { data, status: httpStatus, responseTime } = await fetchWithRetry(
      url,
      config
    );

    if (httpStatus !== 200) {
      const { category, message } = categorizeError(null, httpStatus);
      return {
        source: `${mountainId}-snotel`,
        type: 'snotel',
        mountainId,
        mountainName: mountain.name,
        stationId: snotelConfig.stationId,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        errorCategory: category,
        errorMessage: message,
        recommendations: [
          'Verify SNOTEL station ID is correct',
          'Check SNOTEL API status at https://wcc.sc.egov.usda.gov',
        ],
      };
    }

    // Validate data
    const validation = validateSNOTELData(data, config.staleDataThreshold);

    if (!validation.valid) {
      return {
        source: `${mountainId}-snotel`,
        type: 'snotel',
        mountainId,
        mountainName: mountain.name,
        stationId: snotelConfig.stationId,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        errorCategory: 'validation_error',
        errorMessage: validation.error || 'Data validation failed',
        recommendations: [
          'Inspect API response structure',
          'Check if station is operational',
        ],
      };
    }

    // Determine status
    const status: VerificationStatus = validation.stale ? 'warning' : 'success';

    return {
      source: `${mountainId}-snotel`,
      type: 'snotel',
      mountainId,
      mountainName: mountain.name,
      stationId: snotelConfig.stationId,
      status,
      timestamp: new Date().toISOString(),
      responseTime,
      httpStatus,
      dataFound: true,
      dataQuality: validation.stale ? 'fair' : 'excellent',
      snowDepth: validation.snowDepth,
      snowWaterEquivalent: validation.snowWaterEquivalent,
      dataRecency: validation.dataRecency,
      dataStale: validation.stale,
      sampleData: {
        url,
        stationName: snotelConfig.stationName,
      },
      recommendations: validation.stale
        ? [
            'Data is stale - station may be offline or experiencing issues',
            'Check SNOTEL station status manually',
          ]
        : [],
    };
  } catch (error: any) {
    const { category, message } = categorizeError(error);

    return {
      source: `${mountainId}-snotel`,
      type: 'snotel',
      mountainId,
      mountainName: mountain.name,
      stationId: snotelConfig.stationId,
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: category,
      errorMessage: message,
      recommendations: [
        'Check network connectivity',
        'Verify SNOTEL API is accessible',
        category === 'network_timeout' ? 'Increase timeout configuration' : '',
      ].filter(Boolean),
    };
  }
}

export async function verifyAllSNOTEL(
  config: VerificationConfig
): Promise<SNOTELVerificationResult[]> {
  const mountainIds = Object.keys(mountains);
  const results: SNOTELVerificationResult[] = [];

  // Filter by includeMountains if specified
  const filteredIds = config.includeMountains
    ? mountainIds.filter((id) => config.includeMountains!.includes(id))
    : mountainIds;

  console.log(`\nVerifying ${filteredIds.length} SNOTEL stations...`);

  for (let i = 0; i < filteredIds.length; i++) {
    const mountainId = filteredIds[i];
    console.log(`[${i + 1}/${filteredIds.length}] Verifying ${mountainId}...`);

    const result = await verifySNOTEL(mountainId, config);
    results.push(result);

    // Rate limiting
    if (i < filteredIds.length - 1) {
      await delay(config.delayBetweenRequests);
    }
  }

  return results;
}
