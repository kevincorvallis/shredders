'use client';

import Link from 'next/link';
import { Mountain, Home, ArrowLeft } from 'lucide-react';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">
        <div className="mb-8">
          <Mountain className="w-20 h-20 text-sky-400 mx-auto mb-4" />
          <h1 className="text-6xl font-bold text-white mb-2">404</h1>
          <h2 className="text-2xl font-semibold text-slate-300 mb-4">
            Mountain Not Found
          </h2>
          <p className="text-slate-400">
            Looks like this trail leads nowhere. The page you're looking for doesn't exist.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            href="/"
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-sky-500 hover:bg-sky-600 text-white font-medium rounded-lg transition-colors"
          >
            <Home className="w-5 h-5" />
            Back to Home
          </Link>
          <button
            onClick={() => window.history.back()}
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white font-medium rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Go Back
          </button>
        </div>

        <div className="mt-8 pt-8 border-t border-slate-800">
          <p className="text-sm text-slate-500">
            Looking for mountain conditions?
          </p>
          <Link
            href="/mountains"
            className="text-sky-400 hover:text-sky-300 font-medium"
          >
            View All Mountains
          </Link>
        </div>
      </div>
    </div>
  );
}
