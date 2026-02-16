import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { sendEventReminder } from '@/lib/push/apns';
import { getMountain } from '@shredders/shared';

/**
 * POST /api/cron/event-reminders
 *
 * Cron job to send push notification reminders for events happening tomorrow.
 * This should be called once daily at 6 PM via Vercel Cron to give users
 * evening notice about tomorrow's ski day.
 *
 * Add to vercel.json:
 * {
 *   "crons": [{
 *     "path": "/api/cron/event-reminders",
 *     "schedule": "0 18 * * *"
 *   }]
 * }
 */
export async function POST(request: Request) {
  try {
    // Verify cron secret to prevent unauthorized calls
    const authHeader = request.headers.get('authorization');
    if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const supabase = createAdminClient();
    console.log('Starting event reminders check...');

    // Call the database function to get events needing reminders
    // RPC returns rows per attendee: event_id, event_title, mountain_id, event_date, departure_time, user_id, device_tokens
    const { data: eventsNeedingReminders, error: eventsError } = await supabase.rpc(
      'get_events_for_reminder'
    );

    if (eventsError) {
      console.error('Error fetching events for reminder:', eventsError);
      return NextResponse.json(
        { error: 'Failed to fetch events' },
        { status: 500 }
      );
    }

    if (!eventsNeedingReminders || eventsNeedingReminders.length === 0) {
      console.log('No events need reminders today');
      return NextResponse.json({
        message: 'No events to remind',
        remindersSent: 0,
      });
    }

    console.log(`Found ${eventsNeedingReminders.length} attendee rows needing reminders`);

    let totalRemindersSent = 0;
    const processedEvents = new Set<string>();

    for (const row of eventsNeedingReminders) {
      try {
        // Get mountain name
        const mountain = getMountain(row.mountain_id);
        const mountainName = mountain?.name || row.mountain_id;

        // Get event creator info
        const { data: creator } = await supabase
          .from('users')
          .select('display_name, username')
          .eq('id', row.user_id)
          .single();

        const organizerName = creator?.display_name || creator?.username || 'Unknown';

        // device_tokens is already provided by the RPC as an array
        const deviceTokens: string[] = row.device_tokens || [];

        if (deviceTokens.length === 0) {
          console.log(`No push tokens for attendee in event ${row.event_id}`);
          continue;
        }

        // Send reminders to each device token
        for (const deviceToken of deviceTokens) {
          // Format departure time if present
          let formattedTime: string | undefined;
          if (row.departure_time) {
            const [hours, minutes] = row.departure_time.split(':');
            const hour = parseInt(hours, 10);
            const h12 = hour % 12 === 0 ? 12 : hour % 12;
            const ampm = hour >= 12 ? 'PM' : 'AM';
            formattedTime = `${h12}:${minutes} ${ampm}`;
          }

          const result = await sendEventReminder(deviceToken, {
            eventTitle: row.event_title,
            eventId: row.event_id,
            mountainName,
            eventDate: row.event_date,
            departureTime: formattedTime,
            organizerName,
          });

          if (result.success) {
            totalRemindersSent++;
          } else {
            console.error(
              `Failed to send reminder to ${deviceToken}: ${result.error}`
            );
          }
        }

        processedEvents.add(row.event_id);
      } catch (error) {
        console.error(`Error processing reminder row for event ${row.event_id}:`, error);
      }
    }

    console.log(
      `Event reminders complete. Sent ${totalRemindersSent} notifications for ${processedEvents.size} events.`
    );

    return NextResponse.json({
      message: 'Event reminders processed',
      eventsProcessed: processedEvents.size,
      remindersSent: totalRemindersSent,
    });
  } catch (error) {
    console.error('Error in event-reminders cron:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// Also allow GET for manual testing (with auth)
export async function GET(request: Request) {
  return POST(request);
}
