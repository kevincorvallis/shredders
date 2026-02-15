'use client';

import { useAuth } from '@/hooks/useAuth';
import { useRouter } from 'next/navigation';
import { FormEvent, useState, useEffect } from 'react';

export default function SettingsPage() {
  const { user, profile, updateProfile, loading, isAuthenticated } = useAuth();
  const router = useRouter();

  const [displayName, setDisplayName] = useState('');
  const [bio, setBio] = useState('');
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  useEffect(() => {
    if (!isAuthenticated && !loading) {
      router.push('/auth/login');
    }
  }, [isAuthenticated, loading, router]);

  useEffect(() => {
    if (profile) {
      setDisplayName(profile.display_name || '');
      setBio(profile.bio || '');
    }
  }, [profile]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setMessage(null);

    const { error } = await updateProfile({
      displayName,
      bio,
    });

    setSaving(false);

    if (error) {
      setMessage({ type: 'error', text: error });
    } else {
      setMessage({ type: 'success', text: 'Profile updated successfully' });
    }
  };

  if (loading || !isAuthenticated) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-text-tertiary">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-2xl mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold text-text-primary mb-8">Settings</h1>

        {/* Profile Settings */}
        <div className="bg-surface-primary rounded-lg border border-border-secondary p-6 mb-6">
          <h2 className="text-xl font-semibold text-text-primary mb-4">Profile Settings</h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            {message && (
              <div
                className={`rounded-lg p-4 ${
                  message.type === 'success'
                    ? 'bg-green-500/10 text-green-400 border border-green-500/20'
                    : 'bg-red-500/10 text-red-400 border border-red-500/20'
                }`}
              >
                {message.text}
              </div>
            )}

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-text-secondary mb-2">
                Email
              </label>
              <input
                id="email"
                type="email"
                value={user?.email || ''}
                disabled
                className="w-full px-3 py-2 bg-surface-secondary border border-border-primary rounded-lg text-text-tertiary cursor-not-allowed"
              />
              <p className="text-xs text-text-quaternary mt-1">Email cannot be changed</p>
            </div>

            <div>
              <label htmlFor="username" className="block text-sm font-medium text-text-secondary mb-2">
                Username
              </label>
              <input
                id="username"
                type="text"
                value={profile?.username || ''}
                disabled
                className="w-full px-3 py-2 bg-surface-secondary border border-border-primary rounded-lg text-text-tertiary cursor-not-allowed"
              />
              <p className="text-xs text-text-quaternary mt-1">Username cannot be changed</p>
            </div>

            <div>
              <label htmlFor="displayName" className="block text-sm font-medium text-text-secondary mb-2">
                Display Name
              </label>
              <input
                id="displayName"
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className="w-full px-3 py-2 bg-surface-secondary border border-border-primary rounded-lg text-text-primary focus:outline-none focus:ring-2 focus:ring-accent focus:border-transparent"
                placeholder="How you want to be displayed"
              />
            </div>

            <div>
              <label htmlFor="bio" className="block text-sm font-medium text-text-secondary mb-2">
                Bio
              </label>
              <textarea
                id="bio"
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                rows={4}
                className="w-full px-3 py-2 bg-surface-secondary border border-border-primary rounded-lg text-text-primary focus:outline-none focus:ring-2 focus:ring-accent focus:border-transparent resize-none"
                placeholder="Tell us about yourself"
              />
            </div>

            <button
              type="submit"
              disabled={saving}
              className="w-full px-4 py-2 bg-accent text-text-primary rounded-lg hover:bg-accent-hover transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
            >
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </form>
        </div>

        {/* Account Information */}
        <div className="bg-surface-primary rounded-lg border border-border-secondary p-6">
          <h2 className="text-xl font-semibold text-text-primary mb-4">Account Information</h2>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between">
              <span className="text-text-tertiary">Account created</span>
              <span className="text-text-primary">
                {profile?.created_at
                  ? new Date(profile.created_at).toLocaleDateString()
                  : 'Unknown'}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-text-tertiary">Last login</span>
              <span className="text-text-primary">
                {profile?.last_login_at
                  ? new Date(profile.last_login_at).toLocaleDateString()
                  : 'Unknown'}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
