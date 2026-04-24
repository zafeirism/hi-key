import { supabaseAdmin } from '@/lib/supabase/server';
import { lookupProduct } from '@/lib/credits/catalog';
import type { Balance } from '@/lib/credits/balance';
import { CLAIM_CODE_REGEX, normalizeClaimCodeInput } from './code';

export class InvalidCodeError extends Error {
  constructor() {
    super('invalid_code');
    this.name = 'InvalidCodeError';
  }
}

export class CodeNotFoundError extends Error {
  constructor() {
    super('code_not_found');
    this.name = 'CodeNotFoundError';
  }
}

export class AlreadyClaimedError extends Error {
  constructor() {
    super('already_claimed');
    this.name = 'AlreadyClaimedError';
  }
}

export class AlreadyDoubledError extends Error {
  constructor(public balance: Balance) {
    super('already_doubled');
    this.name = 'AlreadyDoubledError';
  }
}

export async function claimWaitlistCode(userId: string, rawCode: string): Promise<Balance> {
  const code = normalizeClaimCodeInput(rawCode);
  if (!CLAIM_CODE_REGEX.test(code)) {
    throw new InvalidCodeError();
  }

  const bonusSubMills = await computeCurrentTierBonus(userId);

  const { data, error } = await supabaseAdmin.rpc('claim_waitlist_code', {
    p_user_id: userId,
    p_code: code,
    p_bonus_sub_mills: bonusSubMills,
  });

  if (error) throw error;

  const result = data as unknown as {
    success: boolean;
    reason?: string;
    idempotent?: boolean;
    sub_credits_mills: number;
    extra_credits_mills: number;
  };

  const balance: Balance = {
    sub_credits_mills: result.sub_credits_mills,
    extra_credits_mills: result.extra_credits_mills,
  };

  if (!result.success) {
    if (result.reason === 'code_not_found') throw new CodeNotFoundError();
    if (result.reason === 'already_claimed') throw new AlreadyClaimedError();
    if (result.reason === 'already_doubled') throw new AlreadyDoubledError(balance);
    throw new Error(`claim_waitlist_code failed: ${result.reason ?? 'unknown'}`);
  }

  return balance;
}

async function computeCurrentTierBonus(userId: string): Promise<number> {
  const { data, error } = await supabaseAdmin
    .from('user_profiles')
    .select('active_sub_product_id')
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw error;

  const productId = data?.active_sub_product_id;
  if (!productId) return 0;

  const product = lookupProduct(productId);
  if (!product || product.kind !== 'sub') return 0;
  return product.tierMaxMills;
}
