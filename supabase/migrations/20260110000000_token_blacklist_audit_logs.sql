-- Migration: Token Blacklist and Audit Logging
-- Description: Add tables for JWT token revocation and security audit logging
-- Created: 2026-01-10

-- ============================================
-- Token Blacklist Table
-- ============================================
-- Stores revoked JWT tokens to prevent reuse after logout or compromise

CREATE TABLE IF NOT EXISTS token_blacklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jti TEXT UNIQUE NOT NULL, -- JWT ID from token payload
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token_type TEXT NOT NULL CHECK (token_type IN ('access', 'refresh')),
  expires_at TIMESTAMPTZ NOT NULL, -- When token naturally expires
  revoked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- When it was blacklisted
  reason TEXT, -- Optional reason for revocation
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_token_blacklist_jti ON token_blacklist(jti);
CREATE INDEX IF NOT EXISTS idx_token_blacklist_user_id ON token_blacklist(user_id);
CREATE INDEX IF NOT EXISTS idx_token_blacklist_expires_at ON token_blacklist(expires_at);

-- Comment on table
COMMENT ON TABLE token_blacklist IS 'Revoked JWT tokens to prevent reuse after logout';
COMMENT ON COLUMN token_blacklist.jti IS 'Unique JWT ID from token payload';
COMMENT ON COLUMN token_blacklist.expires_at IS 'When token naturally expires (for cleanup)';
COMMENT ON COLUMN token_blacklist.reason IS 'Why token was revoked (logout, compromise, etc)';

-- ============================================
-- Audit Logs Table
-- ============================================
-- Tracks all authentication events for security monitoring and compliance

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Null if user deleted
  event_type TEXT NOT NULL, -- login, signup, refresh, logout, update_profile, etc.
  event_data JSONB, -- Additional event-specific data
  ip_address TEXT, -- Client IP address
  user_agent TEXT, -- Client user agent
  success BOOLEAN NOT NULL, -- Whether the event succeeded
  error_message TEXT, -- Error message if failed
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for querying and analytics
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_success ON audit_logs(success);
CREATE INDEX IF NOT EXISTS idx_audit_logs_ip_address ON audit_logs(ip_address);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created ON audit_logs(user_id, created_at DESC);

-- Comment on table
COMMENT ON TABLE audit_logs IS 'Security audit log for all authentication events';
COMMENT ON COLUMN audit_logs.event_type IS 'Type of auth event (login, signup, refresh, etc)';
COMMENT ON COLUMN audit_logs.event_data IS 'Additional context specific to the event';
COMMENT ON COLUMN audit_logs.success IS 'Whether the authentication attempt succeeded';

-- ============================================
-- Row Level Security (RLS)
-- ============================================

-- Enable RLS on both tables
ALTER TABLE token_blacklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Token blacklist policies
-- Only service role can manage blacklist (not user-facing)
CREATE POLICY "Service role can manage token blacklist"
  ON token_blacklist
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Audit logs policies
-- Users can read their own audit logs
CREATE POLICY "Users can read own audit logs"
  ON audit_logs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Service role can manage all audit logs
CREATE POLICY "Service role can manage audit logs"
  ON audit_logs
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Admins can read all audit logs (assuming users table has is_admin column)
-- Uncomment if you have admin role:
-- CREATE POLICY "Admins can read all audit logs"
--   ON audit_logs
--   FOR SELECT
--   TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1 FROM users
--       WHERE id = auth.uid() AND is_admin = true
--     )
--   );

-- ============================================
-- Cleanup Function
-- ============================================
-- Function to clean up expired tokens from blacklist
-- Run this periodically via cron job or background task

CREATE OR REPLACE FUNCTION cleanup_expired_blacklist_tokens()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM token_blacklist
  WHERE expires_at < NOW();

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION cleanup_expired_blacklist_tokens IS 'Removes expired tokens from blacklist';

-- ============================================
-- Grant Permissions
-- ============================================

-- Grant necessary permissions
GRANT SELECT, INSERT, DELETE ON token_blacklist TO authenticated;
GRANT SELECT, INSERT ON audit_logs TO authenticated;

-- Service role gets full access
GRANT ALL ON token_blacklist TO service_role;
GRANT ALL ON audit_logs TO service_role;
