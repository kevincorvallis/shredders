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

    console.log(`Found ${eventsNeedingReminders.length} events needing reminders`);

    let totalRemindersSent = 0;
    const processedEvents: string[] = [];

    for (const event of eventsNeedingReminders) {
      try {
        // Skip cancelled events (safety check in case RPC doesn't filter them)
        if (event.status === 'cancelled') {
          console.log(`Skipping cancelled event ${event.id}`);
          continue;
        }

        // Get mountain name
        const mountain = getMountain(event.mountain_id);
        const mountainName = mountain?.name || event.mountain_id;

        // Get event creator info
        const { data: creator } = await supabase
          .from('profiles')
          .select('display_name, username')
          .eq('id', event.user_id)
          .single();

        const organizerName = creator?.display_name || creator?.username || 'Unknown';

        // Get all attendees who are going or maybe
        const { data: attendees } = await supabase
          .from('event_attendees')
          .select('user_id')
          .eq('event_id', event.id)
          .in('status', ['going', 'maybe']);

        if (!attendees || attendees.length === 0) {
          console.log(`No attendees for event ${event.id}`);
          continue;
        }

        // Get push tokens for all attendees
        const attendeeIds = attendees.map((a) => a.user_id);

        const { data: tokens } = await supabase
          .from('push_notification_tokens')
          .select('device_token, user_id, platform')
          .in('user_id', attendeeIds)
          .eq('is_active', true);

        if (!tokens || tokens.length === 0) {
          console.log(`No push tokens for event ${event.id} attendees`);
          continue;
        }

        // Send reminders to each attendee
        for (const token of tokens) {
          if (token.platform === 'ios') {
            // Format departure time if present
            let formattedTime: string | undefined;
            if (event.departure_time) {
              const [hours, minutes] = event.departure_time.split(':');
              const hour = parseInt(hours, 10);
              const h12 = hour % 12 === 0 ? 12 : hour % 12;
              const ampm = hour >= 12 ? 'PM' : 'AM';
              formattedTime = `${h12}:${minutes} ${ampm}`;
            }

            const result = await sendEventReminder(token.device_token, {
              eventTitle: event.title,
              eventId: event.id,
              mountainName,
              eventDate: event.event_date,
              departureTime: formattedTime,
              organizerName,
            });

            if (result.success) {
              totalRemindersSent++;
            } else {
              console.error(
                `Failed to send reminder to ${token.device_token}: ${result.error}`
              );
            }
          }
        }

        // Mark event as reminded
        await supabase
          .from('events')
          .update({ reminder_sent: true })
          .eq('id', event.id);

        processedEvents.push(event.id);
      } catch (error) {
        console.error(`Error processing event ${event.id}:`, error);
      }
    }

    console.log(
      `Event reminders complete. Sent ${totalRemindersSent} notifications for ${processedEvents.length} events.`
    );

    return NextResponse.json({
      message: 'Event reminders processed',
      eventsProcessed: processedEvents.length,
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
