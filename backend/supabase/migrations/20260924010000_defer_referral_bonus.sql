-- =====================================================
-- Defer the referral bonus until the redeemer pays.
--
-- Anonymous Supabase sign-ins are free and scriptable, so granting
-- both sides 50 credits at redeem time let anyone farm credits with
-- throwaway accounts. Now:
--   * redeem_referral only records user_profiles.referred_by. If the
--     redeemer has already paid (a purchase/trial/renewal/pack ledger
--     row exists), the bonus is granted right away.
--   * grant_referral_bonus pays both sides once, called by the
--     RevenueCat webhook on the redeemer's purchase/trial/renewal.
-- Idempotency still comes from the existing (reason, source_id)
-- unique index: 'referral' + 'referral_redeemer_<redeemer_id>' /
-- 'referral_referrer_<redeemer_id>', so users who redeemed under the
-- old flow (already paid out) are no-ops here.
-- =====================================================

CREATE OR REPLACE FUNCTION grant_referral_bonus(
  p_redeemer_id text,
  p_bonus_mills integer
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_redeemer_source_id text := 'referral_redeemer_' || p_redeemer_id;
  v_referrer_source_id text := 'referral_referrer_' || p_redeemer_id;
  v_referrer_id text;
BEGIN
  -- Lock the redeemer row so concurrent webhook deliveries serialize here.
  SELECT referred_by INTO v_referrer_id
    FROM user_profiles
    WHERE user_id = p_redeemer_id
    FOR UPDATE;

  IF v_referrer_id IS NULL THEN
    RETURN jsonb_build_object('granted', false, 'reason', 'not_referred');
  END IF;

  IF EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE reason = 'referral' AND source_id = v_redeemer_source_id
  ) THEN
    RETURN jsonb_build_object('granted', false, 'reason', 'already_granted');
  END IF;

  INSERT INTO user_profiles (user_id) VALUES (v_referrer_id)
  ON CONFLICT (user_id) DO NOTHING;

  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id
  ) VALUES
    (p_redeemer_id, 0, p_bonus_mills, 'referral', v_redeemer_source_id),
    (v_referrer_id, 0, p_bonus_mills, 'referral', v_referrer_source_id);

  UPDATE user_profiles
    SET extra_credits_mills = extra_credits_mills + p_bonus_mills,
        updated_at = now()
    WHERE user_id IN (p_redeemer_id, v_referrer_id);

  RETURN jsonb_build_object('granted', true);

EXCEPTION WHEN unique_violation THEN
  RETURN jsonb_build_object('granted', false, 'reason', 'already_granted');
END;
$$;

CREATE OR REPLACE FUNCTION redeem_referral(
  p_redeemer_id text,
  p_referrer_id text,
  p_bonus_mills integer
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_existing_referred_by text;
  v_sub integer;
  v_extra integer;
  v_has_paid boolean;
  v_bonus_granted boolean;
BEGIN
  INSERT INTO user_profiles (user_id) VALUES (p_redeemer_id)
  ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO user_profiles (user_id) VALUES (p_referrer_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT referred_by INTO v_existing_referred_by
    FROM user_profiles
    WHERE user_id = p_redeemer_id
    FOR UPDATE;

  IF v_existing_referred_by IS NOT NULL AND v_existing_referred_by <> p_referrer_id THEN
    SELECT sub_credits_mills, extra_credits_mills INTO v_sub, v_extra
      FROM user_profiles WHERE user_id = p_redeemer_id;
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'already_redeemed',
      'sub_credits_mills', v_sub,
      'extra_credits_mills', v_extra
    );
  END IF;

  IF v_existing_referred_by IS NULL THEN
    UPDATE user_profiles
      SET referred_by = p_referrer_id,
          updated_at = now()
      WHERE user_id = p_redeemer_id;

    -- Already a paying user (e.g. subscribed before redeeming): no future
    -- INITIAL_PURCHASE will arrive, so pay out now.
    SELECT EXISTS (
      SELECT 1 FROM credit_transactions
      WHERE user_id = p_redeemer_id
        AND reason IN ('initial_purchase', 'trial_start', 'renewal', 'pack')
    ) INTO v_has_paid;

    IF v_has_paid THEN
      PERFORM grant_referral_bonus(p_redeemer_id, p_bonus_mills);
    END IF;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE reason = 'referral' AND source_id = 'referral_redeemer_' || p_redeemer_id
  ) INTO v_bonus_granted;

  SELECT sub_credits_mills, extra_credits_mills INTO v_sub, v_extra
    FROM user_profiles WHERE user_id = p_redeemer_id;

  RETURN jsonb_build_object(
    'success', true,
    'idempotent', v_existing_referred_by IS NOT NULL,
    'bonus_pending', NOT v_bonus_granted,
    'sub_credits_mills', v_sub,
    'extra_credits_mills', v_extra
  );
END;
$$;

-- Backend-only, like every other RPC (see 20260924000000_revoke_public_rpc_execute.sql).
REVOKE EXECUTE ON FUNCTION grant_referral_bonus(text, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION redeem_referral(text, text, integer) FROM PUBLIC, anon, authenticated;
