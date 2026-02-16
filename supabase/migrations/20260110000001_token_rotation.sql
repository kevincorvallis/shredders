-- Migration: Token Rotation Tracking
-- Description: Add table for tracking refresh token rotations and detecting reuse attacks
-- Created: 2026-01-11

-- ============================================
-- Token Rotations Table
-- ============================================
CREATE TABLE IF NOT EXISTS token_rotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jti TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL,
  token_family UUID NOT NULL,
  parent_jti TEXT,
  child_jti TEXT,
  used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_token_rotations_jti ON token_rotations(jti);
CREATE INDEX IF NOT EXISTS idx_token_rotations_user_id ON token_rotations(user_id);
CREATE INDEX IF NOT EXISTS idx_token_rotations_token_family ON token_rotations(token_family);
CREATE INDEX IF NOT EXISTS idx_token_rotations_expires_at ON token_rotations(expires_at);
CREATE INDEX IF NOT EXISTS idx_token_rotations_child_jti ON token_rotations(child_jti);

-- Comments
COMMENT ON TABLE token_rotations IS 'Tracks refresh token rotations for detecting reuse attacks';
COMMENT ON COLUMN token_rotations.jti IS 'JWT ID of the refresh token';
COMMENT ON COLUMN token_rotations.token_family IS 'UUID identifying tokens in the same rotation chain';
COMMENT ON COLUMN token_rotations.parent_jti IS 'JTI of the token that was rotated to create this one';
COMMENT ON COLUMN token_rotations.child_jti IS 'JTI of the token created when this token was used';
COMMENT ON COLUMN token_rotations.used_at IS 'When this token was used to generate a new token pair';

-- ============================================
-- Row Level Security
-- ============================================
ALTER TABLE token_rotations ENABLE ROW LEVEL SECURITY;

-- Service role can manage all rotations
CREATE POLICY "Service role can manage token rotations"
  ON token_rotations FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Permissions
GRANT SELECT, INSERT, UPDATE ON token_rotations TO authenticated;
GRANT ALL ON token_rotations TO service_role;
