import { ImageResponse } from 'next/og';
import { NextRequest } from 'next/server';

export const runtime = 'edge';

// Mountain emoji/icon mapping
const mountainIcons: Record<string, string> = {
  baker: '🏔️',
  stevens: '⛷️',
  crystal: '💎',
  snoqualmie: '🎿',
  whistler: '🇨🇦',
  default: '⛰️',
};

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);

  const title = searchParams.get('title') || 'Ski Trip';
  const mountain = searchParams.get('mountain') || 'Mountain';
  const mountainId = searchParams.get('mountainId') || 'default';
  const date = searchParams.get('date') || '';
  const time = searchParams.get('time') || '';
  const going = searchParams.get('going') || '0';
  const snow = searchParams.get('snow'); // Fresh snow amount
  const isPowderDay = searchParams.get('powder') === 'true';
  const host = searchParams.get('host') || '';

  const mountainIcon = mountainIcons[mountainId] || mountainIcons.default;
  const goingCount = parseInt(going, 10);

  return new ImageResponse(
    (
      <div
        style={{
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          position: 'relative',
          fontFamily: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        }}
      >
        {/* Background gradient */}
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: isPowderDay
              ? 'linear-gradient(135deg, #0c4a6e 0%, #075985 30%, #0369a1 60%, #0284c7 100%)'
              : 'linear-gradient(135deg, #0f172a 0%, #1e293b 40%, #334155 100%)',
          }}
        />

        {/* Snowflake pattern overlay for powder days */}
        {isPowderDay && (
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              display: 'flex',
              flexWrap: 'wrap',
              opacity: 0.1,
              fontSize: 40,
            }}
          >
            {Array(20)
              .fill('❄️')
              .map((s, i) => (
                <span
                  key={i}
                  style={{
                    position: 'absolute',
                    top: `${(i * 37) % 100}%`,
                    left: `${(i * 43) % 100}%`,
                  }}
                >
                  {s}
                </span>
              ))}
          </div>
        )}

        {/* Mountain silhouette at bottom */}
        <svg
          style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            width: '100%',
            height: '180px',
          }}
          viewBox="0 0 1200 180"
          preserveAspectRatio="none"
        >
          <defs>
            <linearGradient id="mountainGrad" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor={isPowderDay ? '#0c4a6e' : '#1e293b'} stopOpacity="0.8" />
              <stop offset="100%" stopColor={isPowderDay ? '#082f49' : '#0f172a'} stopOpacity="1" />
            </linearGradient>
          </defs>
          {/* Back mountain range */}
          <polygon
            points="0,180 100,100 250,140 400,60 550,110 700,40 850,90 1000,50 1100,100 1200,70 1200,180"
            fill="url(#mountainGrad)"
            opacity="0.5"
          />
          {/* Front mountain range */}
          <polygon
            points="0,180 150,120 300,150 500,80 650,130 800,70 950,120 1100,90 1200,130 1200,180"
            fill="url(#mountainGrad)"
          />
          {/* Snow caps */}
          <polygon points="400,60 380,80 420,80" fill="white" opacity="0.9" />
          <polygon points="700,40 675,65 725,65" fill="white" opacity="0.9" />
          <polygon points="1000,50 975,75 1025,75" fill="white" opacity="0.9" />
        </svg>

        {/* Content container */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            flex: 1,
            padding: '48px',
            zIndex: 1,
          }}
        >
          {/* Powder Day Badge */}
          {isPowderDay && (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                backgroundColor: 'rgba(34, 211, 238, 0.95)',
                color: '#0c4a6e',
                padding: '10px 28px',
                borderRadius: '24px',
                fontSize: 22,
                fontWeight: 700,
                marginBottom: '24px',
                boxShadow: '0 4px 20px rgba(34, 211, 238, 0.4)',
              }}
            >
              <span>❄️</span>
              <span>POWDER DAY</span>
              {snow && <span>• {snow}" FRESH</span>}
              <span>❄️</span>
            </div>
          )}

          {/* Mountain Icon */}
          <div
            style={{
              fontSize: 64,
              marginBottom: '16px',
            }}
          >
            {mountainIcon}
          </div>

          {/* Event Title */}
          <div
            style={{
              fontSize: 56,
              fontWeight: 800,
              color: 'white',
              textAlign: 'center',
              maxWidth: '90%',
              lineHeight: 1.2,
              textShadow: '0 4px 12px rgba(0,0,0,0.3)',
            }}
          >
            {title}
          </div>

          {/* Mountain Name */}
          <div
            style={{
              fontSize: 32,
              fontWeight: 600,
              color: isPowderDay ? '#7dd3fc' : '#38bdf8',
              marginTop: '16px',
              textShadow: '0 2px 8px rgba(0,0,0,0.2)',
            }}
          >
            {mountain}
          </div>

          {/* Date & Time */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              marginTop: '20px',
              fontSize: 24,
              color: '#94a3b8',
            }}
          >
            <span>📅 {date}</span>
            {time && (
              <>
                <span style={{ color: '#475569' }}>•</span>
                <span>🕐 {time}</span>
              </>
            )}
          </div>

          {/* Attendees */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginTop: '24px',
              backgroundColor: 'rgba(255,255,255,0.1)',
              padding: '12px 24px',
              borderRadius: '16px',
              backdropFilter: 'blur(8px)',
            }}
          >
            {/* Avatar circles */}
            <div style={{ display: 'flex' }}>
              {Array(Math.min(goingCount, 4))
                .fill(0)
                .map((_, i) => (
                  <div
                    key={i}
                    style={{
                      width: '36px',
                      height: '36px',
                      borderRadius: '50%',
                      backgroundColor: ['#f472b6', '#a78bfa', '#38bdf8', '#34d399'][i],
                      border: '2px solid rgba(255,255,255,0.3)',
                      marginLeft: i > 0 ? '-12px' : 0,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '16px',
                    }}
                  >
                    {['⛷️', '🎿', '🏂', '🧑‍🎿'][i]}
                  </div>
                ))}
              {goingCount > 4 && (
                <div
                  style={{
                    width: '36px',
                    height: '36px',
                    borderRadius: '50%',
                    backgroundColor: '#64748b',
                    border: '2px solid rgba(255,255,255,0.3)',
                    marginLeft: '-12px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '14px',
                    color: 'white',
                    fontWeight: 600,
                  }}
                >
                  +{goingCount - 4}
                </div>
              )}
            </div>
            <span style={{ color: 'white', fontSize: 20, fontWeight: 600 }}>
              {goingCount} {goingCount === 1 ? 'person' : 'people'} going
            </span>
          </div>

          {/* Host */}
          {host && (
            <div
              style={{
                marginTop: '16px',
                fontSize: 18,
                color: '#64748b',
              }}
            >
              Hosted by {host}
            </div>
          )}
        </div>

        {/* Bottom branding bar */}
        <div
          style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '20px 40px',
            zIndex: 2,
          }}
        >
          {/* Logo */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              color: '#64748b',
              fontSize: 18,
              fontWeight: 600,
            }}
          >
            <span style={{ fontSize: 24 }}>🎿</span>
            <span>PowderTracker</span>
          </div>

          {/* CTA hint */}
          <div
            style={{
              color: isPowderDay ? '#7dd3fc' : '#38bdf8',
              fontSize: 16,
              fontWeight: 500,
            }}
          >
            Tap to join the crew →
          </div>
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
      headers: {
        'Cache-Control': 'public, max-age=3600, s-maxage=86400, stale-while-revalidate=86400',
      },
    }
  );
}
