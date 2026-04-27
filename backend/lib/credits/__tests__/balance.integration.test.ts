import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { supabaseAdmin } from '@/lib/supabase/server';
import { debit, grant, resetSub, InsufficientCreditsError } from '../balance';
import { getProfile } from '@/lib/profile/profile';

const shouldRunTests =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.SUPABASE_SECRET_KEY;

const testUserId = `test-credits-${Date.now()}`;

async function cleanup(userId: string) {
  await supabaseAdmin.from('credit_transactions').delete().eq('user_id', userId);
  await supabaseAdmin.from('user_profiles').delete().eq('user_id', userId);
}

describe.skipIf(!shouldRunTests)('credits balance integration', () => {
  beforeAll(async () => {
    await cleanup(testUserId);
  });

  afterAll(async () => {
    await cleanup(testUserId);
  });

  it('returns 0/0 when user has no row', async () => {
    const profile = await getProfile(testUserId);
    expect(profile.sub_credits_mills).toBe(0);
    expect(profile.extra_credits_mills).toBe(0);
  });

  it('grants sub credits and persists the ledger', async () => {
    const balance = await grant(testUserId, {
      deltaSubMills: 1000,
      deltaExtraMills: 0,
      reason: 'initial_purchase',
      sourceId: `src-${testUserId}-grant-sub`,
    });
    expect(balance.sub_credits_mills).toBe(1000);
    expect(balance.extra_credits_mills).toBe(0);

    const { data: txs } = await supabaseAdmin
      .from('credit_transactions')
      .select('*')
      .eq('user_id', testUserId)
      .eq('reason', 'initial_purchase');
    expect(txs?.length).toBe(1);
    expect(txs?.[0]?.delta_sub_mills).toBe(1000);
  });

  it('is idempotent on duplicate (reason, source_id)', async () => {
    const sourceId = `src-${testUserId}-idempotent`;
    const first = await grant(testUserId, {
      deltaSubMills: 100,
      deltaExtraMills: 0,
      reason: 'initial_purchase',
      sourceId,
    });
    const second = await grant(testUserId, {
      deltaSubMills: 100,
      deltaExtraMills: 0,
      reason: 'initial_purchase',
      sourceId,
    });
    expect(second.sub_credits_mills).toBe(first.sub_credits_mills);

    const { data: txs } = await supabaseAdmin
      .from('credit_transactions')
      .select('id')
      .eq('user_id', testUserId)
      .eq('reason', 'initial_purchase')
      .eq('source_id', sourceId);
    expect(txs?.length).toBe(1);
  });

  it('debits from sub first, then extra', async () => {
    const user = `${testUserId}-debit`;
    await cleanup(user);
    await grant(user, {
      deltaSubMills: 30,
      deltaExtraMills: 50,
      reason: 'initial_purchase',
      sourceId: `src-${user}-seed`,
    });

    const afterFirst = await debit(user, 20, {
      reason: 'generation_debit',
      sourceId: `src-${user}-debit-1`,
    });
    expect(afterFirst).toEqual({ sub_credits_mills: 10, extra_credits_mills: 50 });

    const afterOverflow = await debit(user, 40, {
      reason: 'generation_debit',
      sourceId: `src-${user}-debit-2`,
    });
    expect(afterOverflow).toEqual({ sub_credits_mills: 0, extra_credits_mills: 20 });

    await cleanup(user);
  });

  it('throws InsufficientCreditsError when balance cannot cover debit', async () => {
    const user = `${testUserId}-insufficient`;
    await cleanup(user);
    await grant(user, {
      deltaSubMills: 5,
      deltaExtraMills: 0,
      reason: 'initial_purchase',
      sourceId: `src-${user}-seed`,
    });

    await expect(
      debit(user, 100, {
        reason: 'generation_debit',
        sourceId: `src-${user}-too-much`,
      })
    ).rejects.toBeInstanceOf(InsufficientCreditsError);

    const profile = await getProfile(user);
    expect(profile.sub_credits_mills).toBe(5);
    expect(profile.extra_credits_mills).toBe(0);

    await cleanup(user);
  });

  it('resetSub replaces sub_credits_mills and preserves extra', async () => {
    const user = `${testUserId}-reset`;
    await cleanup(user);
    await grant(user, {
      deltaSubMills: 500,
      deltaExtraMills: 200,
      reason: 'initial_purchase',
      sourceId: `src-${user}-seed`,
    });

    const reset = await resetSub(user, 2000, {
      reason: 'renewal',
      sourceId: `src-${user}-renew`,
    });
    expect(reset).toEqual({ sub_credits_mills: 2000, extra_credits_mills: 200 });

    const expired = await resetSub(user, 0, {
      reason: 'expiration_reset',
      sourceId: `src-${user}-expire`,
    });
    expect(expired).toEqual({ sub_credits_mills: 0, extra_credits_mills: 200 });

    await cleanup(user);
  });
});
