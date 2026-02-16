-- Migration: 011_recurring_events
-- Description: Add support for recurring event series
-- Created: 2024-02-02

-- ============================================
-- EVENT SERIES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS event_series (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Creator reference
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Series details
    title VARCHAR(100) NOT NULL,
    notes TEXT,
    mountain_id VARCHAR(50) NOT NULL,

    -- Default event settings (inherited by instances)
    departure_time TIME,
    departure_location VARCHAR(255),
    skill_level VARCHAR(20) CHECK (skill_level IN ('beginner', 'intermediate', 'advanced', 'expert', 'all')),
    carpool_available BOOLEAN DEFAULT false,
    carpool_seats INTEGER CHECK (carpool_seats >= 0 AND carpool_seats <= 8),
    max_attendees INTEGER CHECK (max_attendees IS NULL OR (max_attendees >= 1 AND max_attendees <= 1000)),

    -- Recurrence settings
    -- Pattern: weekly, biweekly, monthly_day, monthly_weekday
    recurrence_pattern VARCHAR(20) NOT NULL CHECK (
        recurrence_pattern IN ('weekly', 'biweekly', 'monthly_day', 'monthly_weekday')
    ),

    -- For weekly/biweekly: day of week (0=Sunday, 1=Monday, ..., 6=Saturday)
    day_of_week INTEGER CHECK (day_of_week IS NULL OR (day_of_week >= 0 AND day_of_week <= 6)),

    -- For monthly_day: day of month (1-31)
    day_of_month INTEGER CHECK (day_of_month IS NULL OR (day_of_month >= 1 AND day_of_month <= 31)),

    -- For monthly_weekday: which occurrence (1st, 2nd, 3rd, 4th, -1=last)
    week_of_month INTEGER CHECK (week_of_month IS NULL OR (week_of_month >= -1 AND week_of_month <= 4)),

    -- Series bounds
    start_date DATE NOT NULL,
    end_date DATE, -- NULL means no end date

    -- Series status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'ended')),

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT series_title_length CHECK (char_length(title) >= 3 AND char_length(title) <= 100),
    CONSTRAINT series_notes_length CHECK (notes IS NULL OR char_length(notes) <= 2000)
);

-- Indexes for event_series
CREATE INDEX idx_event_series_user_id ON event_series(user_id);
CREATE INDEX idx_event_series_status ON event_series(status) WHERE status = 'active';
CREATE INDEX idx_event_series_mountain_id ON event_series(mountain_id);

-- ============================================
-- ADD SERIES REFERENCE TO EVENTS
-- ============================================

-- Add series_id column to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS series_id UUID REFERENCES event_series(id) ON DELETE SET NULL;

-- Flag to indicate if this instance has been modified from series defaults
ALTER TABLE events ADD COLUMN IF NOT EXISTS is_series_exception BOOLEAN DEFAULT false;

-- Index for series queries
CREATE INDEX IF NOT EXISTS idx_events_series_id ON events(series_id) WHERE series_id IS NOT NULL;

-- ============================================
-- TRIGGERS
-- ============================================

-- Update updated_at timestamp for event_series
CREATE TRIGGER trigger_event_series_updated_at
BEFORE UPDATE ON event_series
FOR EACH ROW
EXECUTE FUNCTION update_events_updated_at();

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Calculate next occurrence date for a series
CREATE OR REPLACE FUNCTION calculate_next_occurrence(
    p_pattern VARCHAR(20),
    p_day_of_week INTEGER,
    p_day_of_month INTEGER,
    p_week_of_month INTEGER,
    p_from_date DATE
)
RETURNS DATE AS $$
DECLARE
    v_next_date DATE;
    v_target_dow INTEGER;
    v_current_dow INTEGER;
    v_days_to_add INTEGER;
    v_first_of_month DATE;
    v_target_date DATE;
    v_week_count INTEGER;
