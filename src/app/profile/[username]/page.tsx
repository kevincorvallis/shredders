'use client';

import { useAuth } from '@/hooks/useAuth';
import { useParams, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function ProfilePage() {
  const { user, profile: currentUserProfile, isAuthenticated } = useAuth();
  const params = useParams();
  const router = useRouter();
  const username = params.username as string;

  const [profileData, setProfileData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const isOwnProfile = currentUserProfile?.username === username || user?.id === username;

  useEffect(() => {
    async function fetchProfile() {
      try {
        const supabase = createClient();

        const { data, error } = await supabase
          .from('users')
          .select('*')
          .or(`username.eq.${username},auth_user_id.eq.${username}`)
          .single();

        if (error) {
          setError('Profile not found');
        } else {
          setProfileData(data);
        }
      } catch (err: any) {
        setError(err.message || 'Failed to load profile');
      } finally {
        setLoading(false);
      }
    }

    fetchProfile();
  }, [username]);

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-gray-400">Loading profile...</div>
      </div>
    );
  }

  if (error || !profileData) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-400 mb-4">{error || 'Profile not found'}</p>
          <button
            onClick={() => router.back()}
            className="text-blue-400 hover:text-blue-300"
          >
            Go back
          </button>
        </div>
      </div>
    );
  }

  const displayName = profileData.display_name || profileData.username;
  const firstLetter = displayName[0].toUpperCase();

  return (
    <div className="min-h-screen bg-slate-950">
      <div className="max-w-4xl mx-auto px-4 py-8">
        {/* Profile Header */}
        <div className="bg-slate-900 rounded-lg border border-slate-800 p-8 mb-6">
          <div className="flex items-start gap-6">
            <div className="h-24 w-24 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold text-3xl flex-shrink-0">
              {firstLetter}
            </div>
            <div className="flex-1">
              <h1 className="text-3xl font-bold text-white mb-1">
                {displayName}
              </h1>
              <p className="text-gray-400 mb-4">@{profileData.username}</p>
              {profileData.bio && (
                <p className="text-gray-300 mb-4">{profileData.bio}</p>
              )}
              <div className="flex gap-4 text-sm text-gray-400">
                <span>
                  Joined {new Date(profileData.created_at).toLocaleDateString()}
                </span>
                {profileData.last_login_at && (
                  <span>
                    Last active {new Date(profileData.last_login_at).toLocaleDateString()}
                  </span>
                )}
              </div>
            </div>
            {isOwnProfile && (
              <button
                onClick={() => router.push('/settings')}
                className="px-4 py-2 rounded-lg text-sm font-medium bg-slate-800 text-white hover:bg-slate-700 transition-colors"
              >
                Edit Profile
              </button>
            )}
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-slate-900 rounded-lg border border-slate-800 p-6">
          <div className="border-b border-slate-800 mb-6">
            <div className="flex gap-4">
              <button className="px-4 py-2 text-sm font-medium text-white border-b-2 border-blue-500">
                Photos
              </button>
              <button className="px-4 py-2 text-sm font-medium text-gray-400 hover:text-white transition-colors">
                Check-ins
              </button>
              <button className="px-4 py-2 text-sm font-medium text-gray-400 hover:text-white transition-colors">
                Activity
              </button>
            </div>
          </div>

          {/* Content placeholder */}
          <div className="text-center py-12 text-gray-400">
            <p className="text-lg mb-2">No photos yet</p>
            <p className="text-sm">
              {isOwnProfile
                ? 'Upload your first photo from a webcam or mountain page'
                : `${displayName} hasn't uploaded any photos yet`}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
