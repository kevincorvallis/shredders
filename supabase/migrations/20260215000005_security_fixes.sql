-- Migration: Security fixes
-- Drop orphaned photos table, configure storage buckets, add storage RLS policies

-- ============================================================================
-- DROP ORPHANED PHOTOS TABLE
-- This was a Cloudinary-era table with RLS disabled and no code references
-- ============================================================================
DROP TABLE IF EXISTS photos;

-- ============================================================================
-- STORAGE BUCKET CONFIGURATION
-- ============================================================================

-- Configure event-photos bucket (bucket already exists)
UPDATE storage.buckets
SET file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/heif', 'image/webp']
WHERE id = 'event-photos';

-- Create user-photos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-photos',
    'user-photos',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/heif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/heif', 'image/webp'];

-- ============================================================================
-- STORAGE POLICIES: user-photos bucket
-- ============================================================================

-- Public read
CREATE POLICY "User photos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'user-photos');

-- Authenticated upload to own folder
CREATE POLICY "Users can upload to own user-photos folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'user-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner delete
CREATE POLICY "Users can delete own user photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'user-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- STORAGE POLICIES: event-photos bucket
-- ============================================================================

-- Public read
CREATE POLICY "Event photos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'event-photos');

-- Authenticated upload
CREATE POLICY "Authenticated users can upload event photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'event-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner delete
CREATE POLICY "Users can delete own event photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'event-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);
