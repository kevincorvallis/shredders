-- Migration: 006_event_activity
-- Description: Add event activity tracking for timeline (RSVPs, comments, milestones)
-- Created: 2026-01-29

-- ============================================
-- EVENT ACTIVITY TABLE
-- Stores computed/denormalized activity for fast queries
-- ============================================

CREATE TABLE IF NOT EXISTS event_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Activity type
    activity_type VARCHAR(30) NOT NULL CHECK (activity_type IN (
        'rsvp_going',
        'rsvp_maybe',
        'rsvp_declined',
        'comment_posted',
        'milestone_reached',
        'event_created',
        'event_updated'
    )),

    -- Activity metadata (JSON for flexibility)
    -- For milestones: {"milestone": 5, "label": "5 people going!"}
    -- For comments: {"comment_id": "uuid", "preview": "Great powder day..."}
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for event_activity
CREATE INDEX idx_event_activity_event_id ON event_activity(event_id);
CREATE INDEX idx_event_activity_user_id ON event_activity(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_event_activity_created_at ON event_activity(created_at DESC);
CREATE INDEX idx_event_activity_type ON event_activity(activity_type);

-- Composite index for common query (event activities by time)
CREATE INDEX idx_event_activity_event_timeline ON event_activity(event_id, created_at DESC);

-- ============================================
-- TRIGGERS TO AUTO-POPULATE ACTIVITY
-- ============================================

-- Trigger: Record RSVP activity
CREATE OR REPLACE FUNCTION record_rsvp_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Only record if status changed to going, maybe, or declined
    IF NEW.status IN ('going', 'maybe', 'declined') THEN
        -- Don't record if this is just an update with same status
        IF TG_OP = 'UPDATE' AND OLD.status = NEW.status THEN
            RETURN NEW;
        END IF;

        INSERT INTO event_activity (event_id, user_id, activity_type, metadata)
        VALUES (
            NEW.event_id,
            NEW.user_id,
            'rsvp_' || NEW.status,
            jsonb_build_object(
                'previous_status', CASE WHEN TG_OP = 'UPDATE' THEN OLD.status ELSE NULL END
            )
        );

        -- Check for milestones
        PERFORM check_event_milestones(NEW.event_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_record_rsvp_activity
AFTER INSERT OR UPDATE ON event_attendees
FOR EACH ROW
EXECUTE FUNCTION record_rsvp_activity();

-- Trigger: Record comment activity
CREATE OR REPLACE FUNCTION record_comment_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO event_activity (event_id, user_id, activity_type, metadata)
        VALUES (
            NEW.event_id,
            NEW.user_id,
            'comment_posted',
            jsonb_build_object(
                'comment_id', NEW.id,
                'preview', LEFT(NEW.content, 100),
                'is_reply', NEW.parent_id IS NOT NULL
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_record_comment_activity
AFTER INSERT ON event_comments
FOR EACH ROW
EXECUTE FUNCTION record_comment_activity();

-- Trigger: Record event creation
CREATE OR REPLACE FUNCTION record_event_created_activity()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO event_activity (event_id, user_id, activity_type, metadata)
    VALUES (
        NEW.id,
        NEW.user_id,
        'event_created',
        '{}'::jsonb
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_record_event_created
AFTER INSERT ON events
FOR EACH ROW
EXECUTE FUNCTION record_event_created_activity();

-- ============================================
-- MILESTONE CHECKING FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION check_event_milestones(p_event_id UUID)
RETURNS VOID AS $$
DECLARE
    v_going_count INTEGER;
    v_milestones INTEGER[] := ARRAY[5, 10, 15, 20, 25, 50, 100];
    v_milestone INTEGER;
    v_existing_milestone INTEGER;
BEGIN
    -- Get current going count
    SELECT going_count INTO v_going_count
    FROM events
    WHERE id = p_event_id;

    -- Check each milestone
    FOREACH v_milestone IN ARRAY v_milestones
    LOOP
        -- Only trigger if we just hit this milestone
        IF v_going_count = v_milestone THEN
            -- Check if we already recorded this milestone
            SELECT (metadata->>'milestone')::integer INTO v_existing_milestone
            FROM event_activity
            WHERE event_id = p_event_id
            AND activity_type = 'milestone_reached'
            AND (metadata->>'milestone')::integer = v_milestone;

            IF v_existing_milestone IS NULL THEN
                -- Record the milestone
                INSERT INTO event_activity (event_id, user_id, activity_type, metadata)
                VALUES (
                    p_event_id,
                    NULL, -- No specific user for milestones
                    'milestone_reached',
                    jsonb_build_object(
                        'milestone', v_milestone,
                        'label', v_milestone || ' people going!'
                    )
                );
            END IF;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE event_activity ENABLE ROW LEVEL SECURITY;

-- Activity: Readable by event participants (RSVP'd users or event creator)
CREATE POLICY "Event activity readable by participants"
ON event_activity FOR SELECT
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
        WHERE ea.event_id = event_activity.event_id
        AND u.auth_user_id = auth.uid()
        AND ea.status IN ('going', 'maybe')
    )
);

-- Service role full access
CREATE POLICY "Service role full access to event_activity"
ON event_activity FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- ACTIVITY COUNT VIEW (for non-RSVP'd users)
-- ============================================

CREATE OR REPLACE VIEW event_activity_counts AS
SELECT
    event_id,
    COUNT(*) AS total_activity_count,
    COUNT(*) FILTER (WHERE activity_type LIKE 'rsvp_%') AS rsvp_count,
    COUNT(*) FILTER (WHERE activity_type = 'comment_posted') AS comment_count,
    COUNT(*) FILTER (WHERE activity_type = 'milestone_reached') AS milestone_count
FROM event_activity
GROUP BY event_id;

GRANT SELECT ON event_activity_counts TO anon, authenticated;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION check_event_milestones(UUID) TO service_role;
