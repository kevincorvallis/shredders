/**
 * Test helper utilities
 * Common functions used across test files
 */

import { NextRequest, NextResponse } from 'next/server';
import { beforeAll, afterAll, vi } from 'vitest';

/**
 * Create a mock NextRequest for testing API routes
 */
export const createMockRequest = (
  url: string,
  options?: {
    method?: string;
    headers?: Record<string, string>;
    body?: any;
    searchParams?: Record<string, string>;
  }
): NextRequest => {
  const fullUrl = new URL(url, 'http://localhost:3000');

  // Add search params if provided
  if (options?.searchParams) {
    Object.entries(options.searchParams).forEach(([key, value]) => {
      fullUrl.searchParams.set(key, value);
    });
  }

  const requestInit: RequestInit = {
    method: options?.method || 'GET',
    headers: options?.headers || {},
  };

  if (options?.body) {
    requestInit.body = JSON.stringify(options.body);
    if (!requestInit.headers) requestInit.headers = {};
    (requestInit.headers as Record<string, string>)['Content-Type'] = 'application/json';
  }

  return new NextRequest(fullUrl, requestInit as any);
};

/**
 * Extract JSON from NextResponse for testing
 */
export const getResponseJSON = async <T = any>(response: NextResponse): Promise<T> => {
  const text = await response.text();
  return JSON.parse(text) as T;
};

/**
 * Wait for a promise with timeout
 * Useful for testing async operations
 */
export const waitFor = (ms: number): Promise<void> => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

/**
 * Assert response status code
 */
export const assertStatus = (response: NextResponse, expectedStatus: number) => {
  if (response.status !== expectedStatus) {
    throw new Error(
      `Expected status ${expectedStatus}, got ${response.status}. Body: ${JSON.stringify(response.body)}`
    );
  }
};

/**
 * Assert response contains expected data
 */
export const assertResponseContains = async (
  response: NextResponse,
  expectedData: Partial<any>
) => {
  const json = await getResponseJSON(response);

  Object.entries(expectedData).forEach(([key, value]) => {
    if (JSON.stringify(json[key]) !== JSON.stringify(value)) {
      throw new Error(
        `Expected ${key} to be ${JSON.stringify(value)}, got ${JSON.stringify(json[key])}`
      );
    }
  });
};

/**
 * Create mock context for route handlers with params
 */
export const createMockContext = <T = any>(params: T) => ({
  params: Promise.resolve(params),
});

/**
 * Date utilities for testing
 */
export const testDates = {
  /**
   * Get a date string in ISO format
   */
  getISODate: (daysFromNow: number = 0): string => {
    const date = new Date();
    date.setDate(date.getDate() + daysFromNow);
    return date.toISOString();
  },

  /**
   * Get a date string in YYYY-MM-DD format
   */
  getDateString: (daysFromNow: number = 0): string => {
    const date = new Date();
    date.setDate(date.getDate() + daysFromNow);
    return date.toISOString().split('T')[0];
  },

  /**
   * Check if two dates are within tolerance (milliseconds)
   */
  areDatesClose: (date1: string, date2: string, toleranceMs: number = 1000): boolean => {
    const d1 = new Date(date1).getTime();
    const d2 = new Date(date2).getTime();
    return Math.abs(d1 - d2) <= toleranceMs;
  },
};

/**
 * Mock console methods for testing
 * Useful to suppress expected console errors in tests
 */
export const suppressConsole = () => {
  const originalConsole = {
    log: console.log,
    error: console.error,
    warn: console.warn,
  };

  beforeAll(() => {
    console.log = vi.fn();
    console.error = vi.fn();
    console.warn = vi.fn();
  });

  afterAll(() => {
    console.log = originalConsole.log;
    console.error = originalConsole.error;
    console.warn = originalConsole.warn;
  });

  return originalConsole;
};

/**
 * Validate API response schema
 */
export const validateResponseSchema = <T>(
  data: any,
  requiredFields: (keyof T)[]
): data is T => {
  return requiredFields.every((field) => field in data);
};

/**
 * Generate random test data
 */
export const randomTestData = {
  /**
   * Random number between min and max
   */
  number: (min: number, max: number): number => {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  },

  /**
   * Random string of specified length
   */
  string: (length: number = 10): string => {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  },

  /**
   * Random email address
   */
  email: (): string => {
    return `test-${randomTestData.string(8)}@example.com`;
  },

  /**
   * Random boolean
   */
  boolean: (): boolean => {
    return Math.random() > 0.5;
  },
};
