-- =====================================================
-- hi-key referrals + user profile rename
-- user_balances was too narrow a name now that the same
-- row carries profile data (name, referral_code, referred_by).
-- Renamed to user_profiles; the three credit RPCs are
-- redeclared against the new table. Adds redeem_referral
-- RPC that atomically marks the redeemer, writes two
-- ledger rows (idempotent on (reason, source_id)), and
-- grants both sides their bonus.
-- =====================================================

ALTER TABLE user_balances RENAME TO user_profiles;

ALTER TABLE user_profiles
  ADD COLUMN name text,
  ADD COLUMN referral_code text,
  ADD COLUMN referred_by text;

CREATE UNIQUE INDEX idx_user_profiles_referral_code
  ON user_profiles(referral_code)
  WHERE referral_code IS NOT NULL;

COMMENT ON TABLE user_profiles IS 'Per-user row: credit balances + referral fields. 1 credit = 10 mills.';
COMMENT ON COLUMN user_profiles.name IS 'Sanitized display name used as the prefix of referral_code. Uppercase ASCII, up to 6 chars.';
COMMENT ON COLUMN user_profiles.referral_code IS 'Immutable code of the form NAME-XXXXXX (Crockford Base32 suffix). Null until the user creates one.';
COMMENT ON COLUMN user_profiles.referred_by IS 'user_id of the referrer if this user redeemed a code during onboarding. Null otherwise.';

-- =====================================================
-- Redeclare credit RPCs against user_profiles.
-- Postgres resolves table names at each execution, so
-- renaming user_balances without replacing these bodies
-- would break the next call.
-- =====================================================

CREATE OR REPLACE FUNCTION debit_credits(
  p_user_id text,
  p_amount_mills integer,
  p_reason text,
  p_source_id text,
  p_generation_id text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_sub integer;
  v_extra integer;
  v_debit_sub integer;
  v_debit_extra integer;
BEGIN
  IF EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE reason = p_reason AND source_id = p_source_id
  ) THEN
    SELECT sub_credits_mills, extra_credits_mills
      INTO v_sub, v_extra
      FROM user_profiles WHERE user_id = p_user_id;
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO user_profiles (user_id) VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_profiles
    WHERE user_id = p_user_id
    FOR UPDATE;

  IF v_sub + v_extra < p_amount_mills THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'insufficient_credits',
      'sub_credits_mills', v_sub,
      'extra_credits_mills', v_extra
    );
  END IF;

  v_debit_sub := LEAST(p_amount_mills, v_sub);
  v_debit_extra := p_amount_mills - v_debit_sub;

  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id, generation_id
  ) VALUES (
    p_user_id, -v_debit_sub, -v_debit_extra, p_reason, p_source_id, p_generation_id
  );

  UPDATE user_profiles
    SET sub_credits_mills = sub_credits_mills - v_debit_sub,
        extra_credits_mills = extra_credits_mills - v_debit_extra,
        updated_at = now()
    WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'idempotent', false,
    'sub_credits_mills', v_sub - v_debit_sub,
    'extra_credits_mills', v_extra - v_debit_extra
  );

EXCEPTION WHEN unique_violation THEN
  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_profiles WHERE user_id = p_user_id;
  RETURN jsonb_build_object(
    'success', true,
    'idempotent', true,
    'sub_credits_mills', COALESCE(v_sub, 0),
    'extra_credits_mills', COALESCE(v_extra, 0)
  );
END;
$$;

CREATE OR REPLACE FUNCTION grant_credits(
  p_user_id text,
  p_delta_sub_mills integer,
  p_delta_extra_mills integer,
  p_reason text,
  p_source_id text,
  p_generation_id text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_sub integer;
  v_extra integer;
BEGIN
  IF EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE reason = p_reason AND source_id = p_source_id
  ) THEN
    SELECT sub_credits_mills, extra_credits_mills
      INTO v_sub, v_extra
      FROM user_profiles WHERE user_id = p_user_id;
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO user_profiles (user_id) VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_profiles
    WHERE user_id = p_user_id
    FOR UPDATE;

  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id, generation_id
  ) VALUES (
    p_user_id, p_delta_sub_mills, p_delta_extra_mills, p_reason, p_source_id, p_generation_id
  );

  UPDATE user_profiles
    SET sub_credits_mills = sub_credits_mills + p_delta_sub_mills,
        extra_credits_mills = extra_credits_mills + p_delta_extra_mills,
        updated_at = now()
    WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'idempotent', false,
    'sub_credits_mills', v_sub + p_delta_sub_mills,
    'extra_credits_mills', v_extra + p_delta_extra_mills
  );

