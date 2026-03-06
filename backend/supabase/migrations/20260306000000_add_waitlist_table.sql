CREATE TABLE IF NOT EXISTS waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  referral_source TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_waitlist_email ON waitlist (email);

ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
-- No policies = no direct client access. Only service role (backend) can read/write.
