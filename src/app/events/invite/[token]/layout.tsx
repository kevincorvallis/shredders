import type { Metadata, ResolvingMetadata } from 'next';
import { createClient } from '@/lib/supabase/server';

type Props = {
  params: Promise<{ token: string }>;
  children: React.ReactNode;
};

// Powder day threshold (6+ inches)
const POWDER_DAY_THRESHOLD = 6;

export async function generateMetadata(
  { params }: { params: Promise<{ token: string }> },
  parent: ResolvingMetadata
): Promise<Metadata> {
  const { token } = await params;

  try {
    const supabase = await createClient();

    // Fetch invite and event details with conditions
    const { data: invite } = await supabase
      .from('event_invites')
      .select(`
        *,
        events(
          id, title, event_date, departure_time, departure_location,
          mountain_id, going_count, maybe_count, conditions,
          profiles:creator_id(username, display_name)
        )
      `)
      .eq('invite_token', token)
      .single();

    if (!invite?.events) {
      return {
        title: 'Event Invite | PowderTracker',
        description: 'Join a ski trip on PowderTracker',
      };
    }

    const event = invite.events;
    const mountainId = event.mountain_id;
    const mountainName = getMountainName(mountainId);
    const hostName = event.profiles?.display_name || event.profiles?.username || '';

    // Format date (shorter for iMessage)
    const eventDate = new Date(event.event_date);
    const shortDate = eventDate.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    });
    const fullDate = eventDate.toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
    });

    // Format time
    const departureTime = event.departure_time
      ? formatTime(event.departure_time)
      : '';

    // Check for powder day conditions
    const conditions = event.conditions as { forecast?: { snowfall?: number } } | null;
    const snowfall = conditions?.forecast?.snowfall || 0;
    const isPowderDay = snowfall >= POWDER_DAY_THRESHOLD;

    // Create engaging title (keep under 44 chars for iMessage)
    const shortMountainName = getShortMountainName(mountainId);
    let ogTitle = event.title;
    if (ogTitle.length > 35) {
      ogTitle = ogTitle.substring(0, 32) + '...';
    }

    // Full page title
    const title = isPowderDay
      ? `❄️ ${event.title} | PowderTracker`
      : `${event.title} | PowderTracker`;

    // Rich description
    const description = isPowderDay
      ? `POWDER DAY! ${snowfall}" fresh snow expected. Join ${hostName || 'us'} skiing at ${mountainName} on ${fullDate}. ${event.going_count} people going!`
      : `Join ${hostName || 'us'} skiing at ${mountainName} on ${fullDate}. ${event.going_count} people going!`;

    // Generate OG image URL with all parameters
    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://shredders-bay.vercel.app';
    const ogParams = new URLSearchParams({
      title: ogTitle,
      mountain: mountainName,
      mountainId: mountainId,
      date: shortDate,
      going: String(event.going_count),
      ...(departureTime && { time: departureTime }),
      ...(hostName && { host: hostName }),
      ...(isPowderDay && { powder: 'true' }),
      ...(snowfall > 0 && { snow: String(snowfall) }),
    });
    const ogImageUrl = `${baseUrl}/api/og/event?${ogParams.toString()}`;

    return {
      title,
      description,
      openGraph: {
        title: isPowderDay ? `❄️ ${ogTitle}` : ogTitle,
        description,
        type: 'website',
        url: `${baseUrl}/events/invite/${token}`,
        images: [
          {
            url: ogImageUrl,
            width: 1200,
            height: 630,
            alt: `${event.title} at ${mountainName}`,
          },
        ],
        siteName: 'PowderTracker',
      },
      twitter: {
        card: 'summary_large_image',
        title: isPowderDay ? `❄️ ${ogTitle}` : ogTitle,
        description,
        images: [ogImageUrl],
      },
      other: {
        'apple-itunes-app': 'app-id=YOUR_APP_ID, app-argument=powdertracker://events/invite/' + token,
      },
    };
  } catch (error) {
    console.error('Error generating metadata:', error);
    return {
      title: 'Event Invite | PowderTracker',
      description: 'Join a ski trip on PowderTracker',
    };
  }
}

function formatTime(timeString: string): string {
  try {
    // Handle HH:MM:SS format
    const [hours, minutes] = timeString.split(':').map(Number);
    const period = hours >= 12 ? 'PM' : 'AM';
    const hour12 = hours % 12 || 12;
    return `${hour12}:${minutes.toString().padStart(2, '0')} ${period}`;
  } catch {
    return timeString;
  }
}

function getMountainName(mountainId: string): string {
  const mountains: Record<string, string> = {
    baker: 'Mt. Baker',
    stevens: 'Stevens Pass',
    crystal: 'Crystal Mountain',
    snoqualmie: 'Snoqualmie Pass',
    whitepass: 'White Pass',
    missionridge: 'Mission Ridge',
    meadows: 'Mt. Hood Meadows',
    timberline: 'Timberline Lodge',
    skihood: 'Ski Bowl',
    schweitzer: 'Schweitzer',
    silvermt: 'Silver Mountain',
    fortynine: '49° North',
    lookout: 'Lookout Pass',
    bluewood: 'Bluewood',
    whitefish: 'Whitefish Mountain',
    whistler: 'Whistler Blackcomb',
    bachelor: 'Mt. Bachelor',
  };
  return mountains[mountainId] || mountainId;
}

function getShortMountainName(mountainId: string): string {
  const shortNames: Record<string, string> = {
    baker: 'Baker',
    stevens: 'Stevens',
    crystal: 'Crystal',
    snoqualmie: 'Snoqualmie',
    whitepass: 'White Pass',
    missionridge: 'Mission Ridge',
    meadows: 'Meadows',
    timberline: 'Timberline',
    skihood: 'Ski Bowl',
    schweitzer: 'Schweitzer',
    silvermt: 'Silver Mt',
    fortynine: '49° North',
    lookout: 'Lookout',
    bluewood: 'Bluewood',
    whitefish: 'Whitefish',
    whistler: 'Whistler',
    bachelor: 'Bachelor',
  };
  return shortNames[mountainId] || mountainId;
}

export default function InviteLayout({ children }: Props) {
  return <>{children}</>;
}
