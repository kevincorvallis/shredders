/**
 * API Tests for Event Activity Endpoints
 *
 * Tests cover:
 * - GET /api/events/[id]/activity
 *
 * NOTE: These are integration tests that require a running server.
 * Set TEST_API_URL environment variable or run `npm run dev` first.
 */

import { describe, it, expect, beforeAll } from 'vitest';

const API_BASE_URL = process.env.TEST_API_URL || 'http://localhost:3000';

const TEST_EVENT_ID = process.env.TEST_EVENT_ID || 'test-event-id';
const TEST_AUTH_TOKEN = process.env.TEST_AUTH_TOKEN || 'test-token';
const TEST_RSVP_AUTH_TOKEN = process.env.TEST_RSVP_AUTH_TOKEN || 'test-rsvp-token';

// Check if server is reachable before running integration tests
async function isServerReachable(): Promise<boolean> {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 2000);
    const response = await fetch(`${API_BASE_URL}/api/events`, {
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    return response.status !== undefined;
  } catch {
    return false;
  }
}

describe('Event Activity API', () => {
  let serverAvailable = false;

  beforeAll(async () => {
    serverAvailable = await isServerReachable();
    if (!serverAvailable) {
      console.warn(
        `⚠️  Skipping Event Activity API tests: Server not reachable at ${API_BASE_URL}`
      );
    }
  });

  describe('GET /api/events/[id]/activity', () => {
    it('should return 401 without authentication', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/activity`
      );

      expect(response.status).toBe(401);
      const data = await response.json();
      expect(data.error).toBeDefined();
    });

    it('should return gated response for non-RSVP user', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/activity`,
        {
          headers: {
            Authorization: `Bearer ${TEST_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.gated).toBe(true);
      expect(data.message).toBeDefined();
    });

    it('should return activities for RSVP user', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/activity`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.gated).toBe(false);
      expect(Array.isArray(data.activities)).toBe(true);
    });

    it('should support pagination', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/activity?limit=10&offset=0`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.pagination).toBeDefined();
      expect(data.pagination.limit).toBe(10);
      expect(data.pagination.offset).toBe(0);
      expect(typeof data.pagination.hasMore).toBe('boolean');
    });

    it('should return activities sorted by most recent first', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/activity`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();

      if (data.activities.length >= 2) {
        const firstDate = new Date(data.activities[0].createdAt);
        const secondDate = new Date(data.activities[1].createdAt);
        expect(firstDate.getTime()).toBeGreaterThanOrEqual(secondDate.getTime());
      }
    });

    it('should include user info for activities', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/activity`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();

      if (data.activities.length > 0) {
        const activity = data.activities[0];
        // Most activities should have user info (except some milestones)
        if (activity.activityType !== 'milestone_reached') {
          expect(activity.user).toBeDefined();
          expect(activity.user.username).toBeDefined();
        }
      }
    });

    it('should return correct activity types', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/activity`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();

      const validTypes = [
        'rsvp_going',
        'rsvp_maybe',
        'rsvp_cancelled',
        'comment_posted',
        'photo_uploaded',
        'milestone_reached',
      ];

      data.activities.forEach((activity: { activityType: string }) => {
        expect(validTypes).toContain(activity.activityType);
      });
    });

    it('should return 404 for non-existent event', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/non-existent-event/activity`,
        {
          headers: {
            Authorization: `Bearer ${TEST_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(404);
    });
  });
});
