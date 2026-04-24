import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { randomUUID } from 'crypto';
import { supabaseAdmin } from '@/lib/supabase/server';
import {
  debit,
  grant,
  resetSub,
  getBalance,
  refundGeneration,
  DebitNotFoundError,
} from '../balance';

const shouldRunTests =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.SUPABASE_SECRET_KEY;

const testRunId = Date.now();

async function cleanup(userId: string, requestId?: string) {
  await supabaseAdmin.from('credit_transactions').delete().eq('user_id', userId);
  await supabaseAdmin.from('user_profiles').delete().eq('user_id', userId);
  if (requestId) {
    await supabaseAdmin.from('generations').delete().eq('request_id', requestId);
  }
}

async function seedGenerations(
  userId: string,
  requestId: string,
  count: number
): Promise<string[]> {
  const ids = Array.from({ length: count }, () => randomUUID());
  const rows = ids.map((id) => ({
    id,
    user_id: userId,
    request_id: requestId,
    status: 'generating',
  }));
  const { error } = await supabaseAdmin.from('generations').insert(rows);
  if (error) throw error;
  return ids;
}

describe.skipIf(!shouldRunTests)('refund_generation integration', () => {
  const users: { id: string; requestId: string }[] = [];

  beforeAll(async () => {
    // nothing global; each test sets up its own user
  });

  afterAll(async () => {
    for (const { id, requestId } of users) {
      await cleanup(id, requestId);
    }
  });

  async function setupUser(
    suffix: string,
    seed: { sub: number; extra: number }
  ): Promise<{ userId: string; requestId: string; generationIds: string[] }> {
    const userId = `test-refund-${testRunId}-${suffix}`;
    const requestId = `req-${testRunId}-${suffix}`;
    users.push({ id: userId, requestId });
    await cleanup(userId, requestId);
    if (seed.sub > 0 || seed.extra > 0) {
      await grant(userId, {
        deltaSubMills: seed.sub,
        deltaExtraMills: seed.extra,
        reason: 'initial_purchase',
        sourceId: `src-${userId}-seed`,
      });
    }
    const generationIds = await seedGenerations(userId, requestId, 4);
    return { userId, requestId, generationIds };
  }

  it('refunds to extras when debit was only from extras', async () => {
    const { userId, requestId, generationIds } = await setupUser('extras-only', {
      sub: 0,
      extra: 100,
    });
    await debit(userId, 84, {
      reason: 'generation_debit',
      sourceId: requestId,
      generationId: generationIds[0],
    });

    const balance = await refundGeneration(userId, {
      requestId,
      generationId: generationIds[0]!,
      amountMills: 11,
    });

    expect(balance).toEqual({ sub_credits_mills: 0, extra_credits_mills: 27 });
  });

  it('refunds to sub when debit was only from sub', async () => {
    const { userId, requestId, generationIds } = await setupUser('sub-only', {
      sub: 100,
      extra: 0,
    });
    await debit(userId, 84, {
      reason: 'generation_debit',
      sourceId: requestId,
      generationId: generationIds[0],
    });

    const balance = await refundGeneration(userId, {
      requestId,
      generationId: generationIds[0]!,
      amountMills: 11,
    });

    expect(balance).toEqual({ sub_credits_mills: 27, extra_credits_mills: 0 });
  });

  it('splits refund across two refunds that exceed extras-owed', async () => {
    // sub=74, extra=10. Debit 84 = 74 sub + 10 extra. Sub=0, Extra=0.
    const { userId, requestId, generationIds } = await setupUser('mixed-split', {
      sub: 74,
      extra: 10,
    });
    await debit(userId, 84, {
      reason: 'generation_debit',
      sourceId: requestId,
      generationId: generationIds[0],
    });

    // First refund of 30: extras-owed=10, so 10→extras, 20→sub.
    const after1 = await refundGeneration(userId, {
      requestId,
      generationId: generationIds[0]!,
      amountMills: 30,
    });
    expect(after1).toEqual({ sub_credits_mills: 20, extra_credits_mills: 10 });

    // Second refund of 30: extras-owed now 0 (already fully repaid), all→sub.
    const after2 = await refundGeneration(userId, {
      requestId,
      generationId: generationIds[1]!,
      amountMills: 30,
    });
    expect(after2).toEqual({ sub_credits_mills: 50, extra_credits_mills: 10 });
  });

  it('routes full refund to extras when sub was expired between debit and refund', async () => {
    const { userId, requestId, generationIds } = await setupUser('sub-expired', {
      sub: 100,
      extra: 0,
    });
    await debit(userId, 84, {
      reason: 'generation_debit',
      sourceId: requestId,
      generationId: generationIds[0],
    });
    await resetSub(userId, 0, {
      reason: 'expiration_reset',
      sourceId: `src-${userId}-expire`,
    });

    const balance = await refundGeneration(userId, {
      requestId,
      generationId: generationIds[0]!,
      amountMills: 11,
    });

    // sub should NOT get the 11; extras gets it all.
    expect(balance).toEqual({ sub_credits_mills: 0, extra_credits_mills: 11 });
  });

  it('routes full refund to extras when sub was renewed between debit and refund', async () => {
    const { userId, requestId, generationIds } = await setupUser('sub-renewed', {
      sub: 100,
      extra: 0,
    });
    await debit(userId, 84, {
      reason: 'generation_debit',
      sourceId: requestId,
      generationId: generationIds[0],
    });
    await resetSub(userId, 1000, {
      reason: 'renewal',
      sourceId: `src-${userId}-renew`,
    });

    const balance = await refundGeneration(userId, {
      requestId,
      generationId: generationIds[0]!,
      amountMills: 11,
    });

    // sub stays at tier-max; extras get the refund.
    expect(balance).toEqual({ sub_credits_mills: 1000, extra_credits_mills: 11 });
  });

  it('is idempotent on replay of the same generation_id', async () => {
    const { userId, requestId, generationIds } = await setupUser('idempotent', {
      sub: 0,
      extra: 100,
    });
    await debit(userId, 84, {
      reason: 'generation_debit',
      sourceId: requestId,
      generationId: generationIds[0],
    });

    const first = await refundGeneration(userId, {
      requestId,
      generationId: generationIds[0]!,
      amountMills: 11,
    });
    const second = await refundGeneration(userId, {
      requestId,
      generationId: generationIds[0]!,
      amountMills: 11,
    });
    expect(second).toEqual(first);

    const { data: txs } = await supabaseAdmin
      .from('credit_transactions')
      .select('id')
      .eq('user_id', userId)
      .eq('reason', 'generation_refund')
      .eq('source_id', generationIds[0]!);
    expect(txs?.length).toBe(1);
  });

  it('throws DebitNotFoundError when no debit row exists for the request', async () => {
    const { userId, generationIds } = await setupUser('no-debit', { sub: 100, extra: 0 });
    const balanceBefore = await getBalance(userId);

    await expect(
      refundGeneration(userId, {
        requestId: `req-${testRunId}-no-debit-missing`,
        generationId: generationIds[0]!,
        amountMills: 11,
      })
    ).rejects.toBeInstanceOf(DebitNotFoundError);

    const balanceAfter = await getBalance(userId);
    expect(balanceAfter).toEqual(balanceBefore);
  });
});
