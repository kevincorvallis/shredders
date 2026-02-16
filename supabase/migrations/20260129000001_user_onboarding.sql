-- Migration: 008_user_onboarding.sql
-- Description: Add onboarding fields to users table for profile completion flow
-- Created: 2026-01-29

-- ============================================================
-- Add onboarding columns to users table
-- ============================================================

-- Has user completed the onboarding flow?
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE;

-- Skiing experience level
-- Values: beginner, intermediate, advanced, expert
ALTER TABLE users ADD COLUMN IF NOT EXISTS experience_level TEXT;

-- Preferred terrain types (array)
-- Values: groomers, moguls, trees, park, backcountry
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_terrain TEXT[] DEFAULT '{}';

-- Season pass type
-- Values: none, ikon, epic, mountain_specific, other
ALTER TABLE users ADD COLUMN IF NOT EXISTS season_pass_type TEXT;

-- Home mountain (references mountains by ID)
ALTER TABLE users ADD COLUMN IF NOT EXISTS home_mountain_id TEXT;

-- Timestamp when onboarding was completed
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

-- Timestamp when onboarding was skipped
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_skipped_at TIMESTAMPTZ;

-- ============================================================
-- Add constraints
-- ============================================================

-- Validate experience level values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_experience_level_check'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_experience_level_check
            CHECK (experience_level IS NULL OR experience_level IN ('beginner', 'intermediate', 'advanced', 'expert'));
    END IF;
END $$;

-- Validate season pass type values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_season_pass_type_check'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_season_pass_type_check
            CHECK (season_pass_type IS NULL OR season_pass_type IN ('none', 'ikon', 'epic', 'mountain_specific', 'other'));
    END IF;
END $$;

-- ============================================================
-- Create indexes for common queries
-- ============================================================

-- Index for finding users who haven't completed onboarding
CREATE INDEX IF NOT EXISTS idx_users_onboarding_incomplete
    ON users (has_completed_onboarding)
    WHERE has_completed_onboarding = FALSE;

-- Index for finding users by experience level
CREATE INDEX IF NOT EXISTS idx_users_experience_level
    ON users (experience_level)
    WHERE experience_level IS NOT NULL;

-- Index for finding users by home mountain
CREATE INDEX IF NOT EXISTS idx_users_home_mountain
    ON users (home_mountain_id)
    WHERE home_mountain_id IS NOT NULL;

-- ============================================================
-- Update RLS policies (if needed)
-- ============================================================

-- Users can read their own onboarding data
-- (Should already be covered by existing RLS policies on users table)

-- Users can update their own onboarding data
-- (Should already be covered by existing RLS policies on users table)

-- ============================================================
-- Add comment for documentation
-- ============================================================

COMMENT ON COLUMN users.has_completed_onboarding IS 'Whether user has completed the onboarding flow';
COMMENT ON COLUMN users.experience_level IS 'Skiing experience level: beginner, intermediate, advanced, expert';
COMMENT ON COLUMN users.preferred_terrain IS 'Array of preferred terrain types: groomers, moguls, trees, park, backcountry';
COMMENT ON COLUMN users.season_pass_type IS 'Type of season pass: none, ikon, epic, mountain_specific, other';
COMMENT ON COLUMN users.home_mountain_id IS 'Reference to the user home mountain';
COMMENT ON COLUMN users.onboarding_completed_at IS 'Timestamp when user completed onboarding';
COMMENT ON COLUMN users.onboarding_skipped_at IS 'Timestamp when user skipped onboarding';
