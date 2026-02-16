-- Shredders Complete Schema for Supabase
-- Combines mountain data + social features
-- PostgreSQL schema optimized for Supabase with RLS (Row Level Security)

-- ============================================================================
-- EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABLE: mountain_status (migrated from original RDS schema)
-- ============================================================================
CREATE TABLE IF NOT EXISTS mountain_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mountain_id VARCHAR(50) NOT NULL,
    is_open BOOLEAN DEFAULT false,
    percent_open INTEGER CHECK (percent_open >= 0 AND percent_open <= 100),

    lifts_open INTEGER DEFAULT 0,
    lifts_total INTEGER DEFAULT 0,
    runs_open INTEGER DEFAULT 0,
    runs_total INTEGER DEFAULT 0,

    message TEXT,
    conditions_message TEXT,

    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    source_url TEXT,
    scraper_version VARCHAR(20),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for mountain_status
CREATE INDEX IF NOT EXISTS idx_mountain_status_mountain_id ON mountain_status(mountain_id);
CREATE INDEX IF NOT EXISTS idx_mountain_status_scraped_at ON mountain_status(scraped_at DESC);
CREATE INDEX IF NOT EXISTS idx_mountain_status_mountain_date ON mountain_status(mountain_id, scraped_at DESC);

-- ============================================================================
-- TABLE: scraper_runs (tracking table)
-- ============================================================================
CREATE TABLE IF NOT EXISTS scraper_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id VARCHAR(100) UNIQUE NOT NULL,
    total_mountains INTEGER,
    successful_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0,

    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_ms INTEGER,

    status VARCHAR(20) DEFAULT 'running',
    error_message TEXT,
    triggered_by VARCHAR(50),
    environment VARCHAR(20)
);

-- Indexes for scraper_runs
CREATE INDEX IF NOT EXISTS idx_scraper_runs_started_at ON scraper_runs(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_scraper_runs_status ON scraper_runs(status);

-- ============================================================================
-- TABLE: users (social features)
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Auth0/Supabase user ID
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    avatar_url TEXT,
    bio TEXT,
    home_mountain_id VARCHAR(50),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,

    notification_preferences JSONB DEFAULT '{
        "weather_alerts": true,
        "powder_alerts": true,
        "comment_replies": true,
        "likes": true
    }'::jsonb,

    CONSTRAINT users_username_length CHECK (char_length(username) >= 3),
    CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Indexes for users
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_home_mountain ON users(home_mountain_id) WHERE home_mountain_id IS NOT NULL;

-- ============================================================================
-- TABLE: user_photos
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mountain_id VARCHAR(50) NOT NULL,

    -- Supabase Storage reference
    storage_path TEXT NOT NULL,
    storage_bucket VARCHAR(100) NOT NULL DEFAULT 'user-photos',
    public_url TEXT,
    thumbnail_url TEXT,

    caption TEXT,
    taken_at TIMESTAMP WITH TIME ZONE,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    file_size_bytes INTEGER,
    mime_type VARCHAR(50),
    width INTEGER,
    height INTEGER,

    is_approved BOOLEAN DEFAULT true,
    is_flagged BOOLEAN DEFAULT false,
    moderation_status VARCHAR(20) DEFAULT 'approved',

    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,

    location_name VARCHAR(255),

    CONSTRAINT user_photos_file_size CHECK (file_size_bytes > 0 AND file_size_bytes <= 10485760)
);

