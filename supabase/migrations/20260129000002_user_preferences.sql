-- Migration: Add user preferences for favorites and units
-- Description: Sync favorite mountains from iOS and store units preference

-- Add favorite mountain IDs array
ALTER TABLE users ADD COLUMN IF NOT EXISTS favorite_mountain_ids TEXT[] DEFAULT '{}';

-- Add units preference (imperial/metric)
ALTER TABLE users ADD COLUMN IF NOT EXISTS units_preference TEXT DEFAULT 'imperial'
    CHECK (units_preference IN ('imperial', 'metric'));

-- Index for quick lookups on users with preferences set
CREATE INDEX IF NOT EXISTS idx_users_preferences ON users (id)
    WHERE favorite_mountain_ids != '{}' OR units_preference != 'imperial';

-- Comment for documentation
COMMENT ON COLUMN users.favorite_mountain_ids IS 'Array of mountain IDs the user has favorited (max 5)';
COMMENT ON COLUMN users.units_preference IS 'User preference for units: imperial (default) or metric';
