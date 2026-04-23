import { supabaseAdmin } from '@/lib/supabase/server';
import type { CreditReason } from '@/lib/supabase/helpers';

export type Balance = {
  sub_credits_mills: number;
  extra_credits_mills: number;
};

type RpcResult = Balance & {
  success: boolean;
  idempotent?: boolean;
  reason?: 'insufficient_credits';
};

export class InsufficientCreditsError extends Error {
  constructor(public balance: Balance) {
    super('insufficient_credits');
    this.name = 'InsufficientCreditsError';
  }
}

export async function getBalance(userId: string): Promise<Balance> {
  const { data, error } = await supabaseAdmin
    .from('user_balances')
    .select('sub_credits_mills, extra_credits_mills')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;
  return {
    sub_credits_mills: data?.sub_credits_mills ?? 0,
    extra_credits_mills: data?.extra_credits_mills ?? 0,
  };
}

export async function debit(
  userId: string,
  amountMills: number,
  opts: { reason: CreditReason; sourceId: string; generationId?: string }
): Promise<Balance> {
  const { data, error } = await supabaseAdmin.rpc('debit_credits', {
    p_user_id: userId,
    p_amount_mills: amountMills,
    p_reason: opts.reason,
    p_source_id: opts.sourceId,
    p_generation_id: opts.generationId ?? undefined,
  });

  if (error) throw error;
  const result = data as unknown as RpcResult;
  if (!result.success) {
    throw new InsufficientCreditsError({
      sub_credits_mills: result.sub_credits_mills,
      extra_credits_mills: result.extra_credits_mills,
    });
  }
  return {
    sub_credits_mills: result.sub_credits_mills,
    extra_credits_mills: result.extra_credits_mills,
  };
}

export async function grant(
  userId: string,
  opts: {
    deltaSubMills: number;
    deltaExtraMills: number;
    reason: CreditReason;
    sourceId: string;
    generationId?: string;
  }
): Promise<Balance> {
  const { data, error } = await supabaseAdmin.rpc('grant_credits', {
    p_user_id: userId,
    p_delta_sub_mills: opts.deltaSubMills,
    p_delta_extra_mills: opts.deltaExtraMills,
    p_reason: opts.reason,
    p_source_id: opts.sourceId,
    p_generation_id: opts.generationId ?? undefined,
  });

  if (error) throw error;
  const result = data as unknown as RpcResult;
  return {
    sub_credits_mills: result.sub_credits_mills,
    extra_credits_mills: result.extra_credits_mills,
  };
}

export async function resetSub(
  userId: string,
  targetMills: number,
  opts: { reason: CreditReason; sourceId: string }
): Promise<Balance> {
  const { data, error } = await supabaseAdmin.rpc('reset_sub_credits', {
    p_user_id: userId,
    p_target_mills: targetMills,
    p_reason: opts.reason,
    p_source_id: opts.sourceId,
  });

  if (error) throw error;
  const result = data as unknown as RpcResult;
  return {
    sub_credits_mills: result.sub_credits_mills,
    extra_credits_mills: result.extra_credits_mills,
  };
}

export function toDisplayCredits(mills: number): number {
  return Math.floor(mills / 10);
}
