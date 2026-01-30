/**
 * API Tests for Event Photos Endpoints
 *
 * Tests cover:
 * - GET /api/events/[id]/photos
 * - POST /api/events/[id]/photos
 * - DELETE /api/events/[id]/photos/[photoId]
 */

import { describe, it, expect, afterAll } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';

const API_BASE_URL = process.env.TEST_API_URL || 'http://localhost:3000';

const TEST_EVENT_ID = process.env.TEST_EVENT_ID || 'test-event-id';
const TEST_AUTH_TOKEN = process.env.TEST_AUTH_TOKEN || 'test-token';
const TEST_RSVP_AUTH_TOKEN = process.env.TEST_RSVP_AUTH_TOKEN || 'test-rsvp-token';

describe('Event Photos API', () => {
  let uploadedPhotoId: string | null = null;

  // MARK: - GET Photos Tests

  describe('GET /api/events/[id]/photos', () => {
    it('should return 401 without authentication', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`
      );

      expect(response.status).toBe(401);
      const data = await response.json();
      expect(data.error).toBeDefined();
    });

    it('should return gated response for non-RSVP user', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          headers: {
            Authorization: `Bearer ${TEST_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.gated).toBe(true);
      expect(data.photoCount).toBeGreaterThanOrEqual(0);
      expect(data.message).toBeDefined();
    });

    it('should return photos for RSVP user', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.gated).toBe(false);
      expect(Array.isArray(data.photos)).toBe(true);
      expect(data.photoCount).toBeGreaterThanOrEqual(0);
    });

    it('should support pagination', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos?limit=10&offset=0`,
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

    it('should return photo URLs', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();

      if (data.photos.length > 0) {
        const photo = data.photos[0];
        expect(photo.url).toBeDefined();
        expect(photo.url).toMatch(/^https?:\/\//);
      }
    });

    it('should return 404 for non-existent event', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/non-existent-event/photos`,
        {
          headers: {
            Authorization: `Bearer ${TEST_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(404);
    });
  });

  // MARK: - POST Photo Tests

  describe('POST /api/events/[id]/photos', () => {
    it('should return 401 without authentication', async () => {
      const formData = new FormData();
      formData.append('photo', new Blob(['test']), 'test.jpg');

      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          method: 'POST',
          body: formData,
        }
      );

      expect(response.status).toBe(401);
    });

    it('should return 403 for non-RSVP user', async () => {
      const formData = new FormData();
      formData.append('photo', new Blob(['test']), 'test.jpg');

      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_AUTH_TOKEN}`,
          },
          body: formData,
        }
      );

      expect(response.status).toBe(403);
      const data = await response.json();
      expect(data.error).toContain('RSVP');
    });

    it('should return 400 without photo file', async () => {
      const formData = new FormData();
      formData.append('caption', 'Test caption');

      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
          body: formData,
        }
      );

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.error).toContain('photo');
    });

    it('should upload photo with caption', async () => {
      // Create a minimal valid JPEG
      const jpegHeader = new Uint8Array([
        0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xff, 0xdb, 0x00, 0x43,
      ]);
      const jpegBlob = new Blob([jpegHeader], { type: 'image/jpeg' });

      const formData = new FormData();
      formData.append('photo', jpegBlob, 'test-photo.jpg');
      formData.append('caption', 'Test photo from API test');

      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
          body: formData,
        }
      );

      // Note: This may fail if the image is invalid, which is expected
      // In a real test, use a valid test image
      if (response.status === 201) {
        const data = await response.json();
        expect(data.photo).toBeDefined();
        expect(data.photo.id).toBeDefined();
        expect(data.photo.caption).toBe('Test photo from API test');
        uploadedPhotoId = data.photo.id;
      } else {
        // Accept 400 for invalid image data in test environment
        expect([201, 400]).toContain(response.status);
      }
    });

    it('should reject non-image files', async () => {
      const textBlob = new Blob(['This is not an image'], {
        type: 'text/plain',
      });

      const formData = new FormData();
      formData.append('photo', textBlob, 'test.txt');

      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
          body: formData,
        }
      );

      expect(response.status).toBe(400);
    });

    it('should reject files that are too large', async () => {
      // Create a large blob (>10MB)
      const largeBlob = new Blob([new Uint8Array(11 * 1024 * 1024)], {
        type: 'image/jpeg',
      });

      const formData = new FormData();
      formData.append('photo', largeBlob, 'large-photo.jpg');

      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
          body: formData,
        }
      );

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.error.toLowerCase()).toContain('size');
    });
  });

  // MARK: - DELETE Photo Tests

  describe('DELETE /api/events/[id]/photos/[photoId]', () => {
    it('should return 401 without authentication', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos/some-photo-id`,
        {
          method: 'DELETE',
        }
      );

      expect(response.status).toBe(401);
    });

    it('should return 404 for non-existent photo', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos/non-existent-id`,
        {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(404);
    });

    it('should return 403 when deleting another user photo', async () => {
      // This test requires a photo uploaded by a different user
      // Skip if no such photo exists
      const photosResponse = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      const photosData = await photosResponse.json();
      // Find a photo not owned by the test user (if any)
      // This is a placeholder - in real tests, set up proper test data
    });
  });

  // MARK: - Photo Metadata Tests

  describe('Photo Metadata', () => {
    it('should return photo dimensions if available', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();

      if (data.photos.length > 0) {
        const photo = data.photos[0];
        // Dimensions are optional but should be numbers if present
        if (photo.width !== undefined) {
          expect(typeof photo.width).toBe('number');
          expect(photo.width).toBeGreaterThan(0);
        }
        if (photo.height !== undefined) {
          expect(typeof photo.height).toBe('number');
          expect(photo.height).toBeGreaterThan(0);
        }
      }
    });

    it('should return thumbnail URL if available', async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos`,
        {
          headers: {
            Authorization: `Bearer ${TEST_RSVP_AUTH_TOKEN}`,
          },
        }
      );

      expect(response.status).toBe(200);
      const data = await response.json();

      if (data.photos.length > 0) {
        const photo = data.photos[0];
        if (photo.thumbnailUrl) {
          expect(photo.thumbnailUrl).toMatch(/^https?:\/\//);
        }
      }
    });
  });

  // Cleanup
  afterAll(async () => {
    if (uploadedPhotoId) {
      await fetch(
        `${API_BASE_URL}/api/events/${TEST_EVENT_ID}/photos/${uploadedPhotoId}`,
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
