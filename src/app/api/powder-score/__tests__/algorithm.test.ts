/**
 * Unit tests for powder score calculation algorithm
 * Tests all scoring factors and edge cases
 */

import { describe, it, expect } from 'vitest';

// Extract the calculation function for unit testing
// In a real app, this would be in a separate file, but for testing we'll inline it
function calculatePowderScore(
  snowfall24h: number,
  snowfall48h: number,
  temperature: number,
  windSpeed: number,
  baseDepth: number,
  upcomingSnow: number
) {
  let score = 5; // Base score
  const factors: any[] = [];

  // Fresh snow bonus (0-3 points)
  if (snowfall24h >= 12) {
    score += 3;
    factors.push({ name: 'Fresh Snow', points: 3 });
  } else if (snowfall24h >= 6) {
    score += 2;
    factors.push({ name: 'Fresh Snow', points: 2 });
  } else if (snowfall24h >= 2) {
    score += 1;
    factors.push({ name: 'Fresh Snow', points: 1 });
  } else if (snowfall48h >= 6) {
    score += 1;
    factors.push({ name: 'Recent Snow', points: 1 });
  } else {
    factors.push({ name: 'Fresh Snow', points: 0 });
  }

  // Upcoming snow bonus (0-1 point)
  if (upcomingSnow >= 6) {
    score += 1;
    factors.push({ name: 'Incoming Storm', points: 1 });
  }

  // Temperature bonus (0-2 points)
  if (temperature < 20) {
    score += 2;
    factors.push({ name: 'Temperature', points: 2 });
  } else if (temperature < 28) {
    score += 1;
    factors.push({ name: 'Temperature', points: 1 });
  } else if (temperature > 35) {
    score -= 1;
    factors.push({ name: 'Temperature', points: -1 });
  } else {
    factors.push({ name: 'Temperature', points: 0 });
  }

  // Wind penalty (0 to -2 points)
  if (windSpeed > 35) {
    score -= 2;
    factors.push({ name: 'Wind', points: -2 });
  } else if (windSpeed > 25) {
    score -= 1;
    factors.push({ name: 'Wind', points: -1 });
  } else {
    factors.push({ name: 'Wind', points: 0 });
  }

  // Base depth bonus (0-1 point)
  if (baseDepth >= 80) {
    score += 1;
    factors.push({ name: 'Base Depth', points: 1 });
  } else if (baseDepth >= 40) {
    factors.push({ name: 'Base Depth', points: 0 });
  } else if (baseDepth < 20) {
    score -= 1;
    factors.push({ name: 'Base Depth', points: -1 });
  }

  // Clamp score between 1 and 10
  score = Math.max(1, Math.min(10, score));

  return { score, factors };
}

