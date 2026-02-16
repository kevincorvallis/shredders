-- Migration: User Session Management
-- Description: Add table for tracking user sessions across devices with comprehensive metadata
-- Created: 2026-01-11

-- ============================================
-- User Sessions Table
-- ============================================
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  refresh_token_jti TEXT UNIQUE NOT NULL,
  token_family UUID NOT NULL,

  -- Device Information
  device_id TEXT,
  device_type TEXT CHECK (device_type IN ('desktop', 'mobile', 'tablet', 'unknown')),
  device_name TEXT,
  browser TEXT,
  browser_version TEXT,
  os TEXT,
  os_version TEXT,

  -- Location Information
  ip_address TEXT,
  country TEXT,
  region TEXT,
  city TEXT,

  -- Session Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  revoke_reason TEXT,

  -- User Agent
  user_agent TEXT
);

-- ============================================
-- Indexes for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_refresh_token_jti ON user_sessions(refresh_token_jti);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token_family ON user_sessions(token_family);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_last_activity_at ON user_sessions(last_activity_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_sessions_device_id ON user_sessions(device_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_ip_address ON user_sessions(ip_address);

-- Composite index for active sessions query
CREATE INDEX IF NOT EXISTS idx_user_sessions_active
  ON user_sessions(user_id, expires_at, revoked_at)
  WHERE revoked_at IS NULL;

-- ============================================
-- Comments
-- ============================================
COMMENT ON TABLE user_sessions IS 'Tracks user sessions across devices with device fingerprinting and location';
COMMENT ON COLUMN user_sessions.refresh_token_jti IS 'JTI of the refresh token associated with this session';
COMMENT ON COLUMN user_sessions.token_family IS 'Token family UUID for this session chain';
COMMENT ON COLUMN user_sessions.device_id IS 'Unique identifier for the device (fingerprint)';
COMMENT ON COLUMN user_sessions.device_type IS 'Type of device: desktop, mobile, tablet';
COMMENT ON COLUMN user_sessions.last_activity_at IS 'Last time this session was used';
COMMENT ON COLUMN user_sessions.revoked_at IS 'When the session was manually revoked by user or system';
COMMENT ON COLUMN user_sessions.revoke_reason IS 'Why the session was revoked (e.g., user logout, security)';

-- ============================================
-- Row Level Security
-- ============================================
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

-- Users can read their own sessions
CREATE POLICY "Users can view their own sessions"
  ON user_sessions FOR SELECT
  USING (auth.uid()::text = user_id::text);

-- Users can revoke their own sessions
CREATE POLICY "Users can revoke their own sessions"
  ON user_sessions FOR UPDATE
  USING (auth.uid()::text = user_id::text)
  WITH CHECK (auth.uid()::text = user_id::text);

-- Service role can manage all sessions
CREATE POLICY "Service role can manage all sessions"
  ON user_sessions FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- ============================================
-- Permissions
-- ============================================
GRANT SELECT, UPDATE ON user_sessions TO authenticated;
GRANT ALL ON user_sessions TO service_role;

-- ============================================
-- Functions
-- ============================================

-- Function to clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM user_sessions
  WHERE expires_at < NOW()
    AND revoked_at IS NULL;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cleanup_expired_sessions IS 'Deletes expired sessions that have not been explicitly revoked';

-- Function to revoke all user sessions
CREATE OR REPLACE FUNCTION revoke_all_user_sessions(p_user_id UUID, p_reason TEXT DEFAULT 'User requested')
RETURNS INTEGER AS $$
DECLARE
  revoked_count INTEGER;
BEGIN
  UPDATE user_sessions
  SET
    revoked_at = NOW(),
    revoke_reason = p_reason
  WHERE user_id = p_user_id
    AND revoked_at IS NULL
    AND expires_at > NOW();

  GET DIAGNOSTICS revoked_count = ROW_COUNT;
  RETURN revoked_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION revoke_all_user_sessions IS 'Revokes all active sessions for a user (except current if specified)';

-- Function to get session statistics
CREATE OR REPLACE FUNCTION get_session_stats(p_user_id UUID)
RETURNS TABLE (
  total_sessions BIGINT,
  active_sessions BIGINT,
  revoked_sessions BIGINT,
  expired_sessions BIGINT,
  unique_devices BIGINT,
  unique_ips BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) as total_sessions,
    COUNT(*) FILTER (WHERE revoked_at IS NULL AND expires_at > NOW()) as active_sessions,
    COUNT(*) FILTER (WHERE revoked_at IS NOT NULL) as revoked_sessions,
    COUNT(*) FILTER (WHERE expires_at <= NOW() AND revoked_at IS NULL) as expired_sessions,
    COUNT(DISTINCT device_id) as unique_devices,
    COUNT(DISTINCT ip_address) as unique_ips
  FROM user_sessions
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_session_stats IS 'Returns session statistics for a user';

-- Function to detect suspicious sessions
CREATE OR REPLACE FUNCTION detect_suspicious_sessions(p_user_id UUID, p_hours INTEGER DEFAULT 24)
RETURNS TABLE (
  session_id UUID,
  ip_address TEXT,
  country TEXT,
  created_at TIMESTAMPTZ,
  suspicious_reason TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH user_ips AS (
    SELECT DISTINCT ip_address, country
    FROM user_sessions
    WHERE user_id = p_user_id
      AND created_at > NOW() - INTERVAL '30 days'
  ),
  recent_sessions AS (
    SELECT
      s.id,
      s.ip_address,
      s.country,
      s.created_at
    FROM user_sessions s
    WHERE s.user_id = p_user_id
      AND s.created_at > NOW() - (p_hours || ' hours')::INTERVAL
      AND s.revoked_at IS NULL
  )
  SELECT
    rs.id,
    rs.ip_address,
    rs.country,
    rs.created_at,
    CASE
      WHEN rs.ip_address NOT IN (SELECT ip_address FROM user_ips WHERE created_at < rs.created_at - INTERVAL '1 day')
        THEN 'New IP address'
      WHEN rs.country NOT IN (SELECT country FROM user_ips WHERE created_at < rs.created_at - INTERVAL '7 days')
        THEN 'New country'
      ELSE 'Unknown'
    END as suspicious_reason
  FROM recent_sessions rs;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION detect_suspicious_sessions IS 'Detects potentially suspicious login sessions based on IP and location patterns';
