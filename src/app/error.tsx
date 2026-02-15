'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { AlertTriangle, Home, RefreshCw } from 'lucide-react';
import * as Sentry from '@sentry/nextjs';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('Application error:', error);
    Sentry.captureException(error);
  }, [error]);

  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">
        <div className="mb-8">
          <AlertTriangle className="w-20 h-20 text-red-400 mx-auto mb-4" />
          <h1 className="text-4xl font-bold text-text-primary mb-2">
            Avalanche Warning!
          </h1>
          <h2 className="text-xl font-semibold text-text-secondary mb-4">
            Something went wrong
          </h2>
          <p className="text-text-tertiary mb-2">
            We encountered an unexpected error. Don't worry, no powder was harmed.
          </p>
          {error.digest && (
            <p className="text-xs text-text-quaternary font-mono">
              Error ID: {error.digest}
            </p>
          )}
        </div>

        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <button
            onClick={() => reset()}
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-accent hover:bg-accent-hover text-text-primary font-medium rounded-lg transition-colors"
          >
            <RefreshCw className="w-5 h-5" />
            Try Again
          </button>
          <Link
            href="/"
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-surface-secondary hover:bg-surface-tertiary text-text-primary font-medium rounded-lg transition-colors"
          >
            <Home className="w-5 h-5" />
            Back to Home
          </Link>
        </div>

        <div className="mt-8 pt-8 border-t border-border-secondary">
          <p className="text-sm text-text-quaternary">
            If this problem persists, please contact support.
          </p>
        </div>
      </div>
    </div>
  );
}
