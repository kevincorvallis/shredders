import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import http2 from 'http2';
import jwt from 'jsonwebtoken';

// Mock dependencies
vi.mock('http2');
vi.mock('jsonwebtoken');

// We need to reset modules to clear the cached private key between tests
let sendPushNotification: any;
let sendWeatherAlert: any;
let sendPowderAlert: any;

const MOCK_PEM_KEY = '-----BEGIN PRIVATE KEY-----\nMOCK_KEY_CONTENT\n-----END PRIVATE KEY-----';

describe('APNs Service', () => {
  let mockClient: any;
  let mockRequest: any;

  beforeEach(async () => {
    vi.clearAllMocks();
    vi.resetModules();

    // Mock environment variables
    process.env.APNS_KEY_ID = 'test_key_id';
    process.env.APNS_TEAM_ID = 'test_team_id';
    process.env.APNS_KEY = MOCK_PEM_KEY;
    process.env.APNS_PRODUCTION = 'false';
    process.env.APNS_BUNDLE_ID = 'com.test.app';

    // Mock HTTP/2 client
    mockRequest = {
      on: vi.fn((event: string, callback: any) => {
        if (event === 'response') {
          // Simulate successful response
          setTimeout(() => callback({ ':status': 200 }), 0);
        }
        return mockRequest;
      }),
      write: vi.fn(),
      end: vi.fn(),
    };

    mockClient = {
      request: vi.fn().mockReturnValue(mockRequest),
      close: vi.fn(),
    };

    (http2.connect as any).mockReturnValue(mockClient);

    // Mock JWT generation
    (jwt.sign as any).mockReturnValue('mock_jwt_token');

    // Re-import after resetting modules to clear cached private key
    const apns = await import('../apns');
    sendPushNotification = apns.sendPushNotification;
    sendWeatherAlert = apns.sendWeatherAlert;
    sendPowderAlert = apns.sendPowderAlert;
  });

  afterEach(() => {
    delete process.env.APNS_KEY_ID;
    delete process.env.APNS_TEAM_ID;
    delete process.env.APNS_KEY;
    delete process.env.APNS_PRODUCTION;
    delete process.env.APNS_BUNDLE_ID;
  });

  describe('sendPushNotification', () => {
    it('should send notification successfully', async () => {
      const result = await sendPushNotification('device_token_123', {
        title: 'Test Title',
        body: 'Test Body',
        badge: 1,
        sound: 'default',
      });

      expect(result.success).toBe(true);
      expect(http2.connect).toHaveBeenCalledWith('https://api.sandbox.push.apple.com');
      expect(mockRequest.write).toHaveBeenCalled();
      expect(mockRequest.end).toHaveBeenCalled();
      expect(mockClient.close).toHaveBeenCalled();
    });

    it('should use production APNs when APNS_PRODUCTION=true', async () => {
      process.env.APNS_PRODUCTION = 'true';

      await sendPushNotification('device_token_123', {
        title: 'Test',
        body: 'Test',
      });

      expect(http2.connect).toHaveBeenCalledWith('https://api.push.apple.com');
    });

    it('should handle APNs error response', async () => {
      // Mock error response
      mockRequest.on = vi.fn((event: string, callback: any) => {
        if (event === 'response') {
          setTimeout(() => callback({ ':status': 400 }), 0);
        } else if (event === 'data') {
          setTimeout(() => callback('BadDeviceToken'), 0);
        }
        return mockRequest;
      });

      const result = await sendPushNotification('invalid_token', {
        title: 'Test',
        body: 'Test',
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('400');
    });

    it('should include custom data in payload', async () => {
      await sendPushNotification('device_token_123', {
        title: 'Test',
        body: 'Test',
        data: {
          mountainId: 'baker',
          type: 'powder-alert',
        },
      });

      const writeCall = mockRequest.write.mock.calls[0][0];
      const payload = JSON.parse(writeCall);

      expect(payload).toHaveProperty('mountainId', 'baker');
      expect(payload).toHaveProperty('type', 'powder-alert');
    });

    it('should set thread-id for notification grouping', async () => {
      await sendPushNotification('device_token_123', {
        title: 'Test',
        body: 'Test',
        threadId: 'weather-baker',
      });

      const writeCall = mockRequest.write.mock.calls[0][0];
      const payload = JSON.parse(writeCall);

      expect(payload.aps['thread-id']).toBe('weather-baker');
    });

    it('should throw error when APNs credentials are missing', async () => {
      delete process.env.APNS_KEY_ID;

      const result = await sendPushNotification('device_token_123', {
        title: 'Test',
        body: 'Test',
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('APNs credentials not configured');
    });

    it('should handle request errors', async () => {
      mockRequest.on = vi.fn((event: string, callback: any) => {
        if (event === 'error') {
          setTimeout(() => callback(new Error('Network error')), 0);
        }
        return mockRequest;
      });

      const result = await sendPushNotification('device_token_123', {
        title: 'Test',
        body: 'Test',
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain('Network error');
    });
  });

  describe('sendWeatherAlert', () => {
    it('should send weather alert with correct format', async () => {
      const result = await sendWeatherAlert('device_token_123', {
        mountainName: 'Mt. Baker',
        alertType: 'Winter Storm Warning',
        alertDescription: 'Heavy snow expected',
        mountainId: 'baker',
      });

      expect(result.success).toBe(true);

      const writeCall = mockRequest.write.mock.calls[0][0];
      const payload = JSON.parse(writeCall);

      expect(payload.aps.alert.title).toContain('Mt. Baker');
      expect(payload.aps.alert.body).toContain('Winter Storm Warning');
      expect(payload.aps.category).toBe('weather-alert');
      expect(payload.type).toBe('weather-alert');
      expect(payload.mountainId).toBe('baker');
    });

    it('should use thread-id for weather alerts', async () => {
      await sendWeatherAlert('device_token_123', {
        mountainName: 'Mt. Baker',
        alertType: 'Test Alert',
        alertDescription: 'Test',
        mountainId: 'baker',
      });

      const writeCall = mockRequest.write.mock.calls[0][0];
      const payload = JSON.parse(writeCall);

      expect(payload.aps['thread-id']).toBe('weather-baker');
    });
  });

  describe('sendPowderAlert', () => {
    it('should send powder alert with snowfall amount', async () => {
      const result = await sendPowderAlert('device_token_123', {
        mountainName: 'Mt. Baker',
        snowfallInches: 12,
        mountainId: 'baker',
      });

      expect(result.success).toBe(true);

      const writeCall = mockRequest.write.mock.calls[0][0];
      const payload = JSON.parse(writeCall);

      expect(payload.aps.alert.title).toContain('Mt. Baker');
      expect(payload.aps.alert.body).toContain('12"');
      expect(payload.aps.category).toBe('powder-alert-actionable');
      expect(payload.aps.badge).toBe(1);
      expect(payload.type).toBe('powder-alert');
      expect(payload.snowfallInches).toBe(12);
      expect(payload.action).toBe('create-event');
    });

    it('should use thread-id for powder alerts', async () => {
      await sendPowderAlert('device_token_123', {
        mountainName: 'Mt. Baker',
        snowfallInches: 8,
        mountainId: 'baker',
      });

      const writeCall = mockRequest.write.mock.calls[0][0];
      const payload = JSON.parse(writeCall);

      expect(payload.aps['thread-id']).toBe('powder-baker');
    });
  });

  describe('JWT Token Generation', () => {
    it('should generate JWT with correct parameters', async () => {
      await sendPushNotification('device_token_123', {
        title: 'Test',
        body: 'Test',
      });

      expect(jwt.sign).toHaveBeenCalledWith(
        {},
        expect.any(String),
        expect.objectContaining({
          algorithm: 'ES256',
          header: {
            alg: 'ES256',
            kid: 'test_key_id',
          },
          issuer: 'test_team_id',
          expiresIn: '1h',
        })
      );
    });
  });
});
