import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { sendWeatherAlert, sendBulkPushNotifications } from '@/lib/push/apns';

/**
 * POST /api/cron/check-weather-alerts
 *
 * Cron job to check for new weather alerts and send push notifications
 * This should be called every 15 minutes via Vercel Cron
 *
 * Add to vercel.json:
 * {
 *   "crons": [{
 *     "path": "/api/cron/check-weather-alerts",
 *     "schedule": "every 15 minutes"
 *   }]
 * }
 */
export async function POST(request: Request) {
  try {
    // Verify cron secret to prevent unauthorized calls
    const authHeader = request.headers.get('authorization');
    if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const supabase = createAdminClient();
    console.log('Starting weather alerts check...');

    // Fetch all mountains with active alert subscriptions
    const { data: subscriptions, error: subsError } = await supabase
      .from('alert_subscriptions')
      .select(`
        id,
        mountain_id,
        user_id,
        weather_alerts
      `)
      .eq('weather_alerts', true);

    if (subsError) {
      console.error('Error fetching subscriptions:', subsError);
      return NextResponse.json(
        { error: 'Failed to fetch subscriptions' },
        { status: 500 }
      );
    }

    if (!subscriptions || subscriptions.length === 0) {
      console.log('No active weather alert subscriptions');
      return NextResponse.json({
        message: 'No subscriptions to process',
        alertsSent: 0,
      });
    }

    // Get unique mountain IDs
    const mountainIds = [...new Set(subscriptions.map(s => s.mountain_id))];
    console.log(`Checking alerts for ${mountainIds.length} mountains`);

    let totalAlertsSent = 0;
    const notificationsByUser = new Map<string, Array<{
      mountainId: string;
      alertType: string;
      description: string;
    }>>();

    // Check each mountain for new alerts
    for (const mountainId of mountainIds) {
      try {
        // Fetch current alerts from your API
        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL || 'https://shredders-bay.vercel.app'}/api/mountains/${mountainId}/alerts`
        );

        if (!response.ok) {
          console.error(`Failed to fetch alerts for ${mountainId}`);
          continue;
        }

        const data = await response.json();
        const alerts = data.alerts || [];

        // Filter for new/active alerts (issued in last 24 hours)
        const recentAlerts = alerts.filter((alert: any) => {
          const issuedAt = new Date(alert.properties?.sent || alert.properties?.effective);
          const hoursSinceIssued = (Date.now() - issuedAt.getTime()) / (1000 * 60 * 60);
          return hoursSinceIssued < 24;
        });

        if (recentAlerts.length === 0) continue;

        // Find users subscribed to this mountain
        const mountainSubs = subscriptions.filter(s => s.mountain_id === mountainId);

        for (const alert of recentAlerts) {
          const alertType = alert.properties?.event || 'Weather Alert';
          const description = alert.properties?.headline || alert.properties?.description || '';

          // Group notifications by user
          for (const sub of mountainSubs) {
            if (!notificationsByUser.has(sub.user_id)) {
              notificationsByUser.set(sub.user_id, []);
            }
            notificationsByUser.get(sub.user_id)!.push({
              mountainId,
              alertType,
              description: description.substring(0, 200), // Limit length
            });
          }
        }
      } catch (error) {
        console.error(`Error processing alerts for ${mountainId}:`, error);
      }
    }

    // Send notifications to users
    for (const [userId, alerts] of notificationsByUser.entries()) {
      try {
        // Fetch user's active push tokens
        const { data: tokens } = await supabase
          .from('push_notification_tokens')
          .select('device_token, platform')
          .eq('user_id', userId)
          .eq('is_active', true);

        if (!tokens || tokens.length === 0) continue;

        // Group alerts by mountain
        const alertsByMountain = alerts.reduce((acc, alert) => {
          if (!acc[alert.mountainId]) acc[alert.mountainId] = [];
          acc[alert.mountainId].push(alert);
          return acc;
        }, {} as Record<string, typeof alerts>);

        // Send one notification per mountain
        for (const [mountainId, mountainAlerts] of Object.entries(alertsByMountain)) {
          // Get mountain name
          const { data: mountain } = await supabase
            .from('mountains')
            .select('name')
            .eq('id', mountainId)
            .single();

          const mountainName = mountain?.name || mountainId;
          const alertType = mountainAlerts[0].alertType;
          const description = mountainAlerts[0].description;

          // Send to all user's devices
          for (const token of tokens) {
            if (token.platform === 'ios') {
              await sendWeatherAlert(token.device_token, {
                mountainName,
                alertType,
                alertDescription: description,
                mountainId,
              });
              totalAlertsSent++;
            }
          }
        }
      } catch (error) {
        console.error(`Error sending notifications to user ${userId}:`, error);
      }
    }

    console.log(`Weather alerts check complete. Sent ${totalAlertsSent} notifications.`);

    return NextResponse.json({
      message: 'Weather alerts processed',
      subscriptionsChecked: subscriptions.length,
      alertsSent: totalAlertsSent,
    });
  } catch (error) {
    console.error('Error in check-weather-alerts cron:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
