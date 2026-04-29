-- Replaces the enumerated `reason` column comment with a pointer to the TS
-- source of truth. Previously the comment listed every valid value, which
-- meant adding a new CreditReason in code required a migration just to keep
-- the comment in sync — pure overhead since the column is plain text with no
-- CHECK constraint. The pointer comment never goes stale.

COMMENT ON COLUMN credit_transactions.reason IS
  'Free-form ledger reason. Canonical values: see lib/supabase/helpers.ts::CreditReason.';
