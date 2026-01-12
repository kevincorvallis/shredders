/**
 * Service mocks for external APIs and dependencies
 * Mock SNOTEL, NOAA, Supabase, and other external services for testing
 */

import { vi } from 'vitest';
import { mockSnotelResponse, mockNoaaResponse, mockMountainStatus } from './fixtures';

/**
 * Mock global fetch for API calls
 */
export const mockFetch = vi.fn();

/**
 * Mock SNOTEL API calls
 */
export const mockSnotelAPI = {
  fetch: vi.fn().mockResolvedValue(mockSnotelResponse()),

  /**
   * Reset mocks between tests
   */
  reset: () => {
    mockSnotelAPI.fetch.mockClear();
    mockSnotelAPI.fetch.mockResolvedValue(mockSnotelResponse());
  },

  /**
   * Mock a failure response
   */
  mockFailure: (error: Error = new Error('SNOTEL API unavailable')) => {
    mockSnotelAPI.fetch.mockRejectedValue(error);
  },

  /**
   * Mock specific data
   */
  mockData: (data: any) => {
    mockSnotelAPI.fetch.mockResolvedValue(data);
  },
};

/**
 * Mock NOAA/NWS API calls
 */
export const mockNOAAAPI = {
  fetch: vi.fn().mockResolvedValue(mockNoaaResponse()),

  reset: () => {
    mockNOAAAPI.fetch.mockClear();
    mockNOAAAPI.fetch.mockResolvedValue(mockNoaaResponse());
  },

  mockFailure: (error: Error = new Error('NOAA API unavailable')) => {
    mockNOAAAPI.fetch.mockRejectedValue(error);
  },

  mockData: (data: any) => {
    mockNOAAAPI.fetch.mockResolvedValue(data);
  },
};

/**
 * Mock Supabase client
 */
export const mockSupabase = {
  from: vi.fn(() => ({
    select: vi.fn(() => ({
      eq: vi.fn(() => ({
        single: vi.fn().mockResolvedValue({ data: mockMountainStatus(), error: null }),
        data: [mockMountainStatus()],
        error: null,
      })),
      order: vi.fn(() => ({
        limit: vi.fn().mockResolvedValue({ data: [mockMountainStatus()], error: null }),
        data: [mockMountainStatus()],
        error: null,
      })),
      limit: vi.fn().mockResolvedValue({ data: [mockMountainStatus()], error: null }),
      data: [mockMountainStatus()],
      error: null,
    })),
    insert: vi.fn().mockResolvedValue({ data: mockMountainStatus(), error: null }),
    update: vi.fn(() => ({
      eq: vi.fn().mockResolvedValue({ data: mockMountainStatus(), error: null }),
    })),
    delete: vi.fn(() => ({
      eq: vi.fn().mockResolvedValue({ data: null, error: null }),
    })),
  })),

  auth: {
    getUser: vi.fn().mockResolvedValue({
      data: { user: { id: 'test-user-id', email: 'test@example.com' } },
      error: null,
    }),
    signInWithPassword: vi.fn().mockResolvedValue({
      data: { user: { id: 'test-user-id' }, session: { access_token: 'test-token' } },
      error: null,
    }),
  },

  storage: {
    from: vi.fn(() => ({
      upload: vi.fn().mockResolvedValue({
        data: { path: 'test-photo.jpg' },
        error: null,
      }),
      getPublicUrl: vi.fn().mockReturnValue({
        data: { publicUrl: 'https://example.com/test-photo.jpg' },
      }),
    })),
  },

  /**
   * Reset all mocks
   */
  reset: () => {
    mockSupabase.from.mockClear();
    mockSupabase.auth.getUser.mockClear();
    mockSupabase.auth.signInWithPassword.mockClear();
  },

  /**
   * Mock database query failure
   */
  mockQueryFailure: (error: Error = new Error('Database error')) => {
    mockSupabase.from.mockReturnValue({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          single: vi.fn().mockResolvedValue({ data: null, error }),
        })),
      })),
    } as any);
  },

  /**
   * Mock auth failure
   */
  mockAuthFailure: (error: Error = new Error('Unauthorized')) => {
    mockSupabase.auth.getUser.mockResolvedValue({
      data: { user: null },
      error,
    });
  },
};

/**
 * Mock OpenAI API for AI features
 */
export const mockOpenAI = {
  chat: {
    completions: {
      create: vi.fn().mockResolvedValue({
        choices: [
          {
            message: {
              content: JSON.stringify({
                arrivalTime: '8:00 AM',
                confidence: 'high',
                reasoning: 'Best conditions expected in the morning',
              }),
            },
          },
        ],
      }),
    },
  },

  reset: () => {
    mockOpenAI.chat.completions.create.mockClear();
  },

  mockFailure: (error: Error = new Error('OpenAI API error')) => {
    mockOpenAI.chat.completions.create.mockRejectedValue(error);
  },
};

/**
 * Setup all mocks for tests
 * Call this in beforeEach() or test setup
 */
export const setupMocks = () => {
  global.fetch = mockFetch.mockResolvedValue({
    ok: true,
    json: async () => ({}),
    text: async () => '',
  } as Response);

  mockSnotelAPI.reset();
  mockNOAAAPI.reset();
  mockSupabase.reset();
  mockOpenAI.reset();
};

/**
 * Reset all mocks after tests
 * Call this in afterEach()
 */
export const resetMocks = () => {
  vi.clearAllMocks();
  mockFetch.mockReset();
  mockSnotelAPI.reset();
  mockNOAAAPI.reset();
  mockSupabase.reset();
  mockOpenAI.reset();
};

/**
 * Mock environment variables for tests
 */
export const mockEnv = {
  SUPABASE_URL: 'https://test.supabase.co',
  SUPABASE_ANON_KEY: 'test-anon-key',
  SUPABASE_SERVICE_ROLE_KEY: 'test-service-key',
  OPENAI_API_KEY: 'test-openai-key',
  DATABASE_URL: 'postgresql://test:test@localhost:5432/test',
};

/**
 * Setup environment variables for tests
 */
export const setupTestEnv = () => {
  Object.assign(process.env, mockEnv);
};
