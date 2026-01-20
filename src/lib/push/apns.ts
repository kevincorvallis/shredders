import http2 from 'http2';
import fs from 'fs';
import jwt from 'jsonwebtoken';

/**
 * APNs Push Notification Service
 *
 * Sends push notifications to iOS devices using Apple Push Notification service.
 *
 * Setup required:
 * 1. Generate APNs Auth Key (.p8 file) from Apple Developer Console
 * 2. Add environment variables:
 *    - APNS_KEY_ID: Key ID from Apple
 *    - APNS_TEAM_ID: Team ID from Apple
 *    - APNS_KEY_PATH: Path to .p8 key file
 *    - APNS_PRODUCTION: true/false (use production APNs)
 *    - APNS_BUNDLE_ID: App bundle identifier
 */

/**
 * Generate JWT token for APNs authentication
 */
function generateAuthToken(): string {
  const keyId = process.env.APNS_KEY_ID;
  const teamId = process.env.APNS_TEAM_ID;
  const keyPath = process.env.APNS_KEY_PATH;

  if (!keyId || !teamId || !keyPath) {
    throw new Error('APNs credentials not configured. Set APNS_KEY_ID, APNS_TEAM_ID, and APNS_KEY_PATH environment variables.');
  }

  // Read the .p8 key file
  const privateKey = fs.readFileSync(keyPath, 'utf8');

  // Generate JWT token
  const token = jwt.sign({}, privateKey, {
    algorithm: 'ES256',
    header: {
      alg: 'ES256',
      kid: keyId,
    },
    issuer: teamId,
    expiresIn: '1h',
  });

  return token;
}

/**
 * Send a push notification to a single device using HTTP/2
 */
export async function sendPushNotification(
  deviceToken: string,
  options: {
    title: string;
    body: string;
    badge?: number;
    sound?: string;
    category?: string;
    data?: Record<string, any>;
    threadId?: string;
  }
): Promise<{ success: boolean; error?: string }> {
  return new Promise((resolve) => {
    try {
      const production = process.env.APNS_PRODUCTION === 'true';
      const bundleId = process.env.APNS_BUNDLE_ID || 'com.shredders.powdertracker';
      const apnsHost = production
        ? 'api.push.apple.com'
        : 'api.sandbox.push.apple.com';

      // Create HTTP/2 client
      const client = http2.connect(`https://${apnsHost}`);

      // Generate auth token
      const authToken = generateAuthToken();

      // Build notification payload
      const payload = {
        aps: {
          alert: {
            title: options.title,
            body: options.body,
          },
          badge: options.badge,
          sound: options.sound || 'default',
          category: options.category,
          'thread-id': options.threadId,
        },
        ...options.data,
      };

      const payloadString = JSON.stringify(payload);

      // Create request
      const request = client.request({
        ':method': 'POST',
        ':path': `/3/device/${deviceToken}`,
        'apns-topic': bundleId,
        'apns-push-type': 'alert',
        'authorization': `bearer ${authToken}`,
        'content-type': 'application/json',
      });

      let responseData = '';

      request.on('response', (headers) => {
        const status = headers[':status'];

        if (status === 200) {
          console.log('Push notification sent successfully:', deviceToken);
          client.close();
          resolve({ success: true });
        } else {
          console.error('Push notification failed:', status, responseData);
          client.close();
          resolve({
            success: false,
            error: `APNs returned status ${status}: ${responseData}`,
          });
        }
      });

      request.on('data', (chunk) => {
        responseData += chunk;
      });

      request.on('error', (error) => {
        console.error('Request error:', error);
        client.close();
        resolve({
          success: false,
          error: error.message,
        });
      });

      request.write(payloadString);
      request.end();
    } catch (error) {
      console.error('Error sending push notification:', error);
      resolve({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  });
}

/**
 * Send push notifications to multiple devices
 */
export async function sendBulkPushNotifications(
  deviceTokens: string[],
  options: {
    title: string;
    body: string;
    badge?: number;
    sound?: string;
    category?: string;
    data?: Record<string, any>;
    threadId?: string;
  }
): Promise<{
  sent: number;
  failed: number;
  errors: Array<{ token: string; error: string }>;
}> {
  const results = {
    sent: 0,
    failed: 0,
    errors: [] as Array<{ token: string; error: string }>,
  };

  // Send notifications in parallel (but limit concurrency)
  const batchSize = 100;
  for (let i = 0; i < deviceTokens.length; i += batchSize) {
    const batch = deviceTokens.slice(i, i + batchSize);
    const promises = batch.map(async (token) => {
      const result = await sendPushNotification(token, options);
      if (result.success) {
        results.sent++;
      } else {
        results.failed++;
        results.errors.push({
          token,
          error: result.error || 'Unknown error',
        });
      }
    });

    await Promise.all(promises);
  }

  console.log(`Bulk push sent: ${results.sent} succeeded, ${results.failed} failed`);
  return results;
}

/**
 * Send weather alert notification
 */
export async function sendWeatherAlert(
  deviceToken: string,
  options: {
    mountainName: string;
    alertType: string;
    alertDescription: string;
    mountainId: string;
  }
): Promise<{ success: boolean; error?: string }> {
  return sendPushNotification(deviceToken, {
    title: `Weather Alert: ${options.mountainName}`,
    body: `${options.alertType}: ${options.alertDescription}`,
    category: 'weather-alert',
    sound: 'default',
    data: {
      type: 'weather-alert',
      mountainId: options.mountainId,
      alertType: options.alertType,
    },
    threadId: `weather-${options.mountainId}`,
  });
}

/**
 * Send powder alert notification
 */
export async function sendPowderAlert(
  deviceToken: string,
  options: {
    mountainName: string;
    snowfallInches: number;
    mountainId: string;
  }
): Promise<{ success: boolean; error?: string }> {
  return sendPushNotification(deviceToken, {
    title: `Powder Alert: ${options.mountainName}`,
    body: `${options.snowfallInches}" of fresh snow! Time to shred! 🎿`,
    category: 'powder-alert',
    sound: 'default',
    badge: 1,
    data: {
      type: 'powder-alert',
      mountainId: options.mountainId,
      snowfallInches: options.snowfallInches,
    },
    threadId: `powder-${options.mountainId}`,
  });
}

/**
 * Send event reminder notification
 */
export async function sendEventReminder(
  deviceToken: string,
  options: {
    eventTitle: string;
    eventId: string;
    mountainName: string;
    eventDate: string;
    departureTime?: string;
    organizerName: string;
  }
): Promise<{ success: boolean; error?: string }> {
  const timeInfo = options.departureTime ? ` at ${options.departureTime}` : '';
  return sendPushNotification(deviceToken, {
    title: `Tomorrow: ${options.eventTitle}`,
    body: `${options.mountainName}${timeInfo} - organized by ${options.organizerName}`,
    category: 'event-reminder',
    sound: 'default',
    badge: 1,
    data: {
      type: 'event-reminder',
      eventId: options.eventId,
    },
    threadId: `event-${options.eventId}`,
  });
}

