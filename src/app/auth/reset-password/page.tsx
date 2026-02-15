'use client';

import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';
import { FormEvent, useState, useEffect } from 'react';
import Link from 'next/link';

export default function ResetPasswordPage() {
  const router = useRouter();
  const supabase = createClient();

  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [isReady, setIsReady] = useState(false);
  const [sessionError, setSessionError] = useState<string | null>(null);

  useEffect(() => {
    // Handle the auth callback - exchange code for session
    const handleAuthCallback = async () => {
      try {
        // Get the code from URL if present (PKCE flow)
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');

        if (code) {
          // Exchange the code for a session
          const { error } = await supabase.auth.exchangeCodeForSession(code);
          if (error) {
            console.error('Code exchange error:', error);
            setSessionError(error.message);
            return;
          }
        }

        // Check if we have an active session (from hash fragment or code exchange)
        const { data: { session }, error: sessionErr } = await supabase.auth.getSession();

        if (sessionErr) {
          console.error('Session error:', sessionErr);
          setSessionError(sessionErr.message);
          return;
        }

        if (!session) {
          // Try to handle hash fragment (older flow)
          const hashParams = new URLSearchParams(window.location.hash.substring(1));
          const accessToken = hashParams.get('access_token');
          const refreshToken = hashParams.get('refresh_token');
          const type = hashParams.get('type');

          if (type === 'recovery' && accessToken && refreshToken) {
            const { error: setSessionErr } = await supabase.auth.setSession({
              access_token: accessToken,
              refresh_token: refreshToken,
            });

            if (setSessionErr) {
              console.error('Set session error:', setSessionErr);
              setSessionError(setSessionErr.message);
              return;
            }
          } else {
            setSessionError('Invalid or expired reset link. Please request a new one.');
            return;
          }
        }

        setIsReady(true);
      } catch (err: any) {
        console.error('Auth callback error:', err);
        setSessionError(err.message || 'Failed to process reset link');
      }
    };

    handleAuthCallback();
  }, [supabase.auth]);

  const validatePassword = (pwd: string): string[] => {
    const errors: string[] = [];
    if (pwd.length < 12) errors.push('At least 12 characters');
    if (!/[A-Z]/.test(pwd)) errors.push('One uppercase letter');
    if (!/[a-z]/.test(pwd)) errors.push('One lowercase letter');
    if (!/[0-9]/.test(pwd)) errors.push('One number');
    if (!/[!@#$%^&*()_+\-=\[\]{}|;':",./<>?]/.test(pwd)) errors.push('One special character');
    return errors;
  };

  const passwordErrors = validatePassword(password);
  const isPasswordValid = passwordErrors.length === 0;

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!isPasswordValid) {
      setError('Password does not meet requirements');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);

    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password: password,
      });

      if (updateError) {
        setError(updateError.message);
        return;
      }

      setSuccess(true);

      // Sign out and redirect to login after 3 seconds
      setTimeout(async () => {
        await supabase.auth.signOut();
        router.push('/auth/login');
      }, 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to reset password');
    } finally {
      setLoading(false);
    }
  };

  // Show loading while processing auth callback
  if (!isReady && !sessionError) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent mx-auto mb-4"></div>
          <div className="text-text-secondary">Processing reset link...</div>
        </div>
      </div>
    );
  }

  // Show error if session setup failed
  if (sessionError) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background px-4">
        <div className="max-w-md w-full text-center">
          <div className="bg-surface-primary rounded-2xl p-8 shadow-lg border border-border-secondary">
            <div className="text-6xl mb-4">:(</div>
            <h2 className="text-2xl font-bold text-text-primary mb-2">Reset Link Invalid</h2>
            <p className="text-text-secondary mb-6">{sessionError}</p>
            <Link
              href="/auth/login"
              className="inline-block px-4 py-2 bg-accent hover:bg-accent-hover text-white rounded-xl transition-colors"
            >
              Back to Login
            </Link>
          </div>
        </div>
      </div>
    );
  }

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background px-4">
        <div className="max-w-md w-full text-center">
          <div className="bg-surface-primary rounded-2xl p-8 shadow-lg border border-border-secondary">
            <div className="w-16 h-16 mx-auto mb-4 bg-green-500/20 rounded-full flex items-center justify-center">
              <svg className="w-8 h-8 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h2 className="text-2xl font-bold text-text-primary mb-2">Password Reset Successful!</h2>
            <p className="text-text-secondary">
              Your password has been updated. Redirecting to login...
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="max-w-md w-full">
        <div className="bg-surface-primary rounded-2xl p-8 shadow-lg border border-border-secondary">
          <h2 className="text-2xl font-semibold text-text-primary mb-2">
            Reset Your Password
          </h2>
          <p className="text-text-secondary mb-6 text-sm">
            Enter a new password for your account
          </p>
          <form className="space-y-4" onSubmit={handleSubmit}>
            {error && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-3">
                <p className="text-sm text-danger">{error}</p>
              </div>
            )}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-text-secondary mb-1.5">
                New Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-3 py-2.5 bg-surface-secondary border border-border-primary rounded-xl text-text-primary placeholder-text-tertiary focus:outline-none focus:ring-2 focus:ring-accent focus:border-transparent text-sm"
                placeholder="Enter new password"
              />
              {password && (
                <div className="mt-2 space-y-1">
                  {['At least 12 characters', 'One uppercase letter', 'One lowercase letter', 'One number', 'One special character'].map((req) => {
                    const met = !passwordErrors.includes(req);
                    return (
                      <div key={req} className={`text-xs flex items-center gap-1 ${met ? 'text-green-500' : 'text-text-tertiary'}`}>
                        <span>{met ? '\u2713' : '\u25CB'}</span>
                        <span>{req}</span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-text-secondary mb-1.5">
                Confirm Password
              </label>
              <input
                id="confirmPassword"
                name="confirmPassword"
                type="password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="w-full px-3 py-2.5 bg-surface-secondary border border-border-primary rounded-xl text-text-primary placeholder-text-tertiary focus:outline-none focus:ring-2 focus:ring-accent focus:border-transparent text-sm"
                placeholder="Confirm new password"
              />
              {confirmPassword && password !== confirmPassword && (
                <p className="mt-1 text-xs text-danger">Passwords do not match</p>
              )}
            </div>

            <button
              type="submit"
              disabled={loading || !isPasswordValid || password !== confirmPassword}
              className="w-full py-3 px-4 bg-accent hover:bg-accent-hover text-white font-semibold rounded-xl focus:outline-none focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:ring-offset-background disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
            >
              {loading ? 'Resetting...' : 'Reset Password'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
