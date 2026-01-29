'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function EmailVerifiedPage() {
  const router = useRouter();
  const [countdown, setCountdown] = useState(3);
  const [showConfetti, setShowConfetti] = useState(true);

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

    // Hide confetti after 3 seconds
    const confettiTimer = setTimeout(() => setShowConfetti(false), 3000);

    return () => {
      clearInterval(timer);
      clearTimeout(confettiTimer);
    };
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center px-4 py-8 relative overflow-hidden bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
      {/* Animated background elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -left-40 w-80 h-80 bg-green-500/20 rounded-full blur-3xl animate-pulse" />
        <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-blue-400/20 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-green-600/10 rounded-full blur-3xl" />
      </div>

      {/* Confetti effect */}
      {showConfetti && (
        <>
          {Array.from({ length: 50 }).map((_, i) => (
            <div
              key={i}
              className="absolute animate-confetti pointer-events-none"
              style={{
                left: `${Math.random() * 100}%`,
                top: '-10px',
                animationDelay: `${Math.random() * 2}s`,
                animationDuration: `${2 + Math.random() * 2}s`,
              }}
            >
              <div
                className="w-3 h-3 rounded-sm"
                style={{
                  backgroundColor: ['#10B981', '#3B82F6', '#8B5CF6', '#F59E0B', '#EF4444', '#EC4899'][Math.floor(Math.random() * 6)],
                  transform: `rotate(${Math.random() * 360}deg)`,
                }}
              />
            </div>
          ))}
        </>
      )}

      {/* Snowflakes */}
      {Array.from({ length: 15 }).map((_, i) => (
        <div
          key={i}
          className="absolute text-white/30 text-lg animate-float pointer-events-none"
          style={{
            left: `${Math.random() * 100}%`,
            top: `${Math.random() * 100}%`,
            animationDelay: `${Math.random() * 5}s`,
            animationDuration: `${8 + Math.random() * 4}s`,
          }}
        >
          ❄
        </div>
      ))}

      {/* Main content */}
      <div className="max-w-md w-full relative z-10">
        {/* Card */}
        <div className="bg-white/10 backdrop-blur-xl rounded-2xl p-8 shadow-2xl border border-white/20 text-center">
          {/* Animated checkmark icon */}
          <div className="relative inline-block mb-6">
            <div className="w-24 h-24 mx-auto bg-gradient-to-br from-green-400 to-green-600 rounded-full flex items-center justify-center shadow-lg shadow-green-500/30 animate-scale-in">
              <svg className="w-12 h-12 text-white animate-check-draw" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            {/* Sparkle effect */}
            <div className="absolute -top-2 -right-2 text-2xl animate-sparkle">✨</div>
            <div className="absolute -bottom-1 -left-2 text-xl animate-sparkle" style={{ animationDelay: '0.3s' }}>✨</div>
          </div>

          <h1 className="text-2xl font-bold text-white mb-2">Email Verified!</h1>
          <p className="text-blue-200/80 mb-2">
            Welcome to the crew! Your account is ready.
          </p>

          {/* First achievement badge */}
          <div className="inline-flex items-center gap-2 bg-gradient-to-r from-amber-500/20 to-orange-500/20 border border-amber-500/30 rounded-full px-4 py-2 mb-6">
            <span className="text-xl">🎿</span>
            <span className="text-amber-200 font-medium text-sm">First Tracks Badge Unlocked!</span>
          </div>

          <div className="bg-white/5 rounded-xl p-4 mb-6 border border-white/10">
            <p className="text-sm text-blue-200/70">
              Redirecting to the app in <span className="font-bold text-white">{countdown}</span> seconds...
            </p>
          </div>

          {/* Continue button */}
          <Link
            href="/?verified=true"
            className="block w-full py-3 px-4 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white font-semibold rounded-xl shadow-lg shadow-green-500/30 focus:outline-none focus:ring-2 focus:ring-green-400 transition-all duration-200"
          >
            Let&apos;s Go! 🏔️
          </Link>
        </div>

        {/* Footer */}
        <p className="mt-6 text-center text-xs text-blue-200/50">
          Time to track some powder days!
        </p>
      </div>

      {/* CSS for custom animations */}
      <style jsx>{`
        @keyframes float {
          0%, 100% { transform: translateY(0) rotate(0deg); opacity: 0.3; }
          50% { transform: translateY(-20px) rotate(180deg); opacity: 0.6; }
        }
        @keyframes scale-in {
          0% { transform: scale(0); }
          50% { transform: scale(1.2); }
          100% { transform: scale(1); }
        }
        @keyframes check-draw {
          0% { stroke-dasharray: 0 100; }
          100% { stroke-dasharray: 100 0; }
        }
        @keyframes sparkle {
          0%, 100% { opacity: 0; transform: scale(0.5); }
          50% { opacity: 1; transform: scale(1); }
        }
        @keyframes confetti {
          0% {
            transform: translateY(0) rotate(0deg);
            opacity: 1;
          }
          100% {
            transform: translateY(100vh) rotate(720deg);
            opacity: 0;
          }
        }
        .animate-float {
          animation: float 8s ease-in-out infinite;
        }
        .animate-scale-in {
          animation: scale-in 0.5s ease-out forwards;
        }
        .animate-check-draw {
          stroke-dasharray: 100;
          animation: check-draw 0.8s ease-out 0.3s forwards;
        }
        .animate-sparkle {
          animation: sparkle 1.5s ease-in-out infinite;
        }
        .animate-confetti {
          animation: confetti 3s ease-out forwards;
        }
      `}</style>
    </div>
  );
}
