-- Migration: Date Polling for Events
-- Allows event organizers to propose multiple dates and let attendees vote

-- Table: event_date_polls
CREATE TABLE IF NOT EXISTS event_date_polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,
    UNIQUE(event_id)
);

-- Table: event_date_options
CREATE TABLE IF NOT EXISTS event_date_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES event_date_polls(id) ON DELETE CASCADE,
    proposed_date DATE NOT NULL,
    proposed_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(poll_id, proposed_date)
);

-- Table: event_date_votes
CREATE TABLE IF NOT EXISTS event_date_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    option_id UUID NOT NULL REFERENCES event_date_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    vote TEXT NOT NULL CHECK (vote IN ('available', 'maybe', 'unavailable')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(option_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_date_polls_event ON event_date_polls(event_id);
CREATE INDEX IF NOT EXISTS idx_date_options_poll ON event_date_options(poll_id);
CREATE INDEX IF NOT EXISTS idx_date_votes_option ON event_date_votes(option_id);
CREATE INDEX IF NOT EXISTS idx_date_votes_user ON event_date_votes(user_id);

-- RLS policies
ALTER TABLE event_date_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_date_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_date_votes ENABLE ROW LEVEL SECURITY;

-- Polls: anyone authenticated can read, only event creator can create
CREATE POLICY "Anyone can read polls" ON event_date_polls
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert polls" ON event_date_polls
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update polls" ON event_date_polls
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Options: anyone can read, authenticated users can insert
CREATE POLICY "Anyone can read date options" ON event_date_options
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert date options" ON event_date_options
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Votes: anyone can read, authenticated users can insert/update their own
CREATE POLICY "Anyone can read votes" ON event_date_votes
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert votes" ON event_date_votes
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own votes" ON event_date_votes
    FOR UPDATE USING (auth.uid() IS NOT NULL);