-- Indexes for user_photos
CREATE INDEX IF NOT EXISTS idx_user_photos_mountain_id ON user_photos(mountain_id, uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_photos_user_id ON user_photos(user_id, uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_photos_approved ON user_photos(is_approved, uploaded_at DESC) WHERE is_approved = true;

-- ============================================================================
-- TABLE: comments
-- ============================================================================
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    mountain_id VARCHAR(50),
    webcam_id VARCHAR(100),
    photo_id UUID REFERENCES user_photos(id) ON DELETE CASCADE,

    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,

    is_flagged BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    likes_count INTEGER DEFAULT 0,

    CONSTRAINT comments_content_length CHECK (char_length(content) > 0 AND char_length(content) <= 2000),
    CONSTRAINT comments_has_target CHECK (
        (mountain_id IS NOT NULL)::int +
        (webcam_id IS NOT NULL)::int +
        (photo_id IS NOT NULL)::int = 1
    )
);

-- Indexes for comments
CREATE INDEX IF NOT EXISTS idx_comments_mountain_id ON comments(mountain_id, created_at DESC) WHERE mountain_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_comments_webcam_id ON comments(webcam_id, created_at DESC) WHERE webcam_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_comments_photo_id ON comments(photo_id, created_at DESC) WHERE photo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON comments(parent_comment_id, created_at ASC) WHERE parent_comment_id IS NOT NULL;

-- ============================================================================
-- TABLE: check_ins
-- ============================================================================
CREATE TABLE IF NOT EXISTS check_ins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mountain_id VARCHAR(50) NOT NULL,

    check_in_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    check_out_time TIMESTAMP WITH TIME ZONE,

    trip_report TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),

    snow_quality VARCHAR(50),
    crowd_level VARCHAR(50),

    weather_conditions JSONB,

    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT true
);

-- Indexes for check_ins
CREATE INDEX IF NOT EXISTS idx_check_ins_mountain_id ON check_ins(mountain_id, check_in_time DESC);
CREATE INDEX IF NOT EXISTS idx_check_ins_user_id ON check_ins(user_id, check_in_time DESC);
CREATE INDEX IF NOT EXISTS idx_check_ins_public ON check_ins(is_public, check_in_time DESC) WHERE is_public = true;

-- ============================================================================
-- TABLE: likes
-- ============================================================================
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    photo_id UUID REFERENCES user_photos(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    check_in_id UUID REFERENCES check_ins(id) ON DELETE CASCADE,
    webcam_id VARCHAR(100),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT likes_has_target CHECK (
        (photo_id IS NOT NULL)::int +
        (comment_id IS NOT NULL)::int +
        (check_in_id IS NOT NULL)::int +
        (webcam_id IS NOT NULL)::int = 1
    ),
    CONSTRAINT likes_unique_photo UNIQUE (user_id, photo_id),
    CONSTRAINT likes_unique_comment UNIQUE (user_id, comment_id),
    CONSTRAINT likes_unique_check_in UNIQUE (user_id, check_in_id),
    CONSTRAINT likes_unique_webcam UNIQUE (user_id, webcam_id)
);

-- Indexes for likes
CREATE INDEX IF NOT EXISTS idx_likes_photo_id ON likes(photo_id, created_at DESC) WHERE photo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_comment_id ON likes(comment_id, created_at DESC) WHERE comment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_check_in_id ON likes(check_in_id, created_at DESC) WHERE check_in_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_webcam_id ON likes(webcam_id, created_at DESC) WHERE webcam_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id, created_at DESC);

-- ============================================================================
-- TABLE: push_notification_tokens
-- ============================================================================
CREATE TABLE IF NOT EXISTS push_notification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    device_token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL,
    device_id VARCHAR(255),

    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    app_version VARCHAR(50),
    os_version VARCHAR(50),

    CONSTRAINT push_tokens_unique UNIQUE (user_id, device_token),
    CONSTRAINT push_tokens_platform_valid CHECK (platform IN ('ios', 'android', 'web'))
);

-- Indexes for push_notification_tokens
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_notification_tokens(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_push_tokens_active ON push_notification_tokens(is_active, platform) WHERE is_active = true;

-- ============================================================================
-- TABLE: alert_subscriptions
-- ============================================================================
CREATE TABLE IF NOT EXISTS alert_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mountain_id VARCHAR(50) NOT NULL,

    weather_alerts BOOLEAN DEFAULT true,
    powder_alerts BOOLEAN DEFAULT true,
    powder_threshold INTEGER DEFAULT 70,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT alert_subs_unique UNIQUE (user_id, mountain_id),
    CONSTRAINT powder_threshold_range CHECK (powder_threshold >= 0 AND powder_threshold <= 100)
);

