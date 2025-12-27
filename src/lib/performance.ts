/**
 * Performance monitoring utilities
 */

// Track page load time
export function measurePageLoad(pageName: string) {
  if (typeof window === 'undefined') return;

  const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
  if (navigation) {
    const loadTime = navigation.loadEventEnd - navigation.fetchStart;
    console.log(`[Performance] ${pageName} loaded in ${loadTime.toFixed(0)}ms`);
    return loadTime;
  }
}

// Track API call duration
export async function measureApiCall<T>(
  name: string,
  apiCall: () => Promise<T>
): Promise<T> {
  const start = performance.now();
  try {
    const result = await apiCall();
    const duration = performance.now() - start;
    console.log(`[Performance] API ${name} took ${duration.toFixed(0)}ms`);
    return result;
  } catch (error) {
    const duration = performance.now() - start;
    console.error(`[Performance] API ${name} failed after ${duration.toFixed(0)}ms`, error);
    throw error;
  }
}

// Track component render time
export function useRenderTime(componentName: string) {
  if (typeof window === 'undefined') return;

  const start = performance.now();
  return () => {
    const duration = performance.now() - start;
    console.log(`[Performance] ${componentName} rendered in ${duration.toFixed(2)}ms`);
  };
}

// Cache statistics
export interface CacheStats {
  hits: number;
  misses: number;
  hitRate: number;
}

class PerformanceMonitor {
  private apiCalls: Map<string, number[]> = new Map();
  private cacheHits = 0;
  private cacheMisses = 0;

  recordApiCall(endpoint: string, duration: number) {
    if (!this.apiCalls.has(endpoint)) {
      this.apiCalls.set(endpoint, []);
    }
    this.apiCalls.get(endpoint)!.push(duration);
  }

  recordCacheHit() {
    this.cacheHits++;
  }

  recordCacheMiss() {
    this.cacheMisses++;
  }

  getStats() {
    const stats: Record<string, any> = {
      cache: {
        hits: this.cacheHits,
        misses: this.cacheMisses,
        hitRate: this.cacheHits / (this.cacheHits + this.cacheMisses) || 0,
      },
      apis: {},
    };

    for (const [endpoint, durations] of this.apiCalls.entries()) {
      const avg = durations.reduce((a, b) => a + b, 0) / durations.length;
      const min = Math.min(...durations);
      const max = Math.max(...durations);

      stats.apis[endpoint] = {
        calls: durations.length,
        avg: avg.toFixed(0),
        min: min.toFixed(0),
        max: max.toFixed(0),
      };
    }

    return stats;
  }

  reset() {
    this.apiCalls.clear();
    this.cacheHits = 0;
    this.cacheMisses = 0;
  }
}

export const performanceMonitor = new PerformanceMonitor();

// Helper to log performance stats
export function logPerformanceStats() {
  const stats = performanceMonitor.getStats();
  console.log('[Performance Stats]', JSON.stringify(stats, null, 2));
  return stats;
}
