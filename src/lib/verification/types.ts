/**
 * Phase 1: Data Verification Agent - Type Definitions
 *
 * Defines interfaces for verifying all data sources:
 * - Resort scrapers
 * - NOAA Weather.gov APIs
 * - SNOTEL stations
 * - Open-Meteo APIs
 * - Webcams
 */

// ============================================================================
// Verification Result Types
// ============================================================================

export type VerificationStatus = 'success' | 'warning' | 'error';

export type ErrorCategory =
  | 'bot_protection'
  | 'invalid_selector'
  | 'dynamic_content'
  | 'http_error'
  | 'stale_data'
  | 'network_timeout'
  | 'validation_error'
  | 'missing_data'
  | 'api_error'
  | 'unknown';

export interface VerificationResult {
  source: string;
  type: 'scraper' | 'noaa' | 'snotel' | 'open-meteo' | 'webcam';
  status: VerificationStatus;
  timestamp: string;
  responseTime?: number;

  // Success details
  dataFound?: boolean;
  dataQuality?: 'excellent' | 'good' | 'fair' | 'poor';
  sampleData?: Record<string, any>;

  // Error details
  errorCategory?: ErrorCategory;
  errorMessage?: string;
  httpStatus?: number;

  // Additional metadata
  lastSuccessfulFetch?: string;
  recommendations?: string[];
}

// ============================================================================
// Scraper-Specific Types
// ============================================================================

export interface ScraperVerificationResult extends VerificationResult {
  type: 'scraper';
  mountainId: string;
  mountainName: string;

  // Selector validation
  selectorsFound?: {
    selector: string;
    found: boolean;
    value?: string;
  }[];

  // Data extraction
  extractedFields?: {
    field: string;
    value: any;
    valid: boolean;
  }[];
}

// ============================================================================
// API-Specific Types
// ============================================================================

export interface NOAAVerificationResult extends VerificationResult {
  type: 'noaa';
  mountainId: string;
  mountainName: string;
  endpoint: 'hourly' | 'daily' | 'observations' | 'alerts';
  stationId: string;

  dataPoints?: number;
  dataRecency?: string; // ISO timestamp of most recent data
  dataStale?: boolean;
}

export interface SNOTELVerificationResult extends VerificationResult {
  type: 'snotel';
  mountainId: string;
  mountainName: string;
  stationId: string;

  snowDepth?: number;
  snowWaterEquivalent?: number;
  dataRecency?: string;
  dataStale?: boolean;
}

export interface OpenMeteoVerificationResult extends VerificationResult {
  type: 'open-meteo';
  mountainId: string;
  mountainName: string;
  latitude: number;
  longitude: number;

  dataPoints?: number;
  forecast?: {
    temperature?: number[];
    snowfall?: number[];
    precipitation?: number[];
  };
}

export interface WebcamVerificationResult extends VerificationResult {
  type: 'webcam';
  mountainId: string;
  mountainName: string;
  webcamId: string;
  url: string;

  imageAccessible?: boolean;
  imageSize?: number;
  contentType?: string;
  lastModified?: string;
  staleness?: 'fresh' | 'moderate' | 'stale' | 'unknown';
}

// ============================================================================
// Report Types
// ============================================================================

export interface VerificationReport {
  generatedAt: string;
  totalSources: number;
  successCount: number;
  warningCount: number;
  errorCount: number;

  summary: {
    scrapers: { total: number; working: number; broken: number };
    noaa: { total: number; working: number; broken: number };
    snotel: { total: number; working: number; broken: number };
    openMeteo: { total: number; working: number; broken: number };
    webcams: { total: number; working: number; broken: number };
  };

  results: VerificationResult[];

  recommendations: {
    category: string;
    priority: 'high' | 'medium' | 'low';
    affected: string[];
    suggestion: string;
  }[];

  errorsByCategory: Record<ErrorCategory, number>;
}

// ============================================================================
// Configuration Types
// ============================================================================

export interface VerificationConfig {
  // Rate limiting
  delayBetweenRequests: number; // ms
  maxRetries: number;
  retryDelay: number; // ms
  timeout: number; // ms

  // Parallel execution
  maxConcurrent: number;

  // Data validation
  staleDataThreshold: number; // hours

  // Filters
  includeTypes?: ('scraper' | 'noaa' | 'snotel' | 'open-meteo' | 'webcam')[];
  includeMountains?: string[];

  // Output
  saveToFile?: boolean;
  outputDir?: string;
  saveToDB?: boolean;
}

export const DEFAULT_VERIFICATION_CONFIG: VerificationConfig = {
  delayBetweenRequests: 1000,
  maxRetries: 3,
  retryDelay: 1000,
  timeout: 10000,
  maxConcurrent: 5,
  staleDataThreshold: 48,
  saveToFile: true,
  outputDir: './verification-reports',
  saveToDB: false,
};
