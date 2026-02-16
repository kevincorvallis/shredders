import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { sendPowderAlert } from '@/lib/push/apns';

/**
 * POST /api/cron/check-powder-alerts
 *
 * Cron job to check for powder conditions and send push notifications
 * This should be called once daily at 6 AM via Vercel Cron
 *
 * Add to vercel.json:
 * {
 *   "crons": [{
 *     "path": "/api/cron/check-powder-alerts",
 *     "schedule": "0 6 * * *"
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
    console.log('Starting powder alerts check...');

    // Fetch all mountains with active powder alert subscriptions
    const { data: subscriptions, error: subsError } = await supabase
      .from('alert_subscriptions')
      .select(`
        id,
        mountain_id,
        user_id,
        powder_alerts,
        powder_threshold
      `)
      .eq('powder_alerts', true);

    if (subsError) {
      console.error('Error fetching subscriptions:', subsError);
      return NextResponse.json(
        { error: 'Failed to fetch subscriptions' },
        { status: 500 }
      );
    }

    if (!subscriptions || subscriptions.length === 0) {
      console.log('No active powder alert subscriptions');
      return NextResponse.json({
        message: 'No subscriptions to process',
        alertsSent: 0,
      });
    }

    // Get unique mountain IDs
    const mountainIds = [...new Set(subscriptions.map(s => s.mountain_id))];
    console.log(`Checking powder conditions for ${mountainIds.length} mountains`);

    let totalAlertsSent = 0;
    const notificationsByUser = new Map<string, Array<{
      mountainId: string;
      snowfallInches: number;
      threshold: number;
    }>>();

    // Check each mountain for fresh snow
    for (const mountainId of mountainIds) {
      try {
        // Fetch current conditions
        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL || 'https://shredders-bay.vercel.app'}/api/mountains/${mountainId}/conditions`
        );

        if (!response.ok) {
          console.error(`Failed to fetch conditions for ${mountainId}`);
          continue;
        }

        const data = await response.json();
        const snowfall24h = data.conditions?.snowfall24h || 0;
        const powderScore = data.conditions?.powderScore || 0;

        // Only send alerts for significant snowfall (powder score > 7 or snowfall > threshold)
        if (snowfall24h <= 0 || powderScore < 7) {
          continue;
        }

        // Find users subscribed to this mountain who meet threshold
        const mountainSubs = subscriptions.filter(
          s => s.mountain_id === mountainId && snowfall24h >= s.powder_threshold
        );

        for (const sub of mountainSubs) {
          if (!notificationsByUser.has(sub.user_id)) {
            notificationsByUser.set(sub.user_id, []);
          }
          notificationsByUser.get(sub.user_id)!.push({
            mountainId,
            snowfallInches: snowfall24h,
            threshold: sub.powder_threshold,
          });
        }
      } catch (error) {
        console.error(`Error processing powder conditions for ${mountainId}:`, error);
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

        // Send notification for each mountain with fresh snow
        for (const alert of alerts) {
          // Get mountain name
          const { data: mountain } = await supabase
            .from('mountains')
            .select('name')
            .eq('id', alert.mountainId)
            .single();

          const mountainName = mountain?.name || alert.mountainId;

          // Send to all user's devices
          for (const token of tokens) {
            if (token.platform === 'ios') {
              await sendPowderAlert(token.device_token, {
                mountainName,
                snowfallInches: alert.snowfallInches,
                mountainId: alert.mountainId,
              });
              totalAlertsSent++;
            }
          }
        }
      } catch (error) {
        console.error(`Error sending powder alerts to user ${userId}:`, error);
      }
    }

    console.log(`Powder alerts check complete. Sent ${totalAlertsSent} notifications.`);

    return NextResponse.json({
      message: 'Powder alerts processed',
      subscriptionsChecked: subscriptions.length,
      alertsSent: totalAlertsSent,
    });
  } catch (error) {
    console.error('Error in check-powder-alerts cron:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
