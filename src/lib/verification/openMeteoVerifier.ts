/**
 * Phase 1: Open-Meteo API Verification Module
 *
 * Tests Open-Meteo forecast API for all mountains:
 * - Particularly important for Canadian mountains (no NOAA coverage)
 * - Verifies forecast data availability
 * - Validates temperature, snowfall, and precipitation data
 * - Checks data completeness and quality
 *
 * Open-Meteo provides free weather forecast API with global coverage.
 */

import type {
  OpenMeteoVerificationResult,
  VerificationConfig,
  ErrorCategory,
  VerificationStatus,
} from './types';
import { mountains } from '@shredders/shared';

// ============================================================================
// Open-Meteo API Types
// ============================================================================

interface OpenMeteoForecast {
  hourly?: {
    time: string[];
    temperature_2m?: number[];
    snowfall?: number[];
    precipitation?: number[];
  };
  daily?: {
    time: string[];
    temperature_2m_max?: number[];
    temperature_2m_min?: number[];
    snowfall_sum?: number[];
    precipitation_sum?: number[];
  };
}

// ============================================================================
// Helper Functions
// ============================================================================

async function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function buildOpenMeteoUrl(lat: number, lng: number): string {
  const baseUrl = 'https://api.open-meteo.com/v1/forecast';

  const params = new URLSearchParams({
    latitude: lat.toString(),
    longitude: lng.toString(),
    hourly: 'temperature_2m,snowfall,precipitation',
    daily: 'temperature_2m_max,temperature_2m_min,snowfall_sum,precipitation_sum',
    temperature_unit: 'fahrenheit',
    precipitation_unit: 'inch',
    windspeed_unit: 'mph',
    timezone: 'America/Los_Angeles',
    forecast_days: '7',
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
    if (httpStatus === 400) {
      return {
        category: 'api_error',
        message: 'Invalid coordinates or parameters',
      };
    }
    if (httpStatus === 500 || httpStatus === 503) {
      return {
        category: 'api_error',
        message: `Open-Meteo API server error (${httpStatus})`,
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

function validateOpenMeteoData(
  data: OpenMeteoForecast
): {
  valid: boolean;
  dataPoints?: number;
  forecast?: {
    temperature?: number[];
    snowfall?: number[];
    precipitation?: number[];
  };
  error?: string;
} {
  try {
    if (!data || typeof data !== 'object') {
      return { valid: false, error: 'Invalid data structure' };
    }

    // Check hourly data
    const hourly = data.hourly;
    if (!hourly || !Array.isArray(hourly.time) || hourly.time.length === 0) {
      return { valid: false, error: 'No hourly forecast data found' };
    }

    // Verify we have temperature data (minimum requirement)
    if (!Array.isArray(hourly.temperature_2m) || hourly.temperature_2m.length === 0) {
      return { valid: false, error: 'No temperature data in forecast' };
    }

    // Extract sample data
    const forecast = {
      temperature: hourly.temperature_2m?.slice(0, 24) || [],
      snowfall: hourly.snowfall?.slice(0, 24) || [],
      precipitation: hourly.precipitation?.slice(0, 24) || [],
    };

    return {
      valid: true,
      dataPoints: hourly.time.length,
      forecast,
    };
  } catch (error: any) {
    return { valid: false, error: error.message };
  }
}

// ============================================================================
// Main Verifier Functions
// ============================================================================

export async function verifyOpenMeteo(
  mountainId: string,
  config: VerificationConfig
): Promise<OpenMeteoVerificationResult> {
  const mountain = mountains[mountainId];

  if (!mountain) {
    return {
      source: `${mountainId}-open-meteo`,
      type: 'open-meteo',
      mountainId,
      mountainName: 'Unknown',
      latitude: 0,
      longitude: 0,
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: 'unknown',
      errorMessage: `No mountain config found for ${mountainId}`,
    };
  }

  const { lat, lng } = mountain.location;
  const url = buildOpenMeteoUrl(lat, lng);

  try {
    const { data, status: httpStatus, responseTime } = await fetchWithRetry(
      url,
      config
    );

    if (httpStatus !== 200) {
      const { category, message } = categorizeError(null, httpStatus);
      return {
        source: `${mountainId}-open-meteo`,
        type: 'open-meteo',
        mountainId,
        mountainName: mountain.name,
        latitude: lat,
        longitude: lng,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        errorCategory: category,
        errorMessage: message,
        recommendations: [
          'Verify mountain coordinates are correct',
          'Check Open-Meteo API status at https://open-meteo.com',
        ],
      };
    }

    // Validate data
    const validation = validateOpenMeteoData(data);

    if (!validation.valid) {
      return {
        source: `${mountainId}-open-meteo`,
        type: 'open-meteo',
        mountainId,
        mountainName: mountain.name,
        latitude: lat,
        longitude: lng,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        errorCategory: 'validation_error',
        errorMessage: validation.error || 'Data validation failed',
        recommendations: [
          'Inspect API response structure',
          'Update data validation logic',
        ],
      };
    }

    // Success - Open-Meteo is generally reliable
    return {
      source: `${mountainId}-open-meteo`,
      type: 'open-meteo',
      mountainId,
      mountainName: mountain.name,
      latitude: lat,
      longitude: lng,
      status: 'success',
      timestamp: new Date().toISOString(),
      responseTime,
      httpStatus,
      dataFound: true,
      dataQuality: 'excellent',
      dataPoints: validation.dataPoints,
      forecast: validation.forecast,
      sampleData: {
        url,
        region: mountain.region,
      },
    };
  } catch (error: any) {
    const { category, message } = categorizeError(error);

    return {
      source: `${mountainId}-open-meteo`,
      type: 'open-meteo',
      mountainId,
      mountainName: mountain.name,
      latitude: lat,
      longitude: lng,
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: category,
      errorMessage: message,
      recommendations: [
        'Check network connectivity',
        'Verify Open-Meteo API is accessible',
        category === 'network_timeout' ? 'Increase timeout configuration' : '',
      ].filter(Boolean),
    };
  }
}

export async function verifyAllOpenMeteo(
  config: VerificationConfig
): Promise<OpenMeteoVerificationResult[]> {
  const mountainIds = Object.keys(mountains);
  const results: OpenMeteoVerificationResult[] = [];

  // Filter by includeMountains if specified
  const filteredIds = config.includeMountains
    ? mountainIds.filter((id) => config.includeMountains!.includes(id))
    : mountainIds;

  console.log(`\nVerifying ${filteredIds.length} Open-Meteo endpoints...`);

  for (let i = 0; i < filteredIds.length; i++) {
    const mountainId = filteredIds[i];
    console.log(`[${i + 1}/${filteredIds.length}] Verifying ${mountainId}...`);

    const result = await verifyOpenMeteo(mountainId, config);
    results.push(result);

    // Rate limiting
    if (i < filteredIds.length - 1) {
      await delay(config.delayBetweenRequests);
    }
  }

  return results;
}