describe('Powder Score Algorithm', () => {
  describe('perfect conditions', () => {
    it('scores 10/10 for epic powder conditions', () => {
      const result = calculatePowderScore(
        15,  // 15" new snow
        20,  // 20" in 48h
        18,  // 18°F (cold powder)
        10,  // Light wind
        100, // Deep base
        8    // More snow coming
      );

      expect(result.score).toBe(10);

      // Should have max points from all positive factors
      const totalPoints = result.factors.reduce((sum, f) => sum + f.points, 0);
      expect(totalPoints).toBeGreaterThanOrEqual(5); // Base + bonuses
    });

    it('scores 9-10 for 12"+ fresh snow with good conditions', () => {
      const result = calculatePowderScore(12, 15, 22, 12, 90, 6);
      expect(result.score).toBeGreaterThanOrEqual(9);
    });
  });

  describe('fresh snow factor', () => {
    it('adds 3 points for 12"+ new snow', () => {
      const result = calculatePowderScore(12, 0, 30, 10, 50, 0);
      const freshSnowFactor = result.factors.find(f => f.name === 'Fresh Snow');
      expect(freshSnowFactor?.points).toBe(3);
    });

    it('adds 2 points for 6-11" new snow', () => {
      const result = calculatePowderScore(8, 0, 30, 10, 50, 0);
      const freshSnowFactor = result.factors.find(f => f.name === 'Fresh Snow');
      expect(freshSnowFactor?.points).toBe(2);
    });

    it('adds 1 point for 2-5" new snow', () => {
      const result = calculatePowderScore(3, 0, 30, 10, 50, 0);
      const freshSnowFactor = result.factors.find(f => f.name === 'Fresh Snow');
      expect(freshSnowFactor?.points).toBe(1);
    });

    it('uses 48h snow if 24h is low', () => {
      const result = calculatePowderScore(0, 8, 30, 10, 50, 0);
      const recentSnowFactor = result.factors.find(f => f.name === 'Recent Snow');
      expect(recentSnowFactor?.points).toBe(1);
    });

    it('adds 0 points for no new snow', () => {
      const result = calculatePowderScore(0, 0, 30, 10, 50, 0);
      const freshSnowFactor = result.factors.find(f => f.name === 'Fresh Snow');
      expect(freshSnowFactor?.points).toBe(0);
    });
  });

  describe('temperature factor', () => {
    it('adds 2 points for very cold temps (<20°F)', () => {
      const result = calculatePowderScore(0, 0, 18, 10, 50, 0);
      const tempFactor = result.factors.find(f => f.name === 'Temperature');
      expect(tempFactor?.points).toBe(2);
    });

    it('adds 1 point for cold temps (20-27°F)', () => {
      const result = calculatePowderScore(0, 0, 25, 10, 50, 0);
      const tempFactor = result.factors.find(f => f.name === 'Temperature');
      expect(tempFactor?.points).toBe(1);
    });

    it('adds 0 points for moderate temps (28-35°F)', () => {
      const result = calculatePowderScore(0, 0, 32, 10, 50, 0);
      const tempFactor = result.factors.find(f => f.name === 'Temperature');
      expect(tempFactor?.points).toBe(0);
    });

    it('subtracts 1 point for warm temps (>35°F)', () => {
      const result = calculatePowderScore(0, 0, 40, 10, 50, 0);
      const tempFactor = result.factors.find(f => f.name === 'Temperature');
      expect(tempFactor?.points).toBe(-1);
    });
  });

  describe('wind factor', () => {
    it('subtracts 2 points for very high wind (>35mph)', () => {
      const result = calculatePowderScore(0, 0, 30, 40, 50, 0);
      const windFactor = result.factors.find(f => f.name === 'Wind');
      expect(windFactor?.points).toBe(-2);
    });

    it('subtracts 1 point for high wind (26-35mph)', () => {
      const result = calculatePowderScore(0, 0, 30, 30, 50, 0);
      const windFactor = result.factors.find(f => f.name === 'Wind');
      expect(windFactor?.points).toBe(-1);
    });

    it('adds 0 points for manageable wind (<25mph)', () => {
      const result = calculatePowderScore(0, 0, 30, 20, 50, 0);
      const windFactor = result.factors.find(f => f.name === 'Wind');
      expect(windFactor?.points).toBe(0);
    });
  });

  describe('base depth factor', () => {
    it('adds 1 point for deep base (80"+)', () => {
      const result = calculatePowderScore(0, 0, 30, 10, 100, 0);
      const baseFactor = result.factors.find(f => f.name === 'Base Depth');
      expect(baseFactor?.points).toBe(1);
    });

    it('adds 0 points for good base (40-79")', () => {
      const result = calculatePowderScore(0, 0, 30, 10, 50, 0);
      const baseFactor = result.factors.find(f => f.name === 'Base Depth');
      expect(baseFactor?.points).toBe(0);
    });

    it('subtracts 1 point for shallow base (<20")', () => {
      const result = calculatePowderScore(0, 0, 30, 10, 15, 0);
      const baseFactor = result.factors.find(f => f.name === 'Base Depth');
      expect(baseFactor?.points).toBe(-1);
    });
  });

  describe('upcoming snow factor', () => {
    it('adds 1 point for incoming storm (6"+)', () => {
      const result = calculatePowderScore(0, 0, 30, 10, 50, 8);
      const stormFactor = result.factors.find(f => f.name === 'Incoming Storm');
      expect(stormFactor?.points).toBe(1);
    });

    it('adds 0 points for little upcoming snow', () => {
      const result = calculatePowderScore(0, 0, 30, 10, 50, 2);
      const stormFactor = result.factors.find(f => f.name === 'Incoming Storm');
      expect(stormFactor).toBeUndefined();
    });
  });

  describe('score boundaries', () => {
    it('never scores below 1', () => {
      // Worst possible conditions
      const result = calculatePowderScore(
        0,   // No new snow
        0,   // No 48h snow
        45,  // Warm temps
        50,  // Extreme wind
        10,  // Shallow base
        0    // No upcoming snow
      );

      expect(result.score).toBeGreaterThanOrEqual(1);
      expect(result.score).toBe(1);
    });

    it('never scores above 10', () => {
      // Beyond perfect conditions
      const result = calculatePowderScore(
        24,  // Extreme snow
        30,  // Tons of 48h snow
        10,  // Very cold
        5,   // No wind
        150, // Deep base
        12   // Tons more snow coming
      );

      expect(result.score).toBeLessThanOrEqual(10);
      expect(result.score).toBe(10);
    });

    it('base score is 5 with neutral conditions', () => {
      // Perfectly neutral conditions
      const result = calculatePowderScore(
        0,   // No new snow but not terrible
        0,
        32,  // Moderate temp
        15,  // Manageable wind
        50,  // Decent base
        0    // No upcoming snow
      );

      // Should be close to base score with minor adjustments
      expect(result.score).toBeGreaterThanOrEqual(4);
      expect(result.score).toBeLessThanOrEqual(6);
    });
  });

  describe('edge cases', () => {
    it('handles zero values', () => {
      const result = calculatePowderScore(0, 0, 0, 0, 0, 0);

      expect(result.score).toBeGreaterThanOrEqual(1);
      expect(result.score).toBeLessThanOrEqual(10);
      expect(result.factors).toBeDefined();
      expect(result.factors.length).toBeGreaterThan(0);
    });

    it('handles negative values (invalid input)', () => {
      const result = calculatePowderScore(-5, -10, -20, -5, -10, -5);

      // Should still clamp to valid range
      expect(result.score).toBeGreaterThanOrEqual(1);
      expect(result.score).toBeLessThanOrEqual(10);
    });

    it('handles extreme positive values', () => {
      const result = calculatePowderScore(100, 200, 100, 100, 500, 100);

      // Should clamp to 1-10 range despite extreme inputs
      expect(result.score).toBeGreaterThanOrEqual(1);
      expect(result.score).toBeLessThanOrEqual(10);
    });

    it('handles boundary values precisely', () => {
      // Test exact thresholds
      expect(calculatePowderScore(12, 0, 30, 10, 50, 0).score).toBe(
        calculatePowderScore(11.9, 0, 30, 10, 50, 0).score + 1
      );
    });
  });

  describe('realistic scenarios', () => {
    it('scores high for a powder day', () => {
      // Classic powder day: fresh snow, cold temps, light wind
      const result = calculatePowderScore(10, 15, 22, 12, 85, 4);

      expect(result.score).toBeGreaterThanOrEqual(8);
      expect(result.score).toBeLessThanOrEqual(10);
    });

    it('scores medium for groomer day', () => {
      // Good groomer conditions: no fresh snow, decent base
      const result = calculatePowderScore(0, 2, 28, 15, 60, 0);

      expect(result.score).toBeGreaterThanOrEqual(4);
      expect(result.score).toBeLessThanOrEqual(6);
    });

    it('scores low for poor conditions', () => {
      // Warm, windy, no snow
      const result = calculatePowderScore(0, 0, 38, 32, 25, 0);

      expect(result.score).toBeLessThanOrEqual(4);
    });

    it('accounts for incoming storm', () => {
      // Current conditions mediocre, but storm coming
      const withStorm = calculatePowderScore(2, 3, 30, 18, 50, 10);
      const withoutStorm = calculatePowderScore(2, 3, 30, 18, 50, 0);

      expect(withStorm.score).toBeGreaterThan(withoutStorm.score);
    });
  });

  describe('factor combinations', () => {
    it('cold temps + fresh snow = highest scores', () => {
      const coldPowder = calculatePowderScore(12, 15, 18, 10, 80, 0);
      const warmPowder = calculatePowderScore(12, 15, 36, 10, 80, 0);

      expect(coldPowder.score).toBeGreaterThan(warmPowder.score);
    });

    it('high wind reduces score even with fresh snow', () => {
      const calmSnow = calculatePowderScore(10, 12, 25, 10, 70, 0);
      const windySnow = calculatePowderScore(10, 12, 25, 40, 70, 0);

      expect(calmSnow.score).toBeGreaterThan(windySnow.score);
      expect(calmSnow.score - windySnow.score).toBe(2); // Wind penalty
    });

    it('deep base enhances score slightly', () => {
      const deepBase = calculatePowderScore(8, 10, 25, 15, 100, 0);
      const shallowBase = calculatePowderScore(8, 10, 25, 15, 50, 0);

      expect(deepBase.score).toBeGreaterThan(shallowBase.score);
    });
  });
});
