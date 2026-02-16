-- Setup Script: setup-avatars-bucket.sql
-- Description: Create dedicated avatars storage bucket with RLS policies
-- Run this in Supabase SQL Editor
-- Created: 2026-01-29

-- ============================================================
-- Create the avatars storage bucket
-- ============================================================

-- Insert the bucket configuration
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,  -- Public read access for avatars
    1048576,  -- 1MB file size limit (1024 * 1024)
    ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================================
-- RLS Policies for avatars bucket
-- ============================================================

-- Policy: Anyone can view avatars (public bucket)
CREATE POLICY "Public avatar read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Policy: Authenticated users can upload their own avatar
-- Path format: {userId}/avatar_{timestamp}.jpg
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can update their own avatar
CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can delete their own avatar
CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================
-- Helper function to get avatar URL
-- ============================================================

-- Create or replace function to get public avatar URL
CREATE OR REPLACE FUNCTION get_avatar_url(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    avatar_path TEXT;
    bucket_url TEXT;
BEGIN
    -- Get the most recent avatar for this user
    SELECT name INTO avatar_path
    FROM storage.objects
    WHERE bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = user_id::text
    ORDER BY created_at DESC
    LIMIT 1;

    IF avatar_path IS NULL THEN
        RETURN NULL;
    END IF;

    -- Construct the public URL
    -- Note: This assumes the standard Supabase storage URL format
    RETURN 'avatars/' || avatar_path;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Verification queries (run these to verify setup)
-- ============================================================

-- Check bucket was created:
-- SELECT * FROM storage.buckets WHERE id = 'avatars';

-- Check policies were created:
-- SELECT policyname, cmd FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';

-- ============================================================
-- Notes
-- ============================================================

-- File path structure: {userId}/avatar_{timestamp}.jpg
-- Example: "550e8400-e29b-41d4-a716-446655440000/avatar_1706529600.jpg"
--
-- Maximum file size: 1MB (1048576 bytes)
-- Allowed formats: JPEG, PNG, WebP
--
-- The bucket is public for read access, so avatar URLs can be shared
-- Only authenticated users can upload/update/delete, and only their own avatars
