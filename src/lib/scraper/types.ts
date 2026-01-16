/**
 * Types for the mountain status scraping service
 * Inspired by Liftie architecture
 */

export interface ScrapedMountainStatus {
  mountainId: string;
  mountainName: string;
  isOpen: boolean;
  percentOpen: number | null;
  liftsOpen: number;
  liftsClosed: number;
  liftsTotal: number;
  runsOpen: number;
  runsClosed: number;
  runsTotal: number;
  acresOpen: number | null;
  acresTotal: number | null;
  lastUpdated: string;
  message?: string;
  source: string;
  dataUrl: string;
}

export interface ScraperConfig {
  id: string;
  name: string;
  url: string; // User-facing URL
  dataUrl?: string; // URL to scrape (if different from url)
  type: 'html' | 'api' | 'dynamic'; // Scraping method
  enabled: boolean;
  batch?: 1 | 2 | 3; // Batch number for distributed scraping (to avoid timeouts)
  selectors?: {
    // CSS selectors for HTML scraping
    liftsOpen?: string;
    liftsTotal?: string;
    runsOpen?: string;
    runsTotal?: string;
    percentOpen?: string;
    acresOpen?: string;
    status?: string;
    message?: string;

    // Regex patterns for text-based extraction (e.g., OnTheSnow)
    liftsPattern?: RegExp;
    runsPattern?: RegExp;
  };
  apiConfig?: {
    // Configuration for API-based scraping
    endpoint: string;
    method: 'GET' | 'POST';
    headers?: Record<string, string>;
    transform: (data: any) => Partial<ScrapedMountainStatus>;
  };
}

export interface ScraperResult {
  success: boolean;
  data?: ScrapedMountainStatus;
  error?: string;
  timestamp: string;
  duration: number; // milliseconds
}

export interface BaseScraper {
  config: ScraperConfig;
  scrape(): Promise<ScraperResult>;
}
