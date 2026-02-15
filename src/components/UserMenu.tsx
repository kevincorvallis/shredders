'use client';

import { useAuth } from '@/hooks/useAuth';
import Link from 'next/link';
import { useState, useRef, useEffect } from 'react';

export function UserMenu() {
  const { user, profile, signOut, loading, isAuthenticated } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // Close menu on outside click
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const handleSignOut = async () => {
    await signOut();
    setIsOpen(false);
  };

  if (loading) {
    return (
      <div className="h-8 w-8 rounded-full bg-surface-secondary animate-pulse"></div>
    );
  }

  if (!isAuthenticated) {
    return (
      <Link
        href="/auth/login"
        className="px-4 py-2 rounded-lg text-sm font-medium bg-accent text-white hover:bg-accent-hover transition-colors"
      >
        Sign in
      </Link>
    );
  }

  const displayName = profile?.display_name || user?.email?.split('@')[0] || 'User';
  const firstLetter = displayName[0].toUpperCase();

  return (
    <div className="relative" ref={menuRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-surface-secondary/50 transition-colors"
      >
        <div className="h-8 w-8 rounded-full bg-accent flex items-center justify-center text-white font-semibold text-sm">
          {firstLetter}
        </div>
        <span className="hidden sm:block text-sm text-text-secondary">
          {displayName}
        </span>
        <svg
          className={`w-4 h-4 text-text-tertiary transition-transform ${
            isOpen ? 'rotate-180' : ''
          }`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M19 9l-7 7-7-7"
          />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-56 bg-surface-elevated rounded-lg shadow-lg py-1 border border-border-primary">
          <div className="px-4 py-3 border-b border-border-primary">
            <p className="text-sm font-medium text-text-primary">
              {displayName}
            </p>
            <p className="text-xs text-text-tertiary truncate">
              {user?.email}
            </p>
          </div>
          <Link
            href={`/profile/${profile?.username || user?.id}`}
            className="block px-4 py-2 text-sm text-text-secondary hover:bg-accent-subtle transition-colors"
            onClick={() => setIsOpen(false)}
          >
            Your Profile
          </Link>
          <Link
            href="/settings"
            className="block px-4 py-2 text-sm text-text-secondary hover:bg-accent-subtle transition-colors"
            onClick={() => setIsOpen(false)}
          >
            Settings
          </Link>
          <div className="border-t border-border-primary mt-1 pt-1">
            <button
              onClick={handleSignOut}
              className="block w-full text-left px-4 py-2 text-sm text-red-400 hover:bg-accent-subtle transition-colors"
            >
              Sign out
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
