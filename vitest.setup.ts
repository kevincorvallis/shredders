// Vitest setup file
import { beforeAll, afterEach, afterAll } from 'vitest';

// Setup test environment variables
beforeAll(() => {
  // NODE_ENV is automatically set to 'test' by Vitest
  process.env.NEXT_PUBLIC_API_URL = 'http://localhost:3000';
  process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://test.supabase.co';
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = 'test-anon-key';
});

// Clean up after each test
afterEach(() => {
  // Reset any test-specific state
});

afterAll(() => {
  // Cleanup
});
