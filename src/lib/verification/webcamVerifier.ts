/**
 * Phase 1: Webcam Verification Module
 *
 * Tests all webcam URLs to verify:
 * - Image accessibility (200 OK)
 * - Image staleness (Last-Modified header)
 * - Valid image format (Content-Type)
 * - Reasonable file size
 * - Broken or moved webcams
 *
 * Many mountain webcams have moved to dynamic systems - this verifier
 * helps identify which static URLs are still working.
 */

import type {
  WebcamVerificationResult,
  VerificationConfig,
  ErrorCategory,
  VerificationStatus,
} from './types';
import { mountains } from '@shredders/shared';

// ============================================================================
// Helper Functions
// ============================================================================

async function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function fetchWebcamWithRetry(
  url: string,
  config: VerificationConfig,
  attempt = 1
): Promise<{
  status: number;
  contentType: string;
  contentLength: number;
  lastModified?: string;
  responseTime: number;
}> {
  const startTime = Date.now();

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), config.timeout);

    const response = await fetch(url, {
      method: 'HEAD', // Use HEAD to avoid downloading full image
      signal: controller.signal,
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        Accept: 'image/*',
      },
    });

    clearTimeout(timeoutId);

    const contentType = response.headers.get('content-type') || '';
    const contentLength = parseInt(
      response.headers.get('content-length') || '0',
      10
    );
    const lastModified = response.headers.get('last-modified') || undefined;
    const responseTime = Date.now() - startTime;

    return {
      status: response.status,
      contentType,
      contentLength,
      lastModified,
      responseTime,
    };
  } catch (error: any) {
    if (attempt < config.maxRetries) {
      const retryDelay = config.retryDelay * Math.pow(2, attempt - 1);
      await delay(retryDelay);
      return fetchWebcamWithRetry(url, config, attempt + 1);
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
    if (httpStatus === 403) {
      return {
        category: 'bot_protection',
        message: 'HTTP 403 Forbidden - May require referrer or authentication',
      };
    }
    if (httpStatus === 404) {
      return {
        category: 'http_error',
        message: 'HTTP 404 Not Found - Webcam URL may have changed',
      };
    }
    if (httpStatus >= 500) {
      return {
        category: 'http_error',
        message: `HTTP ${httpStatus} Server Error`,
      };
    }
  }

  return {
    category: 'unknown',
    message: error.message || 'Unknown error',
  };
}

function assessStaleness(
  lastModified?: string,
  staleThreshold: number = 48
): 'fresh' | 'moderate' | 'stale' | 'unknown' {
  if (!lastModified) {
    return 'unknown';
  }

  try {
    const modifiedDate = new Date(lastModified);
    const hoursSinceUpdate = (Date.now() - modifiedDate.getTime()) / (1000 * 60 * 60);

    if (hoursSinceUpdate <= 6) return 'fresh'; // Updated within 6 hours
    if (hoursSinceUpdate <= 24) return 'moderate'; // Updated within 24 hours
    if (hoursSinceUpdate <= staleThreshold) return 'moderate'; // Within threshold
    return 'stale'; // Older than threshold
  } catch {
    return 'unknown';
  }
}

function isValidImageType(contentType: string): boolean {
  const validTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'binary/octet-stream', // Generic binary (Whistler webcams)
    'application/octet-stream', // Generic binary stream
  ];
  return validTypes.some((type) => contentType.toLowerCase().includes(type));
}

// ============================================================================
// Main Verifier Functions
// ============================================================================

