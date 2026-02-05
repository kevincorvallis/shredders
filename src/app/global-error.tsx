'use client';

import { useEffect } from 'react';
import * as Sentry from '@sentry/nextjs';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html>
      <body>
        <div style={{
          minHeight: '100vh',
          background: '#0f172a',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '1rem',
          fontFamily: 'system-ui, -apple-system, sans-serif',
        }}>
          <div style={{ maxWidth: '28rem', width: '100%', textAlign: 'center' }}>
            <h1 style={{ fontSize: '2rem', fontWeight: 'bold', color: 'white', marginBottom: '0.5rem' }}>
              Avalanche Warning!
            </h1>
            <h2 style={{ fontSize: '1.25rem', color: '#cbd5e1', marginBottom: '1rem' }}>
              Something went wrong
            </h2>
            <p style={{ color: '#94a3b8', marginBottom: '1.5rem' }}>
              We encountered an unexpected error. Don&apos;t worry, no powder was harmed.
            </p>
            {error.digest && (
              <p style={{ fontSize: '0.75rem', color: '#475569', fontFamily: 'monospace' }}>
                Error ID: {error.digest}
              </p>
            )}
            <button
              onClick={() => reset()}
              style={{
                padding: '0.75rem 1.5rem',
                background: '#0ea5e9',
                color: 'white',
                fontWeight: 500,
                borderRadius: '0.5rem',
                border: 'none',
                cursor: 'pointer',
                marginTop: '1rem',
              }}
            >
              Try Again
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