-- Indexes for alert_subscriptions
CREATE INDEX IF NOT EXISTS idx_alert_subs_mountain_id ON alert_subscriptions(mountain_id);
CREATE INDEX IF NOT EXISTS idx_alert_subs_user_id ON alert_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_subs_weather ON alert_subscriptions(mountain_id, weather_alerts) WHERE weather_alerts = true;
CREATE INDEX IF NOT EXISTS idx_alert_subs_powder ON alert_subscriptions(mountain_id, powder_alerts) WHERE powder_alerts = true;

-- ============================================================================
-- TRIGGERS: Auto-update like/comment counts
-- ============================================================================

-- Update photo likes count
CREATE OR REPLACE FUNCTION update_photo_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.photo_id IS NOT NULL THEN
        UPDATE user_photos SET likes_count = likes_count + 1 WHERE id = NEW.photo_id;
    ELSIF TG_OP = 'DELETE' AND OLD.photo_id IS NOT NULL THEN
        UPDATE user_photos SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.photo_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_photo_likes ON likes;
CREATE TRIGGER trigger_update_photo_likes
AFTER INSERT OR DELETE ON likes
FOR EACH ROW
EXECUTE FUNCTION update_photo_likes_count();

-- Update comment likes count
CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.comment_id IS NOT NULL THEN
        UPDATE comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
    ELSIF TG_OP = 'DELETE' AND OLD.comment_id IS NOT NULL THEN
        UPDATE comments SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.comment_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_comment_likes ON likes;
CREATE TRIGGER trigger_update_comment_likes
AFTER INSERT OR DELETE ON likes
FOR EACH ROW
EXECUTE FUNCTION update_comment_likes_count();

-- Update check-in likes count
CREATE OR REPLACE FUNCTION update_check_in_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.check_in_id IS NOT NULL THEN
        UPDATE check_ins SET likes_count = likes_count + 1 WHERE id = NEW.check_in_id;
    ELSIF TG_OP = 'DELETE' AND OLD.check_in_id IS NOT NULL THEN
        UPDATE check_ins SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.check_in_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_check_in_likes ON likes;
CREATE TRIGGER trigger_update_check_in_likes
AFTER INSERT OR DELETE ON likes
FOR EACH ROW
EXECUTE FUNCTION update_check_in_likes_count();

-- Update photo comments count
CREATE OR REPLACE FUNCTION update_photo_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.photo_id IS NOT NULL AND NEW.is_deleted = false THEN
        UPDATE user_photos SET comments_count = comments_count + 1 WHERE id = NEW.photo_id;
    ELSIF TG_OP = 'DELETE' AND OLD.photo_id IS NOT NULL THEN
        UPDATE user_photos SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.photo_id;
    ELSIF TG_OP = 'UPDATE' AND NEW.photo_id IS NOT NULL AND OLD.is_deleted = false AND NEW.is_deleted = true THEN
        UPDATE user_photos SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = NEW.photo_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_photo_comments ON comments;
CREATE TRIGGER trigger_update_photo_comments
AFTER INSERT OR DELETE OR UPDATE ON comments
FOR EACH ROW
EXECUTE FUNCTION update_photo_comments_count();

-- Update user updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_users_updated_at ON users;
CREATE TRIGGER trigger_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_alert_subs_updated_at ON alert_subscriptions;
CREATE TRIGGER trigger_alert_subs_updated_at
BEFORE UPDATE ON alert_subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS: Helpful views for common queries
-- ============================================================================

-- Latest mountain status per mountain
CREATE OR REPLACE VIEW latest_mountain_status AS
SELECT DISTINCT ON (mountain_id)
    id,
    mountain_id,
    is_open,
    percent_open,
    lifts_open,
    lifts_total,
    runs_open,
    runs_total,
    message,
    conditions_message,
    scraped_at,
    source_url
FROM mountain_status
ORDER BY mountain_id, scraped_at DESC;

-- Recent activity per mountain
CREATE OR REPLACE VIEW mountain_recent_activity AS
SELECT
    mountain_id,
    'photo' AS activity_type,
    id,
    user_id,
    uploaded_at AS activity_time,
    likes_count,
    comments_count
