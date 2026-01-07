/**
 * useAuth Hook
 *
 * Provides authentication state and methods for React components
 */

'use client';

import { createClient } from '@/lib/supabase/client';
import { useEffect, useState } from 'react';
import type { User } from '@supabase/supabase-js';

interface AuthState {
  user: User | null;
  profile: any | null;
  loading: boolean;
  error: string | null;
}

export function useAuth() {
  const [state, setState] = useState<AuthState>({
    user: null,
    profile: null,
    loading: true,
    error: null,
  });

  const supabase = createClient();

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setState((prev) => ({
        ...prev,
        user: session?.user ?? null,
        loading: false,
      }));

      // Fetch user profile if logged in
      if (session?.user) {
        fetchProfile(session.user.id);
      }
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setState((prev) => ({
        ...prev,
        user: session?.user ?? null,
        loading: false,
      }));

      // Fetch profile when user logs in
      if (session?.user) {
        fetchProfile(session.user.id);
      } else {
        setState((prev) => ({ ...prev, profile: null }));
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const fetchProfile = async (userId: string) => {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('auth_user_id', userId)
      .single();

    if (error && error.code !== 'PGRST116') {
      console.error('Error fetching profile:', error);
      setState((prev) => ({ ...prev, error: error.message }));
    } else {
      setState((prev) => ({ ...prev, profile: data }));
    }
  };

  const signUp = async (email: string, password: string, username: string, displayName?: string) => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await fetch('/api/auth/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, username, displayName }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Signup failed');
      }

      setState((prev) => ({ ...prev, loading: false }));
      return { data, error: null };
    } catch (error: any) {
      setState((prev) => ({ ...prev, loading: false, error: error.message }));
      return { data: null, error: error.message };
    }
  };

  const signIn = async (email: string, password: string) => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Login failed');
      }

      setState((prev) => ({ ...prev, loading: false }));
      return { data, error: null };
    } catch (error: any) {
      setState((prev) => ({ ...prev, loading: false, error: error.message }));
      return { data: null, error: error.message };
    }
  };

  const signOut = async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await fetch('/api/auth/logout', {
        method: 'POST',
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Logout failed');
      }

      setState({ user: null, profile: null, loading: false, error: null });
      return { error: null };
    } catch (error: any) {
      setState((prev) => ({ ...prev, loading: false, error: error.message }));
      return { error: error.message };
    }
  };

  const updateProfile = async (updates: any) => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await fetch('/api/auth/user', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Update failed');
      }

      setState((prev) => ({
        ...prev,
        profile: data.profile,
        loading: false,
      }));

      return { data: data.profile, error: null };
    } catch (error: any) {
      setState((prev) => ({ ...prev, loading: false, error: error.message }));
      return { data: null, error: error.message };
    }
  };

  return {
    ...state,
    signUp,
    signIn,
    signOut,
    updateProfile,
    isAuthenticated: !!state.user,
  };
}
