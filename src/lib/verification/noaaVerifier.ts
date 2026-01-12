/**
 * Phase 1: NOAA Weather.gov API Verification Module
 *
 * Tests all NOAA Weather.gov API endpoints:
 * - Hourly forecast (7-day hourly)
 * - Daily forecast (7-day)
 * - Observations (current conditions)
 * - Weather alerts
 *
 * Each mountain has 4 endpoints = 17 mountains × 4 = 68 endpoints total
 */

import type {
  NOAAVerificationResult,
  VerificationConfig,
  ErrorCategory,
  VerificationStatus,
} from './types';
import { mountains } from '@shredders/shared';

// ============================================================================
// NOAA API Types
// ============================================================================

type NOAAEndpointType = 'hourly' | 'daily' | 'observations' | 'alerts';

interface NOAAConfig {
  gridOffice: string;
  gridX: number;
  gridY: number;
}

// ============================================================================
// Helper Functions
// ============================================================================

async function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function buildNOAAUrl(
  config: NOAAConfig,
  endpoint: NOAAEndpointType,
  location?: { lat: number; lng: number }
): string {
  const { gridOffice, gridX, gridY } = config;
  const baseUrl = 'https://api.weather.gov';

  switch (endpoint) {
    case 'hourly':
      return `${baseUrl}/gridpoints/${gridOffice}/${gridX},${gridY}/forecast/hourly`;
    case 'daily':
      return `${baseUrl}/gridpoints/${gridOffice}/${gridX},${gridY}/forecast`;
    case 'observations':
      // Get latest observation - Note: observations endpoint requires station ID
      // We'll use the gridpoint to get the nearest station first
      return `${baseUrl}/gridpoints/${gridOffice}/${gridX},${gridY}/stations`;
    case 'alerts':
      // Get active alerts using lat/lng coordinates (NOT grid coordinates)
      if (!location) {
        throw new Error('Location required for alerts endpoint');
      }
      return `${baseUrl}/alerts/active?point=${location.lat},${location.lng}`;
    default:
      throw new Error(`Unknown endpoint type: ${endpoint}`);
  }
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
        Accept: 'application/geo+json',
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
        message: 'API endpoint not found - Grid coordinates may be invalid',
      };
    }
    if (httpStatus === 500 || httpStatus === 503) {
      return {
        category: 'api_error',
        message: httpStatus === 503
          ? 'NOAA upstream data source temporarily unavailable - Service issue, not a configuration problem'
          : `NOAA API server error (${httpStatus})`,
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

function validateNOAAData(
  data: any,
  endpoint: NOAAEndpointType,
  staleThreshold: number
): {
  valid: boolean;
  dataPoints?: number;
  dataRecency?: string;
  stale?: boolean;
  error?: string;
} {
  try {
    if (!data || typeof data !== 'object') {
      return { valid: false, error: 'Invalid data structure' };
    }

    switch (endpoint) {
      case 'hourly':
      case 'daily': {
        const periods = data.properties?.periods;
        if (!Array.isArray(periods) || periods.length === 0) {
          return { valid: false, error: 'No forecast periods found' };
        }

        // Check if data has required fields
        const firstPeriod = periods[0];
        if (!firstPeriod.temperature || !firstPeriod.startTime) {
          return { valid: false, error: 'Missing required forecast fields' };
        }

        // Check data recency
        const updateTime = new Date(data.properties?.updateTime || periods[0].startTime);
        const hoursSinceUpdate =
          (Date.now() - updateTime.getTime()) / (1000 * 60 * 60);
        const isStale = hoursSinceUpdate > staleThreshold;

        return {
          valid: true,
          dataPoints: periods.length,
          dataRecency: updateTime.toISOString(),
          stale: isStale,
        };
      }

      case 'observations': {
        // This endpoint returns station list, not observations
        const stations = data.features;
        if (!Array.isArray(stations) || stations.length === 0) {
          return { valid: false, error: 'No weather stations found' };
        }

        return {
          valid: true,
          dataPoints: stations.length,
        };
      }

      case 'alerts': {
        const features = data.features;
        if (!Array.isArray(features)) {
          return { valid: false, error: 'Invalid alerts structure' };
        }

        // Alerts can be empty (no active alerts) - that's valid
        return {
          valid: true,
          dataPoints: features.length,
        };
      }

      default:
        return { valid: false, error: 'Unknown endpoint type' };
    }
  } catch (error: any) {
    return { valid: false, error: error.message };
  }
}

// ============================================================================
// Main Verifier Functions
// ============================================================================

export async function verifyNOAAEndpoint(
  mountainId: string,
  endpoint: NOAAEndpointType,
  config: VerificationConfig
): Promise<NOAAVerificationResult> {
  const mountain = mountains[mountainId];

  if (!mountain) {
    return {
      source: `${mountainId}-noaa-${endpoint}`,
      type: 'noaa',
      mountainId,
      mountainName: 'Unknown',
      endpoint,
      stationId: 'unknown',
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: 'unknown',
      errorMessage: `No mountain config found for ${mountainId}`,
    };
  }

  if (!mountain.noaa) {
    return {
      source: `${mountainId}-noaa-${endpoint}`,
      type: 'noaa',
      mountainId,
      mountainName: mountain.name,
      endpoint,
      stationId: 'none',
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: 'missing_data',
      errorMessage: 'No NOAA configuration for this mountain',
      recommendations: ['Add NOAA grid coordinates to mountain config'],
    };
  }

  const noaaConfig = mountain.noaa;
  const stationId = `${noaaConfig.gridOffice}/${noaaConfig.gridX},${noaaConfig.gridY}`;
  const url = buildNOAAUrl(noaaConfig, endpoint, mountain.location);

  try {
    const { data, status: httpStatus, responseTime } = await fetchWithRetry(
      url,
      config
    );

    if (httpStatus !== 200) {
      const { category, message } = categorizeError(null, httpStatus);
      return {
        source: `${mountainId}-noaa-${endpoint}`,
        type: 'noaa',
        mountainId,
        mountainName: mountain.name,
        endpoint,
        stationId,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        errorCategory: category,
        errorMessage: message,
        recommendations: [
          'Verify NOAA grid coordinates are correct',
          'Check NOAA API status at https://api.weather.gov',
        ],
      };
    }

    // Validate data
    const validation = validateNOAAData(
      data,
      endpoint,
      config.staleDataThreshold
    );

    if (!validation.valid) {
      return {
        source: `${mountainId}-noaa-${endpoint}`,
        type: 'noaa',
        mountainId,
        mountainName: mountain.name,
        endpoint,
        stationId,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        errorCategory: 'validation_error',
        errorMessage: validation.error || 'Data validation failed',
        recommendations: ['Inspect API response structure', 'Update data validation logic'],
      };
    }

    // Determine status
    const status: VerificationStatus = validation.stale ? 'warning' : 'success';

    return {
      source: `${mountainId}-noaa-${endpoint}`,
      type: 'noaa',
      mountainId,
      mountainName: mountain.name,
      endpoint,
      stationId,
      status,
      timestamp: new Date().toISOString(),
      responseTime,
      httpStatus,
      dataFound: true,
      dataQuality: validation.stale ? 'fair' : 'excellent',
      dataPoints: validation.dataPoints,
      dataRecency: validation.dataRecency,
      dataStale: validation.stale,
      sampleData: {
        url,
        gridOffice: noaaConfig.gridOffice,
        gridX: noaaConfig.gridX,
        gridY: noaaConfig.gridY,
      },
      recommendations: validation.stale
        ? ['Data is stale - may need to check NOAA API status']
        : [],
    };
  } catch (error: any) {
    const { category, message } = categorizeError(error);

    return {
      source: `${mountainId}-noaa-${endpoint}`,
      type: 'noaa',
      mountainId,
      mountainName: mountain.name,
      endpoint,
      stationId,
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: category,
      errorMessage: message,
      recommendations: [
        'Check network connectivity',
        'Verify NOAA API is accessible',
        category === 'network_timeout' ? 'Increase timeout configuration' : '',
      ].filter(Boolean),
    };
  }
}

export async function verifyAllNOAA(
  config: VerificationConfig
): Promise<NOAAVerificationResult[]> {
  const mountainIds = Object.keys(mountains);
  const endpoints: NOAAEndpointType[] = ['hourly', 'daily', 'observations', 'alerts'];
  const results: NOAAVerificationResult[] = [];

  // Filter by includeMountains if specified
  const filteredIds = config.includeMountains
    ? mountainIds.filter((id) => config.includeMountains!.includes(id))
    : mountainIds;

  // Calculate total endpoints
  const totalEndpoints = filteredIds.length * endpoints.length;
  console.log(`\nVerifying ${totalEndpoints} NOAA endpoints (${filteredIds.length} mountains × ${endpoints.length} endpoints)...`);

  let count = 0;
  for (const mountainId of filteredIds) {
    for (const endpoint of endpoints) {
      count++;
      console.log(`[${count}/${totalEndpoints}] Verifying ${mountainId} - ${endpoint}...`);

      const result = await verifyNOAAEndpoint(mountainId, endpoint, config);
      results.push(result);

      // Rate limiting
      if (count < totalEndpoints) {
        await delay(config.delayBetweenRequests);
      }
    }
  }

  return results;
}
