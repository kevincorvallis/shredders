-- Migration: 005_event_comments
-- Description: Add event comments/discussion feature with RSVP gating
-- Created: 2026-01-29

-- ============================================
-- EVENT COMMENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS event_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Comment content
    content TEXT NOT NULL,

    -- Threading support (nullable for top-level comments)
    parent_id UUID REFERENCES event_comments(id) ON DELETE CASCADE,

    -- Soft delete
    is_deleted BOOLEAN DEFAULT false,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT event_comments_content_length CHECK (char_length(content) >= 1 AND char_length(content) <= 2000)
);

-- Indexes for event_comments
CREATE INDEX idx_event_comments_event_id ON event_comments(event_id);
CREATE INDEX idx_event_comments_user_id ON event_comments(user_id);
CREATE INDEX idx_event_comments_parent_id ON event_comments(parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX idx_event_comments_created_at ON event_comments(created_at DESC);
CREATE INDEX idx_event_comments_active ON event_comments(event_id, is_deleted) WHERE is_deleted = false;

-- ============================================
-- TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE TRIGGER trigger_event_comments_updated_at
BEFORE UPDATE ON event_comments
FOR EACH ROW
EXECUTE FUNCTION update_events_updated_at();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE event_comments ENABLE ROW LEVEL SECURITY;

-- Comments: Readable by event participants (RSVP'd users or event creator)
CREATE POLICY "Event comments readable by participants"
ON event_comments FOR SELECT
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
        WHERE ea.event_id = event_comments.event_id
        AND u.auth_user_id = auth.uid()
        AND ea.status IN ('going', 'maybe')
    )
);

-- Comments: Insertable by event participants
CREATE POLICY "Event participants can comment"
ON event_comments FOR INSERT
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
        WHERE ea.event_id = event_comments.event_id
        AND u.auth_user_id = auth.uid()
        AND ea.status IN ('going', 'maybe')
    )
);

-- Comments: Users can update/delete their own comments
CREATE POLICY "Users can update own comments"
ON event_comments FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own comments"
ON event_comments FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Service role full access
CREATE POLICY "Service role full access to event_comments"
ON event_comments FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- DENORMALIZED COUNT ON EVENTS (OPTIONAL)
-- ============================================

-- Add comment_count column to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS comment_count INTEGER DEFAULT 0;

-- Trigger to update comment count
CREATE OR REPLACE FUNCTION update_event_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.is_deleted = true) THEN
        UPDATE events SET
            comment_count = (
                SELECT COUNT(*) FROM event_comments
                WHERE event_id = COALESCE(NEW.event_id, OLD.event_id)
                AND is_deleted = false
            ),
            updated_at = NOW()
        WHERE id = COALESCE(NEW.event_id, OLD.event_id);
        RETURN COALESCE(NEW, OLD);
    ELSE
        UPDATE events SET
            comment_count = (
                SELECT COUNT(*) FROM event_comments
                WHERE event_id = NEW.event_id
                AND is_deleted = false
            ),
            updated_at = NOW()
        WHERE id = NEW.event_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_event_comment_count
AFTER INSERT OR UPDATE OR DELETE ON event_comments
FOR EACH ROW
EXECUTE FUNCTION update_event_comment_count();

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Allow anon to see comment counts (for non-RSVP'd users)
CREATE OR REPLACE VIEW event_comment_counts AS
SELECT
    event_id,
    COUNT(*) FILTER (WHERE is_deleted = false) AS comment_count
FROM event_comments
GROUP BY event_id;

GRANT SELECT ON event_comment_counts TO anon, authenticated;
