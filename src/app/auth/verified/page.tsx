'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function EmailVerifiedPage() {
  const router = useRouter();
  const [countdown, setCountdown] = useState(3);

  useEffect(() => {
    // Countdown timer
    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          // Redirect with verified param to trigger onboarding flow
          router.push('/?verified=true');
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      clearInterval(timer);
    };
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center px-4 py-8 bg-background">
      {/* Main content */}
      <div className="max-w-md w-full">
        {/* Card */}
        <div className="bg-surface-primary rounded-2xl p-8 shadow-lg border border-border-secondary text-center">
          {/* Checkmark icon */}
          <div className="relative inline-block mb-6">
            <div className="w-24 h-24 mx-auto bg-green-500 rounded-full flex items-center justify-center shadow-lg">
              <svg className="w-12 h-12 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>

          <h1 className="text-2xl font-bold text-text-primary mb-2">Email Verified!</h1>
          <p className="text-text-secondary mb-2">
            Welcome to the crew! Your account is ready.
          </p>

          {/* First achievement badge */}
          <div className="inline-flex items-center gap-2 bg-amber-500/10 border border-amber-500/20 rounded-full px-4 py-2 mb-6">
            <span className="text-xl">🎿</span>
            <span className="text-amber-500 font-medium text-sm">First Tracks Badge Unlocked!</span>
          </div>

          <div className="bg-surface-secondary rounded-xl p-4 mb-6 border border-border-primary">
            <p className="text-sm text-text-secondary">
              Redirecting to the app in <span className="font-bold text-text-primary">{countdown}</span> seconds...
            </p>
          </div>

          {/* Continue button */}
          <Link
            href="/?verified=true"
            className="block w-full py-3 px-4 bg-accent hover:bg-accent-hover text-white font-semibold rounded-xl transition-all duration-200"
          >
            Let&apos;s Go! 🏔️
          </Link>
        </div>

        {/* Footer */}
        <p className="mt-6 text-center text-xs text-text-quaternary">
          Time to track some powder days!
        </p>
      </div>
    </div>
  );
}
