-- Migration: 010_event_capacity_waitlist
-- Description: Add capacity limits and waitlist functionality for events
-- Created: 2024-02-02

-- ============================================
-- SCHEMA CHANGES
-- ============================================

-- Add max_attendees column to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS max_attendees INTEGER;
ALTER TABLE events ADD CONSTRAINT events_max_attendees_check
    CHECK (max_attendees IS NULL OR (max_attendees >= 1 AND max_attendees <= 1000));

-- Add waitlist status to event_attendees
-- First drop the existing constraint and recreate with 'waitlist' status
ALTER TABLE event_attendees DROP CONSTRAINT IF EXISTS event_attendees_status_check;
ALTER TABLE event_attendees ADD CONSTRAINT event_attendees_status_check
    CHECK (status IN ('invited', 'going', 'maybe', 'declined', 'waitlist'));

-- Add waitlist_position column to track queue order
ALTER TABLE event_attendees ADD COLUMN IF NOT EXISTS waitlist_position INTEGER;

-- Add index for waitlist queries
CREATE INDEX IF NOT EXISTS idx_event_attendees_waitlist
    ON event_attendees(event_id, waitlist_position)
    WHERE status = 'waitlist';

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Check if event is at capacity
CREATE OR REPLACE FUNCTION is_event_at_capacity(p_event_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_max_attendees INTEGER;
    v_current_going INTEGER;
BEGIN
    SELECT max_attendees, going_count INTO v_max_attendees, v_current_going
    FROM events
    WHERE id = p_event_id;

    -- No limit set means unlimited capacity
    IF v_max_attendees IS NULL THEN
        RETURN false;
    END IF;

    RETURN v_current_going >= v_max_attendees;
END;
$$ LANGUAGE plpgsql;

-- Get next waitlist position for an event
CREATE OR REPLACE FUNCTION get_next_waitlist_position(p_event_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_max_position INTEGER;
BEGIN
    SELECT COALESCE(MAX(waitlist_position), 0) INTO v_max_position
    FROM event_attendees
    WHERE event_id = p_event_id AND status = 'waitlist';

    RETURN v_max_position + 1;
END;
$$ LANGUAGE plpgsql;

-- Promote next person from waitlist when a spot opens
CREATE OR REPLACE FUNCTION promote_from_waitlist(p_event_id UUID)
RETURNS UUID AS $$
DECLARE
    v_promoted_user_id UUID;
    v_event_title VARCHAR(100);
    v_event_date DATE;
BEGIN
    -- Get the next person on waitlist (lowest position number)
    SELECT user_id INTO v_promoted_user_id
    FROM event_attendees
    WHERE event_id = p_event_id AND status = 'waitlist'
    ORDER BY waitlist_position ASC
    LIMIT 1;

    IF v_promoted_user_id IS NOT NULL THEN
        -- Promote them to 'going' status
        UPDATE event_attendees
        SET status = 'going',
            waitlist_position = NULL,
            responded_at = NOW()
        WHERE event_id = p_event_id AND user_id = v_promoted_user_id;

        -- Reorder remaining waitlist positions
        WITH reordered AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY waitlist_position) as new_position
            FROM event_attendees
            WHERE event_id = p_event_id AND status = 'waitlist'
        )
        UPDATE event_attendees ea
        SET waitlist_position = r.new_position
        FROM reordered r
        WHERE ea.id = r.id;

        -- Get event info for notification (handled by application layer)
        SELECT title, event_date INTO v_event_title, v_event_date
        FROM events WHERE id = p_event_id;

        -- Log the promotion in activity if activity table exists
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'event_activity') THEN
            INSERT INTO event_activity (event_id, user_id, activity_type, metadata)
            VALUES (p_event_id, v_promoted_user_id, 'rsvp_going',
                    jsonb_build_object('promoted_from_waitlist', true));
        END IF;
    END IF;

    RETURN v_promoted_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Auto-promote from waitlist when someone declines or changes status
CREATE OR REPLACE FUNCTION handle_waitlist_promotion()
RETURNS TRIGGER AS $$
DECLARE
    v_max_attendees INTEGER;
    v_current_going INTEGER;
BEGIN
    -- Only handle when someone leaves the 'going' status
    IF TG_OP = 'UPDATE' AND OLD.status = 'going' AND NEW.status != 'going' THEN
        -- Check if there's capacity and waitlisted people
        SELECT max_attendees, going_count INTO v_max_attendees, v_current_going
        FROM events WHERE id = NEW.event_id;

        -- If we now have capacity and there are waitlisted people, promote one
        IF v_max_attendees IS NOT NULL AND v_current_going < v_max_attendees THEN
            PERFORM promote_from_waitlist(NEW.event_id);
        END IF;
    END IF;

    -- Handle deletion of 'going' attendee
    IF TG_OP = 'DELETE' AND OLD.status = 'going' THEN
        SELECT max_attendees INTO v_max_attendees
        FROM events WHERE id = OLD.event_id;

        IF v_max_attendees IS NOT NULL THEN
            PERFORM promote_from_waitlist(OLD.event_id);
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_handle_waitlist_promotion
AFTER UPDATE OR DELETE ON event_attendees
FOR EACH ROW
EXECUTE FUNCTION handle_waitlist_promotion();

-- ============================================
-- UPDATE EXISTING COUNTS TRIGGER
-- ============================================

-- Update the attendee counts trigger to include waitlist count
ALTER TABLE events ADD COLUMN IF NOT EXISTS waitlist_count INTEGER DEFAULT 0;

-- Update the count trigger function
CREATE OR REPLACE FUNCTION update_event_attendee_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE events SET
            attendee_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = OLD.event_id AND status IN ('going', 'maybe')),
            going_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = OLD.event_id AND status = 'going'),
            maybe_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = OLD.event_id AND status = 'maybe'),
            waitlist_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = OLD.event_id AND status = 'waitlist'),
            updated_at = NOW()
        WHERE id = OLD.event_id;
        RETURN OLD;
    ELSE
        UPDATE events SET
            attendee_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = NEW.event_id AND status IN ('going', 'maybe')),
            going_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = NEW.event_id AND status = 'going'),
            maybe_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = NEW.event_id AND status = 'maybe'),
            waitlist_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = NEW.event_id AND status = 'waitlist'),
            updated_at = NOW()
        WHERE id = NEW.event_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION is_event_at_capacity(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_waitlist_position(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION promote_from_waitlist(UUID) TO service_role;
