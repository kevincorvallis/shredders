/**
 * API Tests for Event Comments Endpoints
 *
 * Tests cover:
 * - GET /api/events/[id]/comments
 * - POST /api/events/[id]/comments
 * - DELETE /api/events/[id]/comments/[commentId]
 *
 * NOTE: These are integration tests that require a running server.
 * Set TEST_API_URL environment variable or run `npm run dev` first.
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';

const API_BASE_URL = process.env.TEST_API_URL || 'http://localhost:3000';

// Test data - replace with actual test values
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

describe('Event Comments API', () => {
  let createdCommentId: string | null = null;
  let serverAvailable = false;

  beforeAll(async () => {
    serverAvailable = await isServerReachable();
    if (!serverAvailable) {
      console.warn(
        `⚠️  Skipping Event Comments API tests: Server not reachable at ${API_BASE_URL}`
      );
    }
  });

  // MARK: - GET Comments Tests

  describe('GET /api/events/[id]/comments', () => {
    it('should return 401 without authentication', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`
      );

      expect(response.status).toBe(401);
      const data = await response.json();
      expect(data.error).toBeDefined();
    });

    it('should return gated response for non-RSVP user', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          headers: {
            Authorization: `Bearer ${TEST_AUTH_TOKEN}`,
          },
        }
      );

      // Should return 200 with gated: true
      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.gated).toBe(true);
      expect(data.commentCount).toBeGreaterThanOrEqual(0);
      expect(data.message).toBeDefined();
    });

    it('should return comments for RSVP user', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.gated).toBe(false);
      expect(Array.isArray(data.comments)).toBe(true);
      expect(data.commentCount).toBeGreaterThanOrEqual(0);
    });

    it('should support pagination', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments?limit=5&offset=0`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.pagination).toBeDefined();
      expect(data.pagination.limit).toBe(5);
      expect(data.pagination.offset).toBe(0);
      expect(typeof data.pagination.hasMore).toBe('boolean');
    });

    it('should return 404 for non-existent event', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/non-existent-event/comments`,
        {
          headers: {
            Authorization: `Bearer ${TEST_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(404);
    });
  });

  // MARK: - POST Comment Tests

  describe('POST /api/events/[id]/comments', () => {
    it('should return 401 without authentication', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ content: 'Test comment' }),
        }
      );

      expect(response.status).toBe(401);
    });

    it('should return 403 for non-RSVP user', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_AUTH_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ content: 'Test comment' }),
        }
      );

      expect(response.status).toBe(403);
      const data = await response.json();
      expect(data.error).toContain('RSVP');
    });

    it('should create comment for RSVP user', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ content: 'Test comment from API test' }),
        }
      );

      expect(response.status).toBe(201);
      const data = await response.json();
      expect(data.comment).toBeDefined();
      expect(data.comment.id).toBeDefined();
      expect(data.comment.content).toBe('Test comment from API test');

      // Save for cleanup
      createdCommentId = data.comment.id;
    });

    it('should return 400 for empty content', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ content: '' }),
        }
      );

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.error).toContain('content');
    });

    it('should return 400 for content too long', async ({ skip }) => {
      if (!serverAvailable) skip();
      const longContent = 'a'.repeat(2001);
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ content: longContent }),
        }
      );

      expect(response.status).toBe(400);
    });

    it('should create threaded reply', async ({ skip }) => {
      if (!serverAvailable) skip();
      // First create a parent comment
      const parentResponse = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ content: 'Parent comment' }),
        }
      );

      const parentData = await parentResponse.json();
      const parentId = parentData.comment.id;

      // Create reply
      const replyResponse = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            content: 'Reply to parent',
            parentId: parentId,
          }),
        }
      );

      expect(replyResponse.status).toBe(201);
      const replyData = await replyResponse.json();
      expect(replyData.comment.parentId).toBe(parentId);
    });
  });

  // MARK: - DELETE Comment Tests

  describe('DELETE /api/events/[id]/comments/[commentId]', () => {
    it('should return 401 without authentication', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments/some-comment-id`,
        {
          method: 'DELETE',
        }
      );

      expect(response.status).toBe(401);
    });

    it('should return 404 for non-existent comment', async ({ skip }) => {
      if (!serverAvailable) skip();
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments/non-existent-id`,
        {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(404);
    });

    it('should delete own comment', async ({ skip }) => {
      if (!serverAvailable) skip();
      // First create a comment to delete
      const createResponse = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ content: 'Comment to delete' }),
        }
      );

      const createData = await createResponse.json();
      const commentId = createData.comment.id;

      // Delete it
      const deleteResponse = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments/${commentId}`,
        {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(deleteResponse.status).toBe(200);
      const deleteData = await deleteResponse.json();
      expect(deleteData.message).toBeDefined();
    });
  });

  // Cleanup
  afterAll(async () => {
    if (createdCommentId) {
      await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/comments/${createdCommentId}`,
        {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );
    }
  });
});
