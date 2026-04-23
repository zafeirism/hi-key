-- =====================================================
-- hi-key credits ledger
-- Two-bucket balance (sub_credits_mills + extra_credits_mills)
-- plus append-only transaction log keyed to RC event IDs
-- for idempotency on webhook replays.
-- 1 credit = 10 mills = 1 cent of underlying AI cost.
-- =====================================================

CREATE TABLE user_balances (
  user_id text PRIMARY KEY,
  sub_credits_mills integer NOT NULL DEFAULT 0,
  extra_credits_mills integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE user_balances ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE user_balances IS 'Per-user credit balance. 1 credit = 10 mills. One row per user.';
COMMENT ON COLUMN user_balances.sub_credits_mills IS 'Weekly subscription allowance. Reset on RENEWAL, zeroed on EXPIRATION.';
COMMENT ON COLUMN user_balances.extra_credits_mills IS 'Pack purchases and referrals. Never expires.';

CREATE TABLE credit_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  delta_sub_mills integer NOT NULL DEFAULT 0,
  delta_extra_mills integer NOT NULL DEFAULT 0,
  reason text NOT NULL,
  source_id text NOT NULL,
  generation_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

CREATE UNIQUE INDEX idx_credit_transactions_reason_source
  ON credit_transactions(reason, source_id);

CREATE INDEX idx_credit_transactions_user_id
  ON credit_transactions(user_id);

CREATE INDEX idx_credit_transactions_created_at
  ON credit_transactions(created_at DESC);

COMMENT ON TABLE credit_transactions IS 'Append-only ledger. Every balance change writes one row.';
COMMENT ON COLUMN credit_transactions.reason IS 'initial_purchase | renewal | pack | generation_debit | generation_refund | refund | expiration_reset | referral';
COMMENT ON COLUMN credit_transactions.source_id IS 'RC event.id for webhook-driven rows, request_id for debits, generation_id for refunds.';

-- =====================================================
-- generations: per-image reservation, distinct from cost_usd_mills
-- which is the actual cost (worker may rewrite for image #4).
-- =====================================================

ALTER TABLE generations ADD COLUMN reserved_usd_mills integer;

COMMENT ON COLUMN generations.reserved_usd_mills IS 'Mills reserved for this image at /api/generate time. Replicate webhook refunds reserved - cost on success, or full reserved on failure.';

-- =====================================================
-- RPCs. Called via supabaseAdmin.rpc(...).
-- Each takes a row-level lock via SELECT FOR UPDATE.
-- Idempotency: unique (reason, source_id) on credit_transactions.
-- All RPCs return JSONB { sub_credits_mills, extra_credits_mills, ... }.
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
  -- Fast path: already processed (webhook retry or double-submit).
  IF EXISTS (
    SELECT 1 FROM credit_transactions
    WHERE reason = p_reason AND source_id = p_source_id
  ) THEN
    SELECT sub_credits_mills, extra_credits_mills
      INTO v_sub, v_extra
      FROM user_balances WHERE user_id = p_user_id;
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO user_balances (user_id) VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_balances
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

  -- Insert ledger first: unique constraint is the idempotency gate
  -- against any concurrent caller that passed the fast path above.
  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id, generation_id
  ) VALUES (
    p_user_id, -v_debit_sub, -v_debit_extra, p_reason, p_source_id, p_generation_id
  );

  UPDATE user_balances
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
    FROM user_balances WHERE user_id = p_user_id;
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
      FROM user_balances WHERE user_id = p_user_id;
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO user_balances (user_id) VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_balances
    WHERE user_id = p_user_id
    FOR UPDATE;

  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id, generation_id
  ) VALUES (
    p_user_id, p_delta_sub_mills, p_delta_extra_mills, p_reason, p_source_id, p_generation_id
  );

  UPDATE user_balances
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
    FROM user_balances WHERE user_id = p_user_id;
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
      FROM user_balances WHERE user_id = p_user_id;
    RETURN jsonb_build_object(
      'success', true,
      'idempotent', true,
      'sub_credits_mills', COALESCE(v_sub, 0),
      'extra_credits_mills', COALESCE(v_extra, 0)
    );
  END IF;

  INSERT INTO user_balances (user_id) VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT sub_credits_mills, extra_credits_mills
    INTO v_sub, v_extra
    FROM user_balances
    WHERE user_id = p_user_id
    FOR UPDATE;

  v_delta := p_target_mills - v_sub;

  INSERT INTO credit_transactions (
    user_id, delta_sub_mills, delta_extra_mills, reason, source_id
  ) VALUES (
    p_user_id, v_delta, 0, p_reason, p_source_id
  );

  UPDATE user_balances
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
    FROM user_balances WHERE user_id = p_user_id;
  RETURN jsonb_build_object(
    'success', true,
    'idempotent', true,
    'sub_credits_mills', COALESCE(v_sub, 0),
    'extra_credits_mills', COALESCE(v_extra, 0)
  );
END;
$$;