FROM user_photos
WHERE is_approved = true
UNION ALL
SELECT
    mountain_id,
    'check_in' AS activity_type,
    id,
    user_id,
    check_in_time AS activity_time,
    likes_count,
    comments_count
FROM check_ins
WHERE is_public = true
ORDER BY activity_time DESC;

-- ============================================================================
-- FUNCTIONS: Helper functions
-- ============================================================================

-- Get mountain history
CREATE OR REPLACE FUNCTION get_mountain_history(
    p_mountain_id VARCHAR(50),
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    scraped_at TIMESTAMP WITH TIME ZONE,
    lifts_open INTEGER,
    runs_open INTEGER,
    message TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ms.scraped_at,
        ms.lifts_open,
        ms.runs_open,
        ms.message
    FROM mountain_status ms
    WHERE ms.mountain_id = p_mountain_id
        AND ms.scraped_at >= NOW() - (p_days || ' days')::INTERVAL
    ORDER BY ms.scraped_at DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Cleanup old mountain status (keep 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_mountain_status()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM mountain_status
    WHERE scraped_at < NOW() - INTERVAL '90 days';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - Supabase Best Practice
-- ============================================================================

-- Enable RLS on all social tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_subscriptions ENABLE ROW LEVEL SECURITY;

-- Users: Anyone can read, users can update their own profile
CREATE POLICY "Users are viewable by everyone" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

-- Photos: Public photos viewable by all, users can manage their own
CREATE POLICY "Approved photos are viewable by everyone" ON user_photos
    FOR SELECT USING (is_approved = true);

CREATE POLICY "Users can insert own photos" ON user_photos
    FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own photos" ON user_photos
    FOR UPDATE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own photos" ON user_photos
    FOR DELETE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Comments: Public comments viewable, users can manage their own
CREATE POLICY "Non-deleted comments are viewable by everyone" ON comments
    FOR SELECT USING (is_deleted = false);

CREATE POLICY "Users can insert own comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own comments" ON comments
    FOR UPDATE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own comments" ON comments
    FOR DELETE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Check-ins: Public check-ins viewable, users manage their own
CREATE POLICY "Public check-ins are viewable by everyone" ON check_ins
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can insert own check-ins" ON check_ins
    FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own check-ins" ON check_ins
    FOR UPDATE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own check-ins" ON check_ins
    FOR DELETE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Likes: Users can view all likes, manage their own
CREATE POLICY "Likes are viewable by everyone" ON likes
    FOR SELECT USING (true);

CREATE POLICY "Users can insert own likes" ON likes
    FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own likes" ON likes
    FOR DELETE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Push tokens: Users can only see/manage their own
CREATE POLICY "Users can view own push tokens" ON push_notification_tokens
    FOR SELECT USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can insert own push tokens" ON push_notification_tokens
    FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own push tokens" ON push_notification_tokens
    FOR UPDATE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own push tokens" ON push_notification_tokens
    FOR DELETE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Alert subscriptions: Users manage their own
CREATE POLICY "Users can view own alert subscriptions" ON alert_subscriptions
    FOR SELECT USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can insert own alert subscriptions" ON alert_subscriptions
    FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own alert subscriptions" ON alert_subscriptions
    FOR UPDATE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own alert subscriptions" ON alert_subscriptions
    FOR DELETE USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

-- Mountain data: Publicly readable (no RLS needed, but enable for consistency)
ALTER TABLE mountain_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE scraper_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mountain status is viewable by everyone" ON mountain_status
    FOR SELECT USING (true);

CREATE POLICY "Scraper runs are viewable by everyone" ON scraper_runs
    FOR SELECT USING (true);

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Shredders Supabase schema created successfully!';
    RAISE NOTICE 'Tables: mountain_status, scraper_runs, users, user_photos, comments, check_ins, likes, push_notification_tokens, alert_subscriptions';
    RAISE NOTICE 'Triggers: Auto-update like/comment counts';
    RAISE NOTICE 'Views: latest_mountain_status, mountain_recent_activity';
    RAISE NOTICE 'Functions: get_mountain_history(), cleanup_old_mountain_status()';
    RAISE NOTICE 'RLS: Enabled on all social tables with secure policies';
END $$;
