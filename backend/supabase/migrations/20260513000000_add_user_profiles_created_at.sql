ALTER TABLE user_profiles
  ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
