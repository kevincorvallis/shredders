'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { AlertTriangle, Home, RefreshCw } from 'lucide-react';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('Application error:', error);
  }, [error]);

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">
        <div className="mb-8">
          <AlertTriangle className="w-20 h-20 text-red-400 mx-auto mb-4" />
          <h1 className="text-4xl font-bold text-white mb-2">
            Avalanche Warning!
          </h1>
          <h2 className="text-xl font-semibold text-slate-300 mb-4">
            Something went wrong
          </h2>
          <p className="text-slate-400 mb-2">
            We encountered an unexpected error. Don't worry, no powder was harmed.
          </p>
          {error.digest && (
            <p className="text-xs text-slate-600 font-mono">
              Error ID: {error.digest}
            </p>
          )}
        </div>

        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <button
            onClick={() => reset()}
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-sky-500 hover:bg-sky-600 text-white font-medium rounded-lg transition-colors"
          >
            <RefreshCw className="w-5 h-5" />
            Try Again
          </button>
          <Link
            href="/"
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white font-medium rounded-lg transition-colors"
          >
            <Home className="w-5 h-5" />
            Back to Home
          </Link>
        </div>

        <div className="mt-8 pt-8 border-t border-slate-800">
          <p className="text-sm text-slate-500">
            If this problem persists, please contact support.
          </p>
        </div>
      </div>
    </div>
  );
}
