-- Migration: Social tables (user_photos, comments, check_ins, likes, push notifications, alerts)
-- Adapted from scripts/setup-social-schema.sql for Supabase
-- Skips users table (already exists)

-- ============================================================================
-- TABLE: user_photos
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mountain_id VARCHAR(50) NOT NULL,
    webcam_id VARCHAR(100),
    storage_path TEXT NOT NULL,
    url TEXT,
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

    CONSTRAINT user_photos_file_size CHECK (file_size_bytes IS NULL OR (file_size_bytes > 0 AND file_size_bytes <= 10485760))
);

CREATE INDEX IF NOT EXISTS idx_user_photos_mountain_id ON user_photos(mountain_id, uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_photos_user_id ON user_photos(user_id, uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_photos_approved ON user_photos(is_approved, uploaded_at DESC) WHERE is_approved = true;
CREATE INDEX IF NOT EXISTS idx_user_photos_webcam_id ON user_photos(webcam_id) WHERE webcam_id IS NOT NULL;

-- ============================================================================
-- TABLE: comments (social comments on mountains/webcams/photos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE INDEX IF NOT EXISTS idx_comments_mountain_id ON comments(mountain_id, created_at DESC) WHERE mountain_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_comments_webcam_id ON comments(webcam_id, created_at DESC) WHERE webcam_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_comments_photo_id ON comments(photo_id, created_at DESC) WHERE photo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON comments(parent_comment_id, created_at ASC) WHERE parent_comment_id IS NOT NULL;

-- ============================================================================
-- TABLE: check_ins
-- ============================================================================
CREATE TABLE IF NOT EXISTS check_ins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE INDEX IF NOT EXISTS idx_check_ins_mountain_id ON check_ins(mountain_id, check_in_time DESC);
CREATE INDEX IF NOT EXISTS idx_check_ins_user_id ON check_ins(user_id, check_in_time DESC);
CREATE INDEX IF NOT EXISTS idx_check_ins_public ON check_ins(is_public, check_in_time DESC) WHERE is_public = true;

-- ============================================================================
-- TABLE: likes
-- ============================================================================
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE INDEX IF NOT EXISTS idx_likes_photo_id ON likes(photo_id, created_at DESC) WHERE photo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_comment_id ON likes(comment_id, created_at DESC) WHERE comment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_check_in_id ON likes(check_in_id, created_at DESC) WHERE check_in_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_webcam_id ON likes(webcam_id, created_at DESC) WHERE webcam_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id, created_at DESC);

-- ============================================================================
-- TABLE: push_notification_tokens
-- ============================================================================
CREATE TABLE IF NOT EXISTS push_notification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_notification_tokens(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_push_tokens_active ON push_notification_tokens(is_active, platform) WHERE is_active = true;

-- ============================================================================
-- TABLE: alert_subscriptions
-- ============================================================================
CREATE TABLE IF NOT EXISTS alert_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_photo_comments
AFTER INSERT OR DELETE OR UPDATE ON comments
FOR EACH ROW
EXECUTE FUNCTION update_photo_comments_count();

-- Update alert_subscriptions updated_at
CREATE OR REPLACE FUNCTION update_social_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_alert_subs_updated_at
BEFORE UPDATE ON alert_subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_social_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- user_photos: public read for approved, owner write
ALTER TABLE user_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Approved photos are publicly readable"
ON user_photos FOR SELECT
USING (is_approved = true);

CREATE POLICY "Users can insert own photos"
ON user_photos FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own photos"
ON user_photos FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own photos"
ON user_photos FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Service role full access to user_photos"
ON user_photos FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- comments: public read for non-deleted, authenticated insert, owner update/delete
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Non-deleted comments are publicly readable"
ON comments FOR SELECT
USING (is_deleted = false);

CREATE POLICY "Authenticated users can insert comments"
ON comments FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own comments"
ON comments FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own comments"
ON comments FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Service role full access to comments"
ON comments FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- check_ins: public read for public ones, authenticated insert, owner update/delete
ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public check-ins are readable"
ON check_ins FOR SELECT
USING (is_public = true);

CREATE POLICY "Authenticated users can insert check-ins"
ON check_ins FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own check-ins"
ON check_ins FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own check-ins"
ON check_ins FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Service role full access to check_ins"
ON check_ins FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- likes: public read, authenticated insert/delete own
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes are publicly readable"
ON likes FOR SELECT
USING (true);

CREATE POLICY "Authenticated users can insert likes"
ON likes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own likes"
ON likes FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Service role full access to likes"
ON likes FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- push_notification_tokens: owner only
ALTER TABLE push_notification_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own push tokens"
ON push_notification_tokens FOR SELECT
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can insert own push tokens"
ON push_notification_tokens FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own push tokens"
ON push_notification_tokens FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own push tokens"
ON push_notification_tokens FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Service role full access to push_notification_tokens"
ON push_notification_tokens FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- alert_subscriptions: owner only
ALTER TABLE alert_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own alert subscriptions"
ON alert_subscriptions FOR SELECT
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can insert own alert subscriptions"
ON alert_subscriptions FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update own alert subscriptions"
ON alert_subscriptions FOR UPDATE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete own alert subscriptions"
ON alert_subscriptions FOR DELETE
TO authenticated
USING (auth.uid() = (SELECT auth_user_id FROM users WHERE id = user_id));

CREATE POLICY "Service role full access to alert_subscriptions"
ON alert_subscriptions FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================================================
-- VIEW: mountain_recent_activity
-- ============================================================================
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
