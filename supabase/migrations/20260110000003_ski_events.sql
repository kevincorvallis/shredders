-- Migration: 004_ski_events
-- Description: Add ski events social feature with attendees and invite tokens
-- Created: 2024-01-19

-- ============================================
-- EVENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Creator reference
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Mountain reference (required)
    mountain_id VARCHAR(50) NOT NULL,

    -- Event details
    title VARCHAR(100) NOT NULL,
    notes TEXT,
    event_date DATE NOT NULL,
    departure_time TIME,
    departure_location VARCHAR(255),
    skill_level VARCHAR(20) CHECK (skill_level IN ('beginner', 'intermediate', 'advanced', 'expert', 'all')),

    -- Carpool info
    carpool_available BOOLEAN DEFAULT false,
    carpool_seats INTEGER CHECK (carpool_seats >= 0 AND carpool_seats <= 8),

    -- Event status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'completed')),

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Denormalized counts
    attendee_count INTEGER DEFAULT 0,
    going_count INTEGER DEFAULT 0,
    maybe_count INTEGER DEFAULT 0,

    -- Constraints
    CONSTRAINT events_title_length CHECK (char_length(title) >= 3 AND char_length(title) <= 100),
    CONSTRAINT events_notes_length CHECK (notes IS NULL OR char_length(notes) <= 2000),
    CONSTRAINT events_future_date CHECK (event_date >= CURRENT_DATE)
);

-- Indexes for events
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_mountain_id ON events(mountain_id);
CREATE INDEX idx_events_event_date ON events(event_date);
CREATE INDEX idx_events_status ON events(status) WHERE status = 'active';
CREATE INDEX idx_events_created_at ON events(created_at DESC);

-- Composite index for common queries (user's events sorted by date)
CREATE INDEX idx_events_user_upcoming ON events(user_id, event_date)
    WHERE status = 'active' AND event_date >= CURRENT_DATE;

-- ============================================
-- EVENT ATTENDEES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS event_attendees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- RSVP status
    status VARCHAR(20) DEFAULT 'invited' CHECK (status IN ('invited', 'going', 'maybe', 'declined')),

    -- Carpool details
    is_driver BOOLEAN DEFAULT false,
    needs_ride BOOLEAN DEFAULT false,
    pickup_location VARCHAR(255),
    passengers_count INTEGER DEFAULT 0 CHECK (passengers_count >= 0 AND passengers_count <= 8),

    -- Response tracking
    responded_at TIMESTAMP WITH TIME ZONE,
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Unique constraint (one entry per user per event)
    CONSTRAINT event_attendees_unique UNIQUE (event_id, user_id)
);

-- Indexes for event_attendees
CREATE INDEX idx_event_attendees_event_id ON event_attendees(event_id);
CREATE INDEX idx_event_attendees_user_id ON event_attendees(user_id);
CREATE INDEX idx_event_attendees_status ON event_attendees(status);
CREATE INDEX idx_event_attendees_going ON event_attendees(event_id, status) WHERE status = 'going';

-- ============================================
-- EVENT INVITE TOKENS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS event_invite_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Event reference
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,

    -- Token for URL
    token VARCHAR(64) NOT NULL UNIQUE,

    -- Token metadata
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Usage tracking
    uses_count INTEGER DEFAULT 0,
    max_uses INTEGER, -- NULL means unlimited

    -- Expiration
    expires_at TIMESTAMP WITH TIME ZONE,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT invite_token_length CHECK (char_length(token) >= 16)
);

-- Indexes for invite tokens
CREATE INDEX idx_event_invite_tokens_token ON event_invite_tokens(token);
CREATE INDEX idx_event_invite_tokens_event_id ON event_invite_tokens(event_id);
CREATE INDEX idx_event_invite_tokens_valid ON event_invite_tokens(token, expires_at)
    WHERE expires_at IS NULL OR expires_at > NOW();

-- ============================================
-- TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_events_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_events_updated_at
BEFORE UPDATE ON events
FOR EACH ROW
EXECUTE FUNCTION update_events_updated_at();

CREATE TRIGGER trigger_event_attendees_updated_at
BEFORE UPDATE ON event_attendees
FOR EACH ROW
EXECUTE FUNCTION update_events_updated_at();

-- Update attendee counts when attendees change
CREATE OR REPLACE FUNCTION update_event_attendee_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE events SET
            attendee_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = OLD.event_id AND status IN ('going', 'maybe')),
            going_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = OLD.event_id AND status = 'going'),
            maybe_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = OLD.event_id AND status = 'maybe'),
            updated_at = NOW()
        WHERE id = OLD.event_id;
        RETURN OLD;
    ELSE
        UPDATE events SET
            attendee_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = NEW.event_id AND status IN ('going', 'maybe')),
            going_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = NEW.event_id AND status = 'going'),
            maybe_count = (SELECT COUNT(*) FROM event_attendees WHERE event_id = NEW.event_id AND status = 'maybe'),
            updated_at = NOW()
        WHERE id = NEW.event_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_event_attendee_counts
AFTER INSERT OR UPDATE OR DELETE ON event_attendees
FOR EACH ROW
EXECUTE FUNCTION update_event_attendee_counts();

