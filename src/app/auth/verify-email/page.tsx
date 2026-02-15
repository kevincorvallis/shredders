'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';

export default function VerifyEmailPage() {
  const searchParams = useSearchParams();
  const email = searchParams.get('email') || '';

  const [resending, setResending] = useState(false);
  const [resendSuccess, setResendSuccess] = useState(false);
  const [resendError, setResendError] = useState<string | null>(null);
  const [cooldown, setCooldown] = useState(0);

  // Handle cooldown timer
  useEffect(() => {
    if (cooldown > 0) {
      const timer = setTimeout(() => setCooldown(cooldown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [cooldown]);

  const handleResendEmail = async () => {
    if (cooldown > 0 || !email) return;

    setResending(true);
    setResendError(null);
    setResendSuccess(false);

    try {
      const response = await fetch('/api/auth/resend-verification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });

      const data = await response.json();

      if (!response.ok) {
        if (response.status === 429) {
          setResendError(`Too many attempts. Please try again in ${Math.ceil(data.retryAfter / 60)} minutes.`);
        } else {
          setResendError(data.error || 'Failed to resend email');
        }
        return;
      }

      setResendSuccess(true);
      setCooldown(60); // 60 second cooldown after successful resend
    } catch (err) {
      setResendError('Failed to resend verification email');
    } finally {
      setResending(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4 py-8 bg-background">
      {/* Main content */}
      <div className="max-w-md w-full">
        {/* Card */}
        <div className="bg-surface-primary rounded-2xl p-8 shadow-lg border border-border-secondary text-center">
          {/* Envelope icon */}
          <div className="relative inline-block mb-6">
            <div className="w-24 h-24 mx-auto bg-accent rounded-full flex items-center justify-center shadow-lg">
              <svg className="w-12 h-12 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </div>
            {/* Notification badge */}
            <div className="absolute -top-1 -right-1 w-6 h-6 bg-green-500 rounded-full flex items-center justify-center animate-pulse">
              <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
              </svg>
            </div>
          </div>

          <h1 className="text-2xl font-bold text-text-primary mb-2">Check your email</h1>
          <p className="text-text-secondary mb-6">
            We&apos;ve sent a verification link to
            {email && (
              <span className="block font-medium text-text-primary mt-1">{email}</span>
            )}
          </p>

          <div className="bg-surface-secondary rounded-xl p-4 mb-6 border border-border-primary">
            <p className="text-sm text-text-secondary">
              Click the link in your email to verify your account and start tracking powder days with the crew.
            </p>
          </div>

          {/* Resend section */}
          <div className="space-y-3">
            {resendSuccess && (
              <div className="bg-green-500/10 border border-green-500/30 rounded-lg p-3">
                <p className="text-sm text-green-400">Verification email sent! Check your inbox.</p>
              </div>
            )}

            {resendError && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-3">
                <p className="text-sm text-danger">{resendError}</p>
              </div>
            )}

            <button
              onClick={handleResendEmail}
              disabled={resending || cooldown > 0 || !email}
              className="w-full py-3 px-4 bg-surface-secondary hover:bg-surface-tertiary text-text-primary font-medium rounded-xl border border-border-primary focus:outline-none focus:ring-2 focus:ring-accent disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
            >
              {resending ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-text-primary" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  Sending...
                </span>
              ) : cooldown > 0 ? (
                `Resend in ${cooldown}s`
              ) : (
                "Didn't receive it? Resend email"
              )}
            </button>
          </div>

          {/* Divider */}
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-border-secondary" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-4 bg-surface-primary text-text-tertiary">or</span>
            </div>
          </div>

          {/* Sign in link */}
          <Link
            href="/auth/login"
            className="block w-full py-2.5 px-4 border border-border-primary text-text-primary font-medium rounded-xl text-center hover:bg-surface-secondary transition-all duration-200 text-sm"
          >
            Already verified? Sign in
          </Link>
        </div>

        {/* Footer */}
        <p className="mt-6 text-center text-xs text-text-quaternary">
          Check your spam folder if you don&apos;t see the email.
        </p>
      </div>
    </div>
  );
}
