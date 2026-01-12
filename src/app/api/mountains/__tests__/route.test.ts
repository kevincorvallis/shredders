/**
 * Tests for GET /api/mountains
 * Tests mountain list endpoint with region filtering
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { GET } from '../route';
import { createMockRequest, getResponseJSON } from '@/lib/testing';

describe('GET /api/mountains', () => {
  describe('success cases', () => {
    it('returns all mountains when no region specified', async () => {
      const request = createMockRequest('/api/mountains');
      const response = await GET(request);
      const data = await getResponseJSON(response);

      expect(response.status).toBe(200);
      expect(data.mountains).toBeDefined();
      expect(Array.isArray(data.mountains)).toBe(true);
      expect(data.mountains.length).toBeGreaterThan(0);

      // Validate first mountain has correct structure
      const firstMountain = data.mountains[0];
      expect(firstMountain).toMatchObject({
        id: expect.any(String),
        name: expect.any(String),
        shortName: expect.any(String),
        location: {
          lat: expect.any(Number),
          lng: expect.any(Number),
        },
        elevation: {
          base: expect.any(Number),
          summit: expect.any(Number),
        },
        region: expect.stringMatching(/^(washington|oregon|idaho|canada)$/),
        color: expect.any(String),
        website: expect.any(String),
        hasSnotel: expect.any(Boolean),
        webcamCount: expect.any(Number),
        passType: expect.stringMatching(/^(epic|ikon|independent)$/),
      });
    });

    it('filters mountains by region=washington', async () => {
      const request = createMockRequest('/api/mountains', {
        searchParams: { region: 'washington' },
      });
      const response = await GET(request);
      const data = await getResponseJSON(response);

      expect(response.status).toBe(200);
      expect(data.mountains.length).toBeGreaterThan(0);

      // All mountains should be in Washington
      data.mountains.forEach((mountain: any) => {
        expect(mountain.region).toBe('washington');
      });

      // Should include known Washington mountains
      const mountainNames = data.mountains.map((m: any) => m.name);
      expect(mountainNames).toContain('Mt. Baker');
    });

    it('filters mountains by region=oregon', async () => {
      const request = createMockRequest('/api/mountains', {
        searchParams: { region: 'oregon' },
      });
      const response = await GET(request);
      const data = await getResponseJSON(response);

      expect(response.status).toBe(200);
      expect(data.mountains.length).toBeGreaterThan(0);

      // All mountains should be in Oregon
      data.mountains.forEach((mountain: any) => {
        expect(mountain.region).toBe('oregon');
      });
    });

    it('returns mountains with SNOTEL data marked correctly', async () => {
      const request = createMockRequest('/api/mountains');
      const response = await GET(request);
      const data = await getResponseJSON(response);

      // Mt. Baker should have SNOTEL
      const baker = data.mountains.find((m: any) => m.id === 'baker');
      expect(baker?.hasSnotel).toBe(true);
      expect(baker?.webcamCount).toBeGreaterThan(0);
    });

    it('includes correct passType for mountains', async () => {
      const request = createMockRequest('/api/mountains');
      const response = await GET(request);
      const data = await getResponseJSON(response);

      const crystalOrStevens = data.mountains.find(
        (m: any) => m.id === 'crystal' || m.id === 'stevens'
      );

      if (crystalOrStevens) {
        expect(crystalOrStevens.passType).toBe('epic');
      }
    });
  });

  describe('edge cases', () => {
    it('handles invalid region gracefully', async () => {
      const request = createMockRequest('/api/mountains', {
        searchParams: { region: 'invalid' as any },
      });
      const response = await GET(request);
      const data = await getResponseJSON(response);

      // Should return empty array or all mountains (depending on implementation)
      expect(response.status).toBe(200);
      expect(Array.isArray(data.mountains)).toBe(true);
    });

    it('handles case-sensitive region parameter', async () => {
      const request = createMockRequest('/api/mountains', {
        searchParams: { region: 'Washington' as any },
      });
      const response = await GET(request);
      const data = await getResponseJSON(response);

      // Should handle case insensitivity or return empty
      expect(response.status).toBe(200);
      expect(Array.isArray(data.mountains)).toBe(true);
    });
  });

  describe('data integrity', () => {
    it('returns unique mountain IDs', async () => {
      const request = createMockRequest('/api/mountains');
      const response = await GET(request);
      const data = await getResponseJSON(response);

      const ids = data.mountains.map((m: any) => m.id);
      const uniqueIds = new Set(ids);

      expect(ids.length).toBe(uniqueIds.size);
    });

    it('all mountains have valid coordinates', async () => {
      const request = createMockRequest('/api/mountains');
      const response = await GET(request);
      const data = await getResponseJSON(response);

      data.mountains.forEach((mountain: any) => {
        // Latitude between -90 and 90
        expect(mountain.location.lat).toBeGreaterThanOrEqual(-90);
        expect(mountain.location.lat).toBeLessThanOrEqual(90);

        // Longitude between -180 and 180
        expect(mountain.location.lng).toBeGreaterThanOrEqual(-180);
        expect(mountain.location.lng).toBeLessThanOrEqual(180);
      });
    });

    it('all mountains have valid elevation data', async () => {
      const request = createMockRequest('/api/mountains');
      const response = await GET(request);
      const data = await getResponseJSON(response);

      data.mountains.forEach((mountain: any) => {
        // Summit should be higher than base
        expect(mountain.elevation.summit).toBeGreaterThan(mountain.elevation.base);

        // Elevations should be positive and reasonable
        expect(mountain.elevation.base).toBeGreaterThan(0);
        expect(mountain.elevation.summit).toBeLessThan(20000); // No mountain that high in our regions
      });
    });

    it('all mountains have valid website URLs', async () => {
      const request = createMockRequest('/api/mountains');
      const response = await GET(request);
      const data = await getResponseJSON(response);

      data.mountains.forEach((mountain: any) => {
        expect(mountain.website).toMatch(/^https?:\/\//);
      });
    });
  });

  describe('performance', () => {
    it('responds within acceptable time', async () => {
      const startTime = Date.now();

      const request = createMockRequest('/api/mountains');
      await GET(request);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      // Should respond in less than 100ms (it's just reading static data)
      expect(responseTime).toBeLessThan(100);
    });
  });
});
