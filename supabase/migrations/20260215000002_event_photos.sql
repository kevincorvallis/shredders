-- Migration: 007_event_photos
-- Description: Add event photos feature with Supabase Storage integration
-- Created: 2026-01-29

-- ============================================
-- EVENT PHOTOS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS event_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Photo data
    storage_path VARCHAR(500) NOT NULL,  -- Path in Supabase Storage
    url TEXT NOT NULL,                    -- Public URL
    thumbnail_url TEXT,                   -- Thumbnail URL (optional)

    -- Metadata
    caption TEXT,
    width INTEGER,
    height INTEGER,
    file_size INTEGER,                    -- Size in bytes
    mime_type VARCHAR(50) DEFAULT 'image/jpeg',

    -- Soft delete
    is_deleted BOOLEAN DEFAULT false,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT event_photos_caption_length CHECK (caption IS NULL OR char_length(caption) <= 500),
    CONSTRAINT event_photos_storage_path_not_empty CHECK (char_length(storage_path) > 0)
);

-- Indexes for event_photos
CREATE INDEX idx_event_photos_event_id ON event_photos(event_id);
CREATE INDEX idx_event_photos_user_id ON event_photos(user_id);
CREATE INDEX idx_event_photos_created_at ON event_photos(created_at DESC);
CREATE INDEX idx_event_photos_active ON event_photos(event_id, is_deleted) WHERE is_deleted = false;

-- ============================================
-- TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE TRIGGER trigger_event_photos_updated_at
BEFORE UPDATE ON event_photos
FOR EACH ROW
EXECUTE FUNCTION update_events_updated_at();

-- Record photo upload activity
CREATE OR REPLACE FUNCTION record_photo_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO event_activity (event_id, user_id, activity_type, metadata)
        VALUES (
            NEW.event_id,
            NEW.user_id,
            'photo_uploaded',
            jsonb_build_object(
                'photo_id', NEW.id,
                'has_caption', NEW.caption IS NOT NULL
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_record_photo_activity
AFTER INSERT ON event_photos
FOR EACH ROW
EXECUTE FUNCTION record_photo_activity();

-- ============================================
-- UPDATE EVENT_ACTIVITY TABLE
-- Add photo_uploaded type if not exists
-- ============================================

-- Add photo_uploaded to activity_type check constraint
ALTER TABLE event_activity DROP CONSTRAINT IF EXISTS event_activity_activity_type_check;
ALTER TABLE event_activity ADD CONSTRAINT event_activity_activity_type_check
CHECK (activity_type IN (
    'rsvp_going',
    'rsvp_maybe',
    'rsvp_declined',
    'comment_posted',
    'milestone_reached',
    'event_created',
    'event_updated',
    'photo_uploaded'
));

-- ============================================
-- PHOTO COUNT ON EVENTS
-- ============================================

-- Add photo_count column to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS photo_count INTEGER DEFAULT 0;

-- Trigger to update photo count
CREATE OR REPLACE FUNCTION update_event_photo_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.is_deleted = true) THEN
        UPDATE events SET
            photo_count = (
                SELECT COUNT(*) FROM event_photos
                WHERE event_id = COALESCE(NEW.event_id, OLD.event_id)
                AND is_deleted = false
            ),
            updated_at = NOW()
        WHERE id = COALESCE(NEW.event_id, OLD.event_id);
        RETURN COALESCE(NEW, OLD);
    ELSE
        UPDATE events SET
            photo_count = (
                SELECT COUNT(*) FROM event_photos
                WHERE event_id = NEW.event_id
                AND is_deleted = false
            ),
            updated_at = NOW()
        WHERE id = NEW.event_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_event_photo_count
AFTER INSERT OR UPDATE OR DELETE ON event_photos
FOR EACH ROW
EXECUTE FUNCTION update_event_photo_count();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE event_photos ENABLE ROW LEVEL SECURITY;

-- Photos: Readable by event participants (RSVP'd users or event creator)
CREATE POLICY "Event photos readable by participants"
ON event_photos FOR SELECT
TO authenticated
USING (
    -- User is the event creator
    EXISTS (
        SELECT 1 FROM events e
        JOIN users u ON u.id = e.user_id
        WHERE e.id = event_id
        AND u.auth_user_id = auth.uid()
    )
    OR
    -- User has RSVP'd to the event
    EXISTS (
        SELECT 1 FROM event_attendees ea
        JOIN users u ON u.id = ea.user_id
        WHERE ea.event_id = event_photos.event_id
        AND u.auth_user_id = auth.uid()
        AND ea.status IN ('going', 'maybe')
    )
);

-- Photos: Insertable by event participants
CREATE POLICY "Event participants can upload photos"
ON event_photos FOR INSERT
TO authenticated
WITH CHECK (
    -- User is the event creator
    EXISTS (
        SELECT 1 FROM events e
        JOIN users u ON u.id = e.user_id
        WHERE e.id = event_id
        AND u.auth_user_id = auth.uid()
    )
    OR
    -- User has RSVP'd to the event
    EXISTS (
        SELECT 1 FROM event_attendees ea
        JOIN users u ON u.id = ea.user_id
        WHERE ea.event_id = event_photos.event_id
        AND u.auth_user_id = auth.uid()
        AND ea.status IN ('going', 'maybe')
    )
);

-- Photos: Users can update/delete their own photos
CREATE POLICY "Users can update own photos"
ON event_photos FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own photos"
ON event_photos FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Service role full access
CREATE POLICY "Service role full access to event_photos"
ON event_photos FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- STORAGE BUCKET SETUP
-- Run this in Supabase Dashboard or via API
-- ============================================

-- Create event-photos bucket (run manually in Supabase)
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--     'event-photos',
--     'event-photos',
--     true,
--     5242880,  -- 5MB max
--     ARRAY['image/jpeg', 'image/png', 'image/heif', 'image/webp']
-- );

-- Storage policies (run manually)
-- CREATE POLICY "Event photos are publicly accessible"
-- ON storage.objects FOR SELECT
-- USING (bucket_id = 'event-photos');

-- CREATE POLICY "Authenticated users can upload event photos"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'event-photos');

-- CREATE POLICY "Users can delete own event photos"
-- ON storage.objects FOR DELETE
-- TO authenticated
-- USING (bucket_id = 'event-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================
-- PHOTO COUNT VIEW (for non-RSVP'd users)
-- ============================================

CREATE OR REPLACE VIEW event_photo_counts AS
SELECT
    event_id,
    COUNT(*) FILTER (WHERE is_deleted = false) AS photo_count
FROM event_photos
GROUP BY event_id;

GRANT SELECT ON event_photo_counts TO anon, authenticated;
