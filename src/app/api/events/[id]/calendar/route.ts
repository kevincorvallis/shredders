import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { getMountain } from '@shredders/shared';

/**
 * GET /api/events/[id]/calendar
 *
 * Generate an iCalendar (.ics) file for the event
 * Supports:
 *   - ?format=ics (default) - Returns .ics file download
 *   - ?format=google - Returns Google Calendar URL
 *   - ?format=apple - Returns Apple Calendar URL (webcal://)
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
    const { searchParams } = new URL(request.url);
    const format = searchParams.get('format') || 'ics';

    const supabase = await createClient();

    // Fetch event details
    const { data: event, error } = await supabase
      .from('events')
      .select(`
        id,
        title,
        notes,
        event_date,
        departure_time,
        departure_location,
        mountain_id,
        status,
        creator:user_id (
          display_name
        )
      `)
      .eq('id', eventId)
      .single();

    if (error || !event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // Block calendar export for cancelled events
    if (event.status === 'cancelled') {
      return NextResponse.json(
        { error: 'Cannot export a cancelled event to calendar' },
        { status: 400 }
      );
    }

    const mountain = getMountain(event.mountain_id);
    const mountainName = mountain?.name || event.mountain_id;
    const creatorName = (event.creator as any)?.display_name || 'Shredders';

    // Parse event date and time
    const eventDate = new Date(event.event_date);
    let startTime = new Date(eventDate);
    let endTime = new Date(eventDate);

    if (event.departure_time) {
      const [hours, minutes] = event.departure_time.split(':').map(Number);
      startTime.setHours(hours, minutes, 0, 0);
      // Default end time: 8 hours after start (full day skiing)
      endTime.setHours(hours + 8, minutes, 0, 0);
    } else {
      // All-day event if no departure time
      startTime.setHours(8, 0, 0, 0);
      endTime.setHours(17, 0, 0, 0);
    }

    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app';
    const eventUrl = `${baseUrl}/events/${eventId}`;

    // Build description
    const description = [
      event.notes || '',
      '',
      `Organized by: ${creatorName}`,
      event.departure_location ? `Meeting point: ${event.departure_location}` : '',
      '',
      `View event: ${eventUrl}`,
    ].filter(Boolean).join('\\n');

    const location = event.departure_location
      ? `${event.departure_location} → ${mountainName}`
      : mountainName;

    if (format === 'google') {
      // Google Calendar URL
      const googleUrl = new URL('https://calendar.google.com/calendar/render');
      googleUrl.searchParams.set('action', 'TEMPLATE');
      googleUrl.searchParams.set('text', `${event.title} @ ${mountainName}`);
      googleUrl.searchParams.set('dates', `${formatDateGoogle(startTime)}/${formatDateGoogle(endTime)}`);
      googleUrl.searchParams.set('details', description.replace(/\\n/g, '\n'));
      googleUrl.searchParams.set('location', location);

      return NextResponse.json({ url: googleUrl.toString() });
    }

    if (format === 'apple') {
      // Apple Calendar uses webcal:// protocol with .ics
      const icsUrl = `${baseUrl}/api/events/${eventId}/calendar?format=ics`;
      const webcalUrl = icsUrl.replace('https://', 'webcal://').replace('http://', 'webcal://');

      return NextResponse.json({ url: webcalUrl });
    }

    // Generate .ics file
    const icsContent = generateICS({
      uid: `${eventId}@shredders-bay.vercel.app`,
      title: `${event.title} @ ${mountainName}`,
      description,
      location,
      startTime,
      endTime,
      url: eventUrl,
      organizer: creatorName,
      status: event.status === 'completed' ? 'CONFIRMED' : 'CONFIRMED',
    });

    return new NextResponse(icsContent, {
      status: 200,
      headers: {
        'Content-Type': 'text/calendar; charset=utf-8',
        'Content-Disposition': `attachment; filename="${sanitizeFilename(event.title)}.ics"`,
      },
    });
  } catch (error) {
    console.error('Error in GET /api/events/[id]/calendar:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * Generate ICS file content
 */
function generateICS(params: {
  uid: string;
  title: string;
  description: string;
  location: string;
  startTime: Date;
  endTime: Date;
  url: string;
  organizer: string;
  status?: string;
}): string {
  const { uid, title, description, location, startTime, endTime, url, organizer, status = 'CONFIRMED' } = params;

  const now = new Date();
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Shredders//Event Calendar//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    `UID:${uid}`,
    `DTSTAMP:${formatDateICS(now)}`,
    `DTSTART:${formatDateICS(startTime)}`,
    `DTEND:${formatDateICS(endTime)}`,
    `SUMMARY:${escapeICS(title)}`,
    `DESCRIPTION:${escapeICS(description)}`,
    `LOCATION:${escapeICS(location)}`,
    `URL:${url}`,
    `ORGANIZER;CN=${escapeICS(organizer)}:mailto:events@shredders-bay.vercel.app`,
    `STATUS:${status}`,
    'SEQUENCE:0',
    'END:VEVENT',
    'END:VCALENDAR',
  ];

  return lines.join('\r\n');
}

/**
 * Format date for ICS (YYYYMMDDTHHMMSSZ)
 */
function formatDateICS(date: Date): string {
  return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
}

/**
 * Format date for Google Calendar (YYYYMMDDTHHMMSS)
 */
function formatDateGoogle(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  return `${year}${month}${day}T${hours}${minutes}${seconds}`;
}

/**
 * Escape special characters for ICS format
 */
function escapeICS(text: string): string {
  return text
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\n/g, '\\n');
}

/**
 * Sanitize filename for download
 */
function sanitizeFilename(name: string): string {
  return name
    .replace(/[^a-zA-Z0-9\s-]/g, '')
    .replace(/\s+/g, '_')
    .substring(0, 50);
}
