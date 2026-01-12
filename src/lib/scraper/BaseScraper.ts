import type { ScraperConfig, ScraperResult, ScrapedMountainStatus } from './types';

/**
 * Base scraper class inspired by Liftie
 * Provides common functionality for all resort scrapers
 */
export abstract class BaseScraper {
  protected config: ScraperConfig;

  constructor(config: ScraperConfig) {
    this.config = config;
  }

  /**
   * Main scrape method - to be implemented by each resort scraper
   */
  abstract scrape(): Promise<ScraperResult>;

  /**
   * Helper: Make HTTP request with timeout and error handling
   */
  protected async fetchWithTimeout(
    url: string,
    options: RequestInit = {},
    timeout = 30000  // Increased from 10000 to handle sequential scraping
  ): Promise<Response> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });
      clearTimeout(timeoutId);
      return response;
    } catch (error) {
      clearTimeout(timeoutId);
      throw error;
    }
  }

  /**
   * Helper: Extract number from string (e.g., "8/10" -> 8)
   */
  protected extractNumber(text: string | null | undefined): number {
    if (!text) return 0;
    const match = text.match(/(\d+)/);
    return match ? parseInt(match[1], 10) : 0;
  }

  /**
   * Helper: Extract percentage from string (e.g., "85%" -> 85)
   */
  protected extractPercentage(text: string | null | undefined): number | null {
    if (!text) return null;
    const match = text.match(/(\d+)%/);
    return match ? parseInt(match[1], 10) : null;
  }

  /**
   * Helper: Parse "X/Y" format (e.g., "8/10" -> { open: 8, total: 10 })
   */
  protected parseRatio(text: string | null | undefined): { open: number; total: number } {
    if (!text) return { open: 0, total: 0 };
    const match = text.match(/(\d+)\s*\/\s*(\d+)/);
    return match
      ? { open: parseInt(match[1], 10), total: parseInt(match[2], 10) }
      : { open: 0, total: 0 };
  }

  /**
   * Helper: Create result object
   */
  protected createResult(
    success: boolean,
    data?: ScrapedMountainStatus,
    error?: string,
    startTime?: number
  ): ScraperResult {
    return {
      success,
      data,
      error,
      timestamp: new Date().toISOString(),
      duration: startTime ? Date.now() - startTime : 0,
    };
  }

  /**
   * Helper: Create default status when scraping fails
   */
  protected createDefaultStatus(): ScrapedMountainStatus {
    return {
      mountainId: this.config.id,
      mountainName: this.config.name,
      isOpen: false,
      percentOpen: null,
      liftsOpen: 0,
      liftsClosed: 0,
      liftsTotal: 0,
      runsOpen: 0,
      runsClosed: 0,
      runsTotal: 0,
      acresOpen: null,
      acresTotal: null,
      lastUpdated: new Date().toISOString(),
      message: 'Data unavailable',
      source: this.config.url,
      dataUrl: this.config.dataUrl || this.config.url,
    };
  }

  /**
   * Validate scraper is enabled
   */
  isEnabled(): boolean {
    return this.config.enabled;
  }

  /**
   * Get scraper info
   */
  getInfo() {
    return {
      id: this.config.id,
      name: this.config.name,
      type: this.config.type,
      enabled: this.config.enabled,
    };
  }
}