export async function verifyWebcam(
  mountainId: string,
  webcamId: string,
  config: VerificationConfig
): Promise<WebcamVerificationResult> {
  const mountain = mountains[mountainId];

  if (!mountain) {
    return {
      source: `${mountainId}-webcam-${webcamId}`,
      type: 'webcam',
      mountainId,
      mountainName: 'Unknown',
      webcamId,
      url: '',
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: 'unknown',
      errorMessage: `No mountain config found for ${mountainId}`,
    };
  }

  // Find webcam in both webcams and roadWebcams arrays
  const webcam =
    mountain.webcams?.find((w) => w.id === webcamId) ||
    mountain.roadWebcams?.find((w) => w.id === webcamId);

  if (!webcam) {
    return {
      source: `${mountainId}-webcam-${webcamId}`,
      type: 'webcam',
      mountainId,
      mountainName: mountain.name,
      webcamId,
      url: '',
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: 'missing_data',
      errorMessage: `No webcam found with ID ${webcamId}`,
      recommendations: ['Verify webcam ID is correct in mountain config'],
    };
  }

  const url = webcam.url;

  try {
    const {
      status: httpStatus,
      contentType,
      contentLength,
      lastModified,
      responseTime,
    } = await fetchWebcamWithRetry(url, config);

    // Check HTTP status
    if (httpStatus !== 200) {
      const { category, message } = categorizeError(null, httpStatus);
      return {
        source: `${mountainId}-webcam-${webcamId}`,
        type: 'webcam',
        mountainId,
        mountainName: mountain.name,
        webcamId,
        url,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        errorCategory: category,
        errorMessage: message,
        recommendations: [
          'Check if webcam URL has changed',
          'Verify webcam is still operational',
          'Consider switching to dynamic webcam system',
        ],
      };
    }

    // Validate image type
    if (!isValidImageType(contentType)) {
      return {
        source: `${mountainId}-webcam-${webcamId}`,
        type: 'webcam',
        mountainId,
        mountainName: mountain.name,
        webcamId,
        url,
        status: 'error',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        contentType,
        errorCategory: 'validation_error',
        errorMessage: `Invalid content type: ${contentType} (expected image)`,
        recommendations: [
          'Verify URL points to an image file',
          'Check if endpoint returns HTML instead of image',
        ],
      };
    }

    // Check file size (too small = likely placeholder, too large = might be issue)
    const imageSize = contentLength;
    if (imageSize < 1000) {
      // Less than 1KB is suspicious
      return {
        source: `${mountainId}-webcam-${webcamId}`,
        type: 'webcam',
        mountainId,
        mountainName: mountain.name,
        webcamId,
        url,
        status: 'warning',
        timestamp: new Date().toISOString(),
        responseTime,
        httpStatus,
        contentType,
        imageSize,
        imageAccessible: true,
        errorCategory: 'validation_error',
        errorMessage: 'Image size suspiciously small - may be placeholder',
        recommendations: [
          'Manually verify image is not a placeholder',
          'Check if webcam is actually updating',
        ],
      };
    }

    // Assess staleness
    const staleness = assessStaleness(lastModified, config.staleDataThreshold);

    // Determine overall status
    let status: VerificationStatus = 'success';
    const recommendations: string[] = [];

    if (staleness === 'stale') {
      status = 'warning';
      recommendations.push(
        'Image has not been updated recently',
        'Webcam may be offline or stuck'
      );
    } else if (staleness === 'unknown') {
      recommendations.push('No Last-Modified header - cannot verify freshness');
    }

    return {
      source: `${mountainId}-webcam-${webcamId}`,
      type: 'webcam',
      mountainId,
      mountainName: mountain.name,
      webcamId,
      url,
      status,
      timestamp: new Date().toISOString(),
      responseTime,
      httpStatus,
      dataFound: true,
      dataQuality:
        staleness === 'fresh'
          ? 'excellent'
          : staleness === 'moderate'
          ? 'good'
          : staleness === 'stale'
          ? 'poor'
          : 'fair',
      imageAccessible: true,
      imageSize,
      contentType,
      lastModified,
      staleness,
      sampleData: {
        webcamName: webcam.name,
        refreshUrl: (webcam as any).refreshUrl,
      },
      recommendations,
    };
  } catch (error: any) {
    const { category, message } = categorizeError(error);

    return {
      source: `${mountainId}-webcam-${webcamId}`,
      type: 'webcam',
      mountainId,
      mountainName: mountain.name,
      webcamId,
      url,
      status: 'error',
      timestamp: new Date().toISOString(),
      errorCategory: category,
      errorMessage: message,
      recommendations: [
        'Check network connectivity',
        'Verify webcam URL is accessible',
        category === 'network_timeout' ? 'Increase timeout configuration' : '',
      ].filter(Boolean),
    };
  }
}

export async function verifyAllWebcams(
  config: VerificationConfig
): Promise<WebcamVerificationResult[]> {
  const mountainIds = Object.keys(mountains);
  const results: WebcamVerificationResult[] = [];

  // Filter by includeMountains if specified
  const filteredIds = config.includeMountains
    ? mountainIds.filter((id) => config.includeMountains!.includes(id))
    : mountainIds;

  // Count total webcams
  let totalWebcams = 0;
  for (const mountainId of filteredIds) {
    const mountain = mountains[mountainId];
    totalWebcams += (mountain.webcams?.length || 0) + (mountain.roadWebcams?.length || 0);
  }

  console.log(`\nVerifying ${totalWebcams} webcams across ${filteredIds.length} mountains...`);

  let count = 0;
  for (const mountainId of filteredIds) {
    const mountain = mountains[mountainId];

    // Verify regular webcams
    if (mountain.webcams) {
      for (const webcam of mountain.webcams) {
        count++;
        console.log(
          `[${count}/${totalWebcams}] Verifying ${mountainId} - ${webcam.name}...`
        );

        const result = await verifyWebcam(mountainId, webcam.id, config);
        results.push(result);

        if (count < totalWebcams) {
          await delay(config.delayBetweenRequests);
        }
      }
    }

    // Verify road webcams
    if (mountain.roadWebcams) {
      for (const webcam of mountain.roadWebcams) {
        count++;
        console.log(
          `[${count}/${totalWebcams}] Verifying ${mountainId} - ${webcam.name}...`
        );

        const result = await verifyWebcam(mountainId, webcam.id, config);
        results.push(result);

        if (count < totalWebcams) {
          await delay(config.delayBetweenRequests);
        }
      }
    }
  }

  return results;
}
