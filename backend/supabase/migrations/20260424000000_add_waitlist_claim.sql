-- =====================================================
-- Waitlist claim codes + double-credits feature.
-- Visitors who joined the waitlist before launch get a
-- unique code in the launch email. Applying it in-app
-- flips user_profiles.double_credits=true, which doubles
-- every subsequent sub grant, renewal and pack purchase.
-- For immediate impact, the claim also tops up the current
-- sub balance by one full tier (the active sub product is
-- tracked separately on user_profiles).
-- =====================================================

ALTER TABLE waitlist
  ADD COLUMN claim_code text,
  ADD COLUMN claimed_at timestamptz,
  ADD COLUMN claimed_by_user_id text;

CREATE UNIQUE INDEX idx_waitlist_claim_code
  ON waitlist(claim_code)
  WHERE claim_code IS NOT NULL;

COMMENT ON COLUMN waitlist.claim_code IS 'Unique code shared in the launch email. Format HI-XXXXXXXX (Crockford Base32). NULL until generated manually.';
COMMENT ON COLUMN waitlist.claimed_at IS 'Timestamp when the code was applied in the app. NULL = unused.';
COMMENT ON COLUMN waitlist.claimed_by_user_id IS 'user_id that applied the code. Kept for support/debug.';

ALTER TABLE user_profiles
  ADD COLUMN double_credits boolean NOT NULL DEFAULT false,
  ADD COLUMN active_sub_product_id text;

COMMENT ON COLUMN user_profiles.double_credits IS 'Set to true after a waitlist claim code is applied. Doubles every sub grant, renewal and pack purchase.';
COMMENT ON COLUMN user_profiles.active_sub_product_id IS 'RC product_id of the currently-active subscription, or NULL. Maintained by the RC webhook on INITIAL_PURCHASE/RENEWAL/EXPIRATION.';

-- =====================================================
-- claim_waitlist_code: atomic application of a waitlist
-- code. Returns a jsonb payload shaped like the other
-- credit RPCs: { success, reason?, sub_credits_mills,
-- extra_credits_mills, idempotent? }.
--
-- Rules:
-- - Code must exist (reason='code_not_found').
-- - Re-applying the same code by the same user is a no-op
--   (idempotent=true).
-- - A user who already has double_credits cannot claim a
--   different code (reason='already_doubled').
-- - A code used by another user cannot be reused
--   (reason='already_claimed').
-- - On success, caller-provided p_bonus_sub_mills is
--   added to sub_credits_mills and ledgered.
-- =====================================================

CREATE OR REPLACE FUNCTION claim_waitlist_code(
  p_user_id text,
  p_code text,
  p_bonus_sub_mills integer
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_waitlist_id uuid;
  v_claimed_by text;
  v_already_doubled boolean;
  v_sub integer;
  v_extra integer;
BEGIN
  SELECT id, claimed_by_user_id
    INTO v_waitlist_id, v_claimed_by
    FROM waitlist
    WHERE claim_code = p_code
    FOR UPDATE;

  IF v_waitlist_id IS NULL THEN
    SELECT sub_credits_mills, extra_credits_mills
      INTO v_sub, v_extra
      FROM user_profiles WHERE user_id = p_user_id;
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'code_not_found',
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO user_profiles (user_id) VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT double_credits, sub_credits_mills, extra_credits_mills
    INTO v_already_doubled, v_sub, v_extra
    FROM user_profiles
    WHERE user_id = p_user_id
    FOR UPDATE;

  IF v_claimed_by = p_user_id THEN
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', v_sub,
      'extra_credits_mills', v_extra
    );
  END IF;

  IF v_already_doubled THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'already_doubled',
      'sub_credits_mills', v_sub,
      'extra_credits_mills', v_extra
    );
  END IF;

  IF v_claimed_by IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'already_claimed',
      'sub_credits_mills', v_sub,
      'extra_credits_mills', v_extra
    );
  END IF;

  UPDATE waitlist
    SET claimed_at = now(),
        claimed_by_user_id = p_user_id
    WHERE id = v_waitlist_id;

  UPDATE user_profiles
    SET double_credits = true,
        sub_credits_mills = sub_credits_mills + p_bonus_sub_mills,
        updated_at = now()
    WHERE user_id = p_user_id;

  IF p_bonus_sub_mills > 0 THEN
    INSERT INTO credit_transactions (
      user_id, delta_sub_mills, delta_extra_mills, reason, source_id
    ) VALUES (
      p_user_id, p_bonus_sub_mills, 0, 'waitlist_claim', 'waitlist_claim_' || p_user_id
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'idempotent', false,
    'sub_credits_mills', v_sub + p_bonus_sub_mills,
    'extra_credits_mills', v_extra
  );
END;
$$;
