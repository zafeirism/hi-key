-- =====================================================
-- Fix redeem_referral: the original fast-path only checked
-- the redeemer's ledger row, which means a second attempt
-- by the same redeemer with a DIFFERENT code returned
-- idempotent success instead of already_redeemed.
--
-- New shape: gate on user_profiles.referred_by (locked via
-- SELECT FOR UPDATE). Idempotent only when the stored
-- referrer matches the one being passed in.
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
  INSERT INTO user_profiles (user_id) VALUES (p_redeemer_id)
  ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO user_profiles (user_id) VALUES (p_referrer_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT referred_by, sub_credits_mills, extra_credits_mills
    INTO v_existing_referred_by, v_sub, v_extra
    FROM user_profiles
    WHERE user_id = p_redeemer_id
    FOR UPDATE;

  IF v_existing_referred_by IS NOT NULL THEN
    IF v_existing_referred_by = p_referrer_id THEN
      RETURN jsonb_build_object(
        'success', true,
        'idempotent', true,
        'sub_credits_mills', v_sub,
        'extra_credits_mills', v_extra
      );
    END IF;

    RETURN jsonb_build_object(
      'success', false,
      'reason', 'already_redeemed',
      'sub_credits_mills', v_sub,
      'extra_credits_mills', v_extra
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
  -- Concurrent caller won the race. Re-read and treat as idempotent success
  -- iff the stored referrer matches (the UPDATE that set referred_by happens
  -- in the same transaction as the ledger inserts, so this is coherent).
  SELECT referred_by, sub_credits_mills, extra_credits_mills
    INTO v_existing_referred_by, v_sub, v_extra
    FROM user_profiles WHERE user_id = p_redeemer_id;
  IF v_existing_referred_by = p_referrer_id THEN
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;
  RETURN jsonb_build_object(
    'success', false,
    'reason', 'already_redeemed',
    'sub_credits_mills', COALESCE(v_sub, 0),
    'extra_credits_mills', COALESCE(v_extra, 0)
  );
END;
$$;
