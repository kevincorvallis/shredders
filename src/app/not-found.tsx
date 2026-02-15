'use client';

import Link from 'next/link';
import { Mountain, Home, ArrowLeft } from 'lucide-react';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">
        <div className="mb-8">
          <Mountain className="w-20 h-20 text-accent mx-auto mb-4" />
          <h1 className="text-6xl font-bold text-text-primary mb-2">404</h1>
          <h2 className="text-2xl font-semibold text-text-secondary mb-4">
            Mountain Not Found
          </h2>
          <p className="text-text-tertiary">
            Looks like this trail leads nowhere. The page you're looking for doesn't exist.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            href="/"
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-accent hover:bg-accent-hover text-text-primary font-medium rounded-lg transition-colors"
          >
            <Home className="w-5 h-5" />
            Back to Home
          </Link>
          <button
            onClick={() => window.history.back()}
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-surface-secondary hover:bg-surface-tertiary text-text-primary font-medium rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Go Back
          </button>
        </div>

        <div className="mt-8 pt-8 border-t border-border-secondary">
          <p className="text-sm text-text-quaternary">
            Looking for mountain conditions?
          </p>
          <Link
            href="/mountains"
            className="text-accent hover:text-accent-hover font-medium"
          >
            View All Mountains
          </Link>
        </div>
      </div>
    </div>
  );
}
