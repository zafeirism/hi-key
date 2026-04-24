-- =====================================================
-- refund_generation RPC
-- Computes the bucket split for a per-image refund by
-- reading the original debit ledger row + any prior refunds
-- for the same request, and applies "extras first" mirror.
--
-- If the sub bucket was touched between debit and refund
-- (expiration, renewal, or upgrade grant), the entire
-- refund is routed to extras instead of sub — refunding
-- to sub would either resurrect zeroed credits or push
-- above tier max.
--
-- Idempotency: unique (reason='generation_refund', source_id=generation_id).
-- =====================================================

CREATE OR REPLACE FUNCTION refund_generation(
  p_user_id text,
  p_request_id text,
  p_generation_id text,
  p_amount_mills integer
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_sub integer;
  v_extra integer;
  v_debit_created_at timestamptz;
  v_net_extra integer;
  v_remaining_extra_debt integer;
  v_sub_touched boolean;
  v_delta_extra integer;
  v_delta_sub integer;
  v_remaining integer;
BEGIN
  -- Fast path: already processed (webhook retry).
  IF EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE reason = 'generation_refund' AND source_id = p_generation_id
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

  -- Locate the debit row for this request.
  SELECT created_at
    INTO v_debit_created_at
    FROM credit_transactions
    WHERE user_id = p_user_id
      AND reason = 'generation_debit'
      AND source_id = p_request_id
    LIMIT 1;

  IF v_debit_created_at IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason', 'debit_not_found',
      'sub_credits_mills', v_sub,
      'extra_credits_mills', v_extra
    );
  END IF;

  -- Remaining extras-owed: sum delta_extra_mills across the debit row
  -- (negative) and any prior generation_refund rows for this request's
  -- generations (positive). -sum clamped at 0 is how much extras
  -- still owes back to the user.
  SELECT COALESCE(SUM(delta_extra_mills), 0)
    INTO v_net_extra
    FROM credit_transactions
    WHERE user_id = p_user_id
      AND (
        (reason = 'generation_debit' AND source_id = p_request_id)
        OR (
          reason = 'generation_refund'
          AND generation_id IN (
            SELECT id FROM generations WHERE request_id = p_request_id
          )
        )
      );
  v_remaining_extra_debt := GREATEST(-v_net_extra, 0);

  -- Has the sub bucket been reset/regranted since the debit?
  SELECT EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE user_id = p_user_id
      AND reason IN ('renewal', 'expiration_reset', 'initial_purchase')
      AND created_at > v_debit_created_at
  ) INTO v_sub_touched;

  -- Split: extras first, then sub (unless sub was touched — in which
  -- case the remainder also goes to extras).
  v_delta_extra := LEAST(p_amount_mills, v_remaining_extra_debt);
  v_remaining := p_amount_mills - v_delta_extra;
  IF v_sub_touched THEN
    v_delta_extra := v_delta_extra + v_remaining;
    v_delta_sub := 0;
  ELSE
    v_delta_sub := v_remaining;
  END IF;

  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id, generation_id
  ) VALUES (
    p_user_id, v_delta_sub, v_delta_extra, 'generation_refund', p_generation_id, p_generation_id
  );

  UPDATE user_profiles
    SET sub_credits_mills = sub_credits_mills + v_delta_sub,
        extra_credits_mills = extra_credits_mills + v_delta_extra,
        updated_at = now()
    WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'idempotent', false,
    'sub_credits_mills', v_sub + v_delta_sub,
    'extra_credits_mills', v_extra + v_delta_extra
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