EXCEPTION WHEN unique_violation THEN
  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_profiles WHERE user_id = p_user_id;
  RETURN jsonb_build_object(
    'success', true,
    'idempotent', true,
    'sub_credits_mills', COALESCE(v_sub, 0),
    'extra_credits_mills', COALESCE(v_extra, 0)
  );
END;
$$;

CREATE OR REPLACE FUNCTION reset_sub_credits(
  p_user_id text,
  p_target_mills integer,
  p_reason text,
  p_source_id text
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_sub integer;
  v_extra integer;
  v_delta integer;
BEGIN
  IF EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE reason = p_reason AND source_id = p_source_id
  ) THEN
    SELECT sub_credits_mills, extra_credits_mills
      INTO v_sub, v_extra
      FROM user_profiles WHERE user_id = p_user_id;
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO user_profiles (user_id) VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_profiles
    WHERE user_id = p_user_id
    FOR UPDATE;

  v_delta := p_target_mills - v_sub;

  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id
  ) VALUES (
    p_user_id, v_delta, 0, p_reason, p_source_id
  );

  UPDATE user_profiles
    SET sub_credits_mills = p_target_mills,
        updated_at = now()
    WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'idempotent', false,
    'sub_credits_mills', p_target_mills,
    'extra_credits_mills', v_extra
  );

EXCEPTION WHEN unique_violation THEN
  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_profiles WHERE user_id = p_user_id;
  RETURN jsonb_build_object(
    'success', true,
    'idempotent', true,
    'sub_credits_mills', COALESCE(v_sub, 0),
    'extra_credits_mills', COALESCE(v_extra, 0)
  );
END;
$$;

-- =====================================================
-- redeem_referral: atomic redeem + two-sided grant.
-- source_ids are keyed on the REDEEMER (referral_redeemer_<id>
-- and referral_referrer_<id>) so any retry by the same
-- redeemer is a unique-constraint no-op, and two different
-- redeemers using the same referrer do not collide.
-- =====================================================

CREATE OR REPLACE FUNCTION redeem_referral(
  p_redeemer_id text,
  p_referrer_id text,
  p_bonus_mills integer
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_redeemer_source_id text := 'referral_redeemer_' || p_redeemer_id;
  v_referrer_source_id text := 'referral_referrer_' || p_redeemer_id;
  v_existing_referred_by text;
  v_sub integer;
  v_extra integer;
BEGIN
  IF EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE reason = 'referral' AND source_id = v_redeemer_source_id
  ) THEN
    SELECT sub_credits_mills, extra_credits_mills
      INTO v_sub, v_extra
      FROM user_profiles WHERE user_id = p_redeemer_id;
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO user_profiles (user_id) VALUES (p_redeemer_id)
  ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO user_profiles (user_id) VALUES (p_referrer_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT referred_by
    INTO v_existing_referred_by
    FROM user_profiles
    WHERE user_id = p_redeemer_id
    FOR UPDATE;

  IF v_existing_referred_by IS NOT NULL THEN
    SELECT sub_credits_mills, extra_credits_mills
      INTO v_sub, v_extra
      FROM user_profiles WHERE user_id = p_redeemer_id;
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'already_redeemed',
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id
  ) VALUES
    (p_redeemer_id, 0, p_bonus_mills, 'referral', v_redeemer_source_id),
    (p_referrer_id, 0, p_bonus_mills, 'referral', v_referrer_source_id);

  UPDATE user_profiles
    SET referred_by = p_referrer_id,
        extra_credits_mills = extra_credits_mills + p_bonus_mills,
        updated_at = now()
    WHERE user_id = p_redeemer_id;

  UPDATE user_profiles
    SET extra_credits_mills = extra_credits_mills + p_bonus_mills,
        updated_at = now()
    WHERE user_id = p_referrer_id;

  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_profiles WHERE user_id = p_redeemer_id;

  RETURN jsonb_build_object(
    'success', true,
    'idempotent', false,
    'sub_credits_mills', v_sub,
    'extra_credits_mills', v_extra
  );

EXCEPTION WHEN unique_violation THEN
  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_profiles WHERE user_id = p_redeemer_id;
  RETURN jsonb_build_object(
    'success', true,
    'idempotent', true,
    'sub_credits_mills', COALESCE(v_sub, 0),
    'extra_credits_mills', COALESCE(v_extra, 0)
  );
END;
$$;