-- Auto-add creator as attendee with 'going' status
CREATE OR REPLACE FUNCTION auto_add_event_creator()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO event_attendees (event_id, user_id, status, is_driver, responded_at)
    VALUES (NEW.id, NEW.user_id, 'going', NEW.carpool_available, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_add_event_creator
AFTER INSERT ON events
FOR EACH ROW
EXECUTE FUNCTION auto_add_event_creator();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_invite_tokens ENABLE ROW LEVEL SECURITY;

-- Events: Public read for active events, authenticated users can create
CREATE POLICY "Events are viewable by everyone"
ON events FOR SELECT
USING (status = 'active');

CREATE POLICY "Users can create events"
ON events FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own events"
ON events FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own events"
ON events FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Service role full access
CREATE POLICY "Service role full access to events"
ON events FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Event Attendees: Visible to event participants
CREATE POLICY "Attendees viewable by authenticated users"
ON event_attendees FOR SELECT
TO authenticated
USING (
    -- Can see if user is an attendee or creator of the event
    user_id = (SELECT u.id FROM users u WHERE u.auth_user_id = auth.uid())
    OR EXISTS (
        SELECT 1 FROM events e
        WHERE e.id = event_id
        AND e.user_id = (SELECT u.id FROM users u WHERE u.auth_user_id = auth.uid())
    )
    OR EXISTS (
        SELECT 1 FROM event_attendees ea
        JOIN users u ON u.id = ea.user_id
        WHERE ea.event_id = event_attendees.event_id
        AND u.auth_user_id = auth.uid()
    )
);

CREATE POLICY "Users can RSVP to events"
ON event_attendees FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own attendance"
ON event_attendees FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can remove own attendance"
ON event_attendees FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Service role full access to event_attendees"
ON event_attendees FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Invite Tokens: Readable by anyone (for public links), writable by event creators
CREATE POLICY "Invite tokens are publicly readable"
ON event_invite_tokens FOR SELECT
USING (true);

CREATE POLICY "Event creators can create invite tokens"
ON event_invite_tokens FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = (SELECT auth_user_id FROM users WHERE id = created_by)
    AND EXISTS (
        SELECT 1 FROM events e
        JOIN users u ON u.id = e.user_id
        WHERE e.id = event_id
        AND u.auth_user_id = auth.uid()
    )
);

CREATE POLICY "Service role full access to invite_tokens"
ON event_invite_tokens FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- VIEWS
-- ============================================

-- View for upcoming events with creator info
CREATE OR REPLACE VIEW upcoming_events_with_creator AS
SELECT
    e.*,
    u.username AS creator_username,
    u.display_name AS creator_display_name,
    u.avatar_url AS creator_avatar_url
FROM events e
JOIN users u ON u.id = e.user_id
WHERE e.status = 'active'
AND e.event_date >= CURRENT_DATE
ORDER BY e.event_date ASC;

-- View for user's event feed (created + attending)
CREATE OR REPLACE VIEW user_event_feed AS
SELECT
    e.*,
    u.username AS creator_username,
    u.display_name AS creator_display_name,
    u.avatar_url AS creator_avatar_url,
    ea.status AS user_rsvp_status,
    ea.user_id AS attendee_user_id,
    CASE WHEN e.user_id = ea.user_id THEN true ELSE false END AS is_creator
FROM events e
JOIN users u ON u.id = e.user_id
JOIN event_attendees ea ON ea.event_id = e.id
WHERE e.status = 'active'
ORDER BY e.event_date ASC;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Generate secure invite token
CREATE OR REPLACE FUNCTION generate_invite_token()
RETURNS VARCHAR(64) AS $$
DECLARE
    chars VARCHAR(62) := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result VARCHAR(64) := '';
    i INTEGER;
BEGIN
    FOR i IN 1..32 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Check if invite token is valid
CREATE OR REPLACE FUNCTION is_invite_token_valid(p_token VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    v_token event_invite_tokens%ROWTYPE;
BEGIN
    SELECT * INTO v_token
    FROM event_invite_tokens
    WHERE token = p_token;

    IF v_token IS NULL THEN
        RETURN false;
    END IF;

    -- Check expiration
    IF v_token.expires_at IS NOT NULL AND v_token.expires_at < NOW() THEN
        RETURN false;
    END IF;

    -- Check max uses
    IF v_token.max_uses IS NOT NULL AND v_token.uses_count >= v_token.max_uses THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Increment invite token usage
CREATE OR REPLACE FUNCTION increment_invite_token_usage(p_token VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE event_invite_tokens
    SET uses_count = uses_count + 1
    WHERE token = p_token;
END;
$$ LANGUAGE plpgsql;

-- Get events for push notification reminders (morning-of)
CREATE OR REPLACE FUNCTION get_events_for_reminder(p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    event_id UUID,
    event_title VARCHAR(100),
    mountain_id VARCHAR(50),
    event_date DATE,
    departure_time TIME,
    user_id UUID,
    device_tokens TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id AS event_id,
        e.title AS event_title,
        e.mountain_id,
        e.event_date,
        e.departure_time,
        ea.user_id,
        ARRAY_AGG(pnt.device_token) AS device_tokens
    FROM events e
    JOIN event_attendees ea ON ea.event_id = e.id
    JOIN push_notification_tokens pnt ON pnt.user_id = ea.user_id AND pnt.is_active = true
    WHERE e.event_date = p_date
    AND e.status = 'active'
    AND ea.status = 'going'
    GROUP BY e.id, e.title, e.mountain_id, e.event_date, e.departure_time, ea.user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT SELECT ON upcoming_events_with_creator TO authenticated;
GRANT SELECT ON user_event_feed TO authenticated;
GRANT EXECUTE ON FUNCTION generate_invite_token() TO authenticated;
GRANT EXECUTE ON FUNCTION is_invite_token_valid(VARCHAR) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION increment_invite_token_usage(VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION get_events_for_reminder(DATE) TO service_role;