BEGIN
    CASE p_pattern
        WHEN 'weekly' THEN
            -- Find next occurrence of this day of week
            v_current_dow := EXTRACT(DOW FROM p_from_date);
            v_days_to_add := (p_day_of_week - v_current_dow + 7) % 7;
            IF v_days_to_add = 0 THEN
                v_days_to_add := 7; -- Next week if today is the target day
            END IF;
            v_next_date := p_from_date + v_days_to_add;

        WHEN 'biweekly' THEN
            -- Find next occurrence, 2 weeks from target day
            v_current_dow := EXTRACT(DOW FROM p_from_date);
            v_days_to_add := (p_day_of_week - v_current_dow + 7) % 7;
            IF v_days_to_add = 0 THEN
                v_days_to_add := 14; -- Two weeks if today is the target day
            ELSIF v_days_to_add <= 7 THEN
                v_days_to_add := v_days_to_add; -- This week
            END IF;
            v_next_date := p_from_date + v_days_to_add;

        WHEN 'monthly_day' THEN
            -- Find next month with this day
            v_first_of_month := DATE_TRUNC('month', p_from_date)::DATE;
            v_target_date := v_first_of_month + (p_day_of_month - 1);

            -- Handle months with fewer days
            IF EXTRACT(DAY FROM (v_first_of_month + INTERVAL '1 month' - INTERVAL '1 day')) < p_day_of_month THEN
                v_target_date := (v_first_of_month + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
            END IF;

            IF v_target_date <= p_from_date THEN
                v_first_of_month := (v_first_of_month + INTERVAL '1 month')::DATE;
                v_target_date := v_first_of_month + (p_day_of_month - 1);
                IF EXTRACT(DAY FROM (v_first_of_month + INTERVAL '1 month' - INTERVAL '1 day')) < p_day_of_month THEN
                    v_target_date := (v_first_of_month + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
                END IF;
            END IF;
            v_next_date := v_target_date;

        WHEN 'monthly_weekday' THEN
            -- Find nth weekday of month (e.g., 2nd Saturday)
            v_first_of_month := DATE_TRUNC('month', p_from_date)::DATE;

            -- Find target date for current month
            IF p_week_of_month = -1 THEN
                -- Last occurrence of weekday in month
                v_target_date := (v_first_of_month + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
                WHILE EXTRACT(DOW FROM v_target_date) != p_day_of_week LOOP
                    v_target_date := v_target_date - 1;
                END LOOP;
            ELSE
                -- Nth occurrence of weekday
                v_target_date := v_first_of_month;
                WHILE EXTRACT(DOW FROM v_target_date) != p_day_of_week LOOP
                    v_target_date := v_target_date + 1;
                END LOOP;
                v_target_date := v_target_date + (7 * (p_week_of_month - 1));
            END IF;

            IF v_target_date <= p_from_date THEN
                -- Move to next month
                v_first_of_month := (v_first_of_month + INTERVAL '1 month')::DATE;
                IF p_week_of_month = -1 THEN
                    v_target_date := (v_first_of_month + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
                    WHILE EXTRACT(DOW FROM v_target_date) != p_day_of_week LOOP
                        v_target_date := v_target_date - 1;
                    END LOOP;
                ELSE
                    v_target_date := v_first_of_month;
                    WHILE EXTRACT(DOW FROM v_target_date) != p_day_of_week LOOP
                        v_target_date := v_target_date + 1;
                    END LOOP;
                    v_target_date := v_target_date + (7 * (p_week_of_month - 1));
                END IF;
            END IF;
            v_next_date := v_target_date;

        ELSE
            RAISE EXCEPTION 'Unknown recurrence pattern: %', p_pattern;
    END CASE;

    RETURN v_next_date;
END;
$$ LANGUAGE plpgsql;

-- Generate event instances for a series (next N months)
CREATE OR REPLACE FUNCTION generate_series_instances(
    p_series_id UUID,
    p_months_ahead INTEGER DEFAULT 3
)
RETURNS INTEGER AS $$
DECLARE
    v_series event_series%ROWTYPE;
    v_next_date DATE;
    v_end_date DATE;
    v_count INTEGER := 0;
    v_event_id UUID;
BEGIN
    -- Get series details
    SELECT * INTO v_series FROM event_series WHERE id = p_series_id;

    IF v_series IS NULL THEN
        RAISE EXCEPTION 'Series not found: %', p_series_id;
    END IF;

    IF v_series.status != 'active' THEN
        RETURN 0; -- Don't generate for inactive series
    END IF;

    -- Calculate end date for generation
    v_end_date := COALESCE(
        v_series.end_date,
        (CURRENT_DATE + (p_months_ahead || ' months')::INTERVAL)::DATE
    );

    -- Start from today or series start date, whichever is later
    v_next_date := GREATEST(CURRENT_DATE, v_series.start_date);

    -- Generate instances
    WHILE v_next_date <= v_end_date LOOP
        v_next_date := calculate_next_occurrence(
            v_series.recurrence_pattern,
            v_series.day_of_week,
            v_series.day_of_month,
            v_series.week_of_month,
            v_next_date
        );

        -- Check if we're still within bounds
        IF v_next_date > v_end_date THEN
            EXIT;
        END IF;

        -- Check if event already exists for this date
        IF NOT EXISTS (
            SELECT 1 FROM events
            WHERE series_id = p_series_id
            AND event_date = v_next_date
        ) THEN
            -- Create event instance
            INSERT INTO events (
                user_id,
                mountain_id,
                title,
                notes,
                event_date,
                departure_time,
                departure_location,
                skill_level,
                carpool_available,
                carpool_seats,
                max_attendees,
                series_id,
                is_series_exception
            ) VALUES (
                v_series.user_id,
                v_series.mountain_id,
                v_series.title,
                v_series.notes,
                v_next_date,
                v_series.departure_time,
                v_series.departure_location,
                v_series.skill_level,
                v_series.carpool_available,
                v_series.carpool_seats,
                v_series.max_attendees,
                p_series_id,
                false
            );

            v_count := v_count + 1;
        END IF;

        -- Move to next occurrence (add 1 day to avoid infinite loop)
        v_next_date := v_next_date + 1;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Cancel all future events in a series
CREATE OR REPLACE FUNCTION cancel_series(p_series_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Update series status
    UPDATE event_series SET status = 'ended' WHERE id = p_series_id;

    -- Cancel all future events
    UPDATE events
    SET status = 'cancelled'
    WHERE series_id = p_series_id
    AND event_date >= CURRENT_DATE
    AND status = 'active';

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE event_series ENABLE ROW LEVEL SECURITY;

-- Series are viewable by authenticated users
CREATE POLICY "Event series are viewable by authenticated users"
ON event_series FOR SELECT
TO authenticated
USING (status = 'active');

CREATE POLICY "Users can create event series"
ON event_series FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own event series"
ON event_series FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own event series"
ON event_series FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Service role full access to event_series"
ON event_series FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION calculate_next_occurrence(VARCHAR, INTEGER, INTEGER, INTEGER, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_series_instances(UUID, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION cancel_series(UUID) TO service_role;
