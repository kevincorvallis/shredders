/**
 * Simple in-memory cache for API responses
 * For production, consider using Redis or Vercel KV
 */

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  expiresAt: number;
}

class SimpleCache {
  private cache: Map<string, CacheEntry<any>> = new Map();
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor() {
    // Clean up expired entries every 5 minutes
    if (typeof window === 'undefined') {
      this.cleanupInterval = setInterval(() => this.cleanup(), 5 * 60 * 1000);
    }
  }

  get<T>(key: string): T | null {
    const entry = this.cache.get(key);

    if (!entry) {
      return null;
    }

    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }

    return entry.data as T;
  }

  /** Get entry even if expired (for stale-while-revalidate) */
  getStale<T>(key: string): { data: T; isStale: boolean } | null {
    const entry = this.cache.get(key);
    if (!entry) return null;

    return {
      data: entry.data as T,
      isStale: Date.now() > entry.expiresAt,
    };
  }

  set<T>(key: string, data: T, ttlSeconds: number = 600): void {
    const entry: CacheEntry<T> = {
      data,
      timestamp: Date.now(),
      expiresAt: Date.now() + ttlSeconds * 1000,
    };

    this.cache.set(key, entry);
  }

  delete(key: string): void {
    this.cache.delete(key);
  }

  clear(): void {
    this.cache.clear();
  }

  has(key: string): boolean {
    const entry = this.cache.get(key);
    if (!entry) return false;
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return false;
    }
    return true;
  }

  private cleanup(): void {
    const now = Date.now();
    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        this.cache.delete(key);
      }
    }
  }

  getStats() {
    return {
      size: this.cache.size,
      entries: Array.from(this.cache.keys()),
    };
  }
}

export const cache = new SimpleCache();

/**
 * Helper function to wrap API calls with caching.
 * Supports stale-while-revalidate: returns stale data immediately
 * while refreshing in the background.
 */
export async function withCache<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttlSeconds: number = 600
): Promise<T> {
  // Check fresh cache first
  const cached = cache.get<T>(key);
  if (cached !== null) {
    console.log(`[Cache HIT] ${key}`);
    return cached;
  }

  // Check for stale data we can serve while revalidating
  const stale = cache.getStale<T>(key);
  if (stale) {
    console.log(`[Cache STALE] ${key} - serving stale, revalidating in background`);
    // Revalidate in background (fire-and-forget)
    fetcher()
      .then((data) => cache.set(key, data, ttlSeconds))
      .catch((err) => console.error(`[Cache REVALIDATE ERROR] ${key}:`, err));
    return stale.data;
  }

  // Full cache miss - must fetch synchronously
  console.log(`[Cache MISS] ${key}`);
  const data = await fetcher();

  // Store in cache
  cache.set(key, data, ttlSeconds);

  return data;
}
