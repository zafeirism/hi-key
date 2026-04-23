import { supabaseAdmin } from '@/lib/supabase/server';
import type { Balance } from '@/lib/credits/balance';
import {
  REFERRAL_CODE_REGEX,
  buildReferralCode,
  normalizeCodeInput,
  sanitizeName,
} from './code';

export const REFERRAL_BONUS_MILLS = 500;
const MAX_CODE_GENERATION_ATTEMPTS = 5;
const UNIQUE_VIOLATION = '23505';

export class InvalidNameError extends Error {
  constructor() {
    super('invalid_name');
    this.name = 'InvalidNameError';
  }
}

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

export class SelfReferralError extends Error {
  constructor() {
    super('self_referral');
    this.name = 'SelfReferralError';
  }
}

export class AlreadyRedeemedError extends Error {
  constructor(public balance: Balance) {
    super('already_redeemed');
    this.name = 'AlreadyRedeemedError';
  }
}

export type ReferralProfile = {
  name: string;
  code: string;
};

export async function getOrCreateReferralCode(
  userId: string,
  rawName: string
): Promise<ReferralProfile> {
  const { error: upsertError } = await supabaseAdmin
    .from('user_profiles')
    .upsert({ user_id: userId }, { onConflict: 'user_id', ignoreDuplicates: true });
  if (upsertError) throw upsertError;

  const existing = await readProfile(userId);
  if (existing.referral_code && existing.name) {
    return { name: existing.name, code: existing.referral_code };
  }

  const sanitized = sanitizeName(rawName);
  if (!sanitized) throw new InvalidNameError();

  for (let attempt = 0; attempt < MAX_CODE_GENERATION_ATTEMPTS; attempt++) {
    const code = buildReferralCode(sanitized);
    const { data, error } = await supabaseAdmin
      .from('user_profiles')
      .update({
        name: sanitized,
        referral_code: code,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .is('referral_code', null)
      .select('referral_code, name');

    if (error) {
      if (error.code === UNIQUE_VIOLATION) continue;
      throw error;
    }

    if (data && data.length > 0) {
      return { name: sanitized, code };
    }

    // 0 rows updated: another caller set the code between our read and write.
    const winner = await readProfile(userId);
    if (winner.referral_code && winner.name) {
      return { name: winner.name, code: winner.referral_code };
    }
  }

  throw new Error('Could not generate a unique referral code after multiple attempts');
}

export async function redeemReferralCode(
  redeemerId: string,
  rawCode: string
): Promise<Balance> {
  const code = normalizeCodeInput(rawCode);
  if (!REFERRAL_CODE_REGEX.test(code)) {
    throw new InvalidCodeError();
  }

  const { data: referrer, error: lookupError } = await supabaseAdmin
    .from('user_profiles')
    .select('user_id')
    .eq('referral_code', code)
    .maybeSingle();

  if (lookupError) throw lookupError;
  if (!referrer) throw new CodeNotFoundError();
  if (referrer.user_id === redeemerId) throw new SelfReferralError();

  const { data, error: rpcError } = await supabaseAdmin.rpc('redeem_referral', {
    p_redeemer_id: redeemerId,
    p_referrer_id: referrer.user_id,
    p_bonus_mills: REFERRAL_BONUS_MILLS,
  });

  if (rpcError) throw rpcError;

  const result = data as unknown as {
    success: boolean;
    reason?: string;
    sub_credits_mills: number;
    extra_credits_mills: number;
  };

  const balance: Balance = {
    sub_credits_mills: result.sub_credits_mills,
    extra_credits_mills: result.extra_credits_mills,
  };

  if (!result.success) {
    if (result.reason === 'already_redeemed') {
      throw new AlreadyRedeemedError(balance);
    }
    throw new Error(`redeem_referral failed: ${result.reason ?? 'unknown'}`);
  }

  return balance;
}

async function readProfile(userId: string) {
  const { data, error } = await supabaseAdmin
    .from('user_profiles')
    .select('name, referral_code, referred_by')
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw error;
  return {
    name: data?.name ?? null,
    referral_code: data?.referral_code ?? null,
    referred_by: data?.referred_by ?? null,
  };
}

export async function getReferralProfile(userId: string) {
  return readProfile(userId);
}
