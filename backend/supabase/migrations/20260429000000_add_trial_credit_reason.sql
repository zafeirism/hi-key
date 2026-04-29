-- Documents `trial_start` as a valid value for credit_transactions.reason.
-- The column is plain text (no CHECK constraint), so this is a comment-only
-- update; the value works without the migration. Kept here for hygiene and
-- to keep the column comment in sync with `lib/supabase/helpers.ts::CreditReason`.

COMMENT ON COLUMN credit_transactions.reason IS
  'initial_purchase | trial_start | renewal | pack | generation_debit | generation_refund | refund | expiration_reset | referral | waitlist_claim';
