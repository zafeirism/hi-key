import { describe, it, expect, afterAll } from 'vitest';
import { supabaseAdmin } from '@/lib/supabase/server';
import { getProfile } from '@/lib/profile/profile';
import {
  AlreadyRedeemedError,
  CodeNotFoundError,
  InvalidCodeError,
  InvalidNameError,
  REFERRAL_BONUS_MILLS,
  SelfReferralError,
  getOrCreateReferralCode,
  grantReferralBonus,
  redeemReferralCode,
} from '../service';

const shouldRunTests = !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.SUPABASE_SECRET_KEY;

const prefix = `test-referral-${Date.now()}`;

async function cleanup(userId: string) {
  await supabaseAdmin.from('credit_transactions').delete().eq('user_id', userId);
  await supabaseAdmin.from('user_profiles').delete().eq('user_id', userId);
}

describe.skipIf(!shouldRunTests)('referrals service integration', () => {
  const allUsers: string[] = [];
  const track = (u: string) => {
    allUsers.push(u);
    return u;
  };

  afterAll(async () => {
    for (const u of allUsers) await cleanup(u);
  });

  it('creates a code on first call and returns the same code on subsequent calls', async () => {
    const user = track(`${prefix}-create`);
    await cleanup(user);

    const first = await getOrCreateReferralCode(user, 'Jane');
    expect(first.name).toBe('Jane');
    expect(first.code.startsWith('JANE-')).toBe(true);

    const second = await getOrCreateReferralCode(user, 'SomeoneElse');
    expect(second.code).toBe(first.code);
    expect(second.name).toBe('Jane');
  });

  it('stores the full name when longer than the code prefix max', async () => {
    const user = track(`${prefix}-long-name`);
    await cleanup(user);

    const result = await getOrCreateReferralCode(user, 'Johnathan');
    expect(result.name).toBe('Johnathan');
    expect(result.code.startsWith('JOHNAT-')).toBe(true);

    const { data } = await supabaseAdmin
      .from('user_profiles')
      .select('name')
      .eq('user_id', user)
      .maybeSingle();
    expect(data?.name).toBe('Johnathan');
  });

  it('preserves casing, diacritics, and spaces in the stored name', async () => {
    const user = track(`${prefix}-rich-name`);
    await cleanup(user);

    const result = await getOrCreateReferralCode(user, '  Zoë Müller  ');
    expect(result.name).toBe('Zoë Müller');
    expect(result.code.startsWith('ZOEMUL-')).toBe(true);
  });

  it('rejects names that sanitize to empty', async () => {
    const user = track(`${prefix}-invalid-name`);
    await cleanup(user);

    await expect(getOrCreateReferralCode(user, '🎉')).rejects.toBeInstanceOf(InvalidNameError);
  });

  it('rejects invalid code formats', async () => {
    const user = track(`${prefix}-invalid-code`);
    await cleanup(user);

    await expect(redeemReferralCode(user, 'not-a-code')).rejects.toBeInstanceOf(InvalidCodeError);
    await expect(redeemReferralCode(user, 'JANE-ILOU12')).rejects.toBeInstanceOf(InvalidCodeError);
  });

  it('rejects codes that no user owns', async () => {
    const user = track(`${prefix}-notfound`);
    await cleanup(user);

    await expect(redeemReferralCode(user, 'JANE-ZZZZZZ')).rejects.toBeInstanceOf(CodeNotFoundError);
  });

  it('rejects self-referral', async () => {
    const user = track(`${prefix}-self`);
    await cleanup(user);

    const { code } = await getOrCreateReferralCode(user, 'Self');
    await expect(redeemReferralCode(user, code)).rejects.toBeInstanceOf(SelfReferralError);
  });

  async function referralTxs(users: string[]) {
    const { data } = await supabaseAdmin
      .from('credit_transactions')
      .select('user_id, delta_extra_mills')
      .eq('reason', 'referral')
      .in('user_id', users);
    return data ?? [];
  }

  it('redeem records referred_by but defers the bonus until the redeemer pays', async () => {
    const referrer = track(`${prefix}-hr-referrer`);
    const redeemer = track(`${prefix}-hr-redeemer`);
    await cleanup(referrer);
    await cleanup(redeemer);

    const { code } = await getOrCreateReferralCode(referrer, 'Alice');
    const result = await redeemReferralCode(redeemer, code);

    expect(result.bonusPending).toBe(true);
    expect(result.balance.extra_credits_mills).toBe(0);
    expect((await getProfile(redeemer)).referred_by).toBe(referrer);
    expect((await getProfile(referrer)).extra_credits_mills).toBe(0);
    expect(await referralTxs([referrer, redeemer])).toHaveLength(0);
  });

  it('grantReferralBonus pays both sides exactly once', async () => {
    const referrer = track(`${prefix}-pay-referrer`);
    const redeemer = track(`${prefix}-pay-redeemer`);
    await cleanup(referrer);
    await cleanup(redeemer);

    const { code } = await getOrCreateReferralCode(referrer, 'Paula');
    await redeemReferralCode(redeemer, code);

    expect(await grantReferralBonus(redeemer)).toBe(true);
    expect(await grantReferralBonus(redeemer)).toBe(false);

    expect((await getProfile(redeemer)).extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);
    expect((await getProfile(referrer)).extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);
    const txs = await referralTxs([referrer, redeemer]);
    expect(txs).toHaveLength(2);
    expect(txs.every((t) => t.delta_extra_mills === REFERRAL_BONUS_MILLS)).toBe(true);

    // Replaying the redemption after payout reports the bonus as no longer pending.
    const replayed = await redeemReferralCode(redeemer, code);
    expect(replayed.bonusPending).toBe(false);
    expect(replayed.balance.extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);
  });

  it('grantReferralBonus is a no-op for users who were not referred', async () => {
    const user = track(`${prefix}-unreferred`);
    await cleanup(user);
    await supabaseAdmin.from('user_profiles').insert({ user_id: user });

    expect(await grantReferralBonus(user)).toBe(false);
    expect((await getProfile(user)).extra_credits_mills).toBe(0);
  });

  it('pays out immediately when the redeemer has already paid', async () => {
    const referrer = track(`${prefix}-paid-referrer`);
    const redeemer = track(`${prefix}-paid-redeemer`);
    await cleanup(referrer);
    await cleanup(redeemer);

    await supabaseAdmin.from('user_profiles').insert({ user_id: redeemer });
    await supabaseAdmin.from('credit_transactions').insert({
      user_id: redeemer,
      delta_sub_mills: 0,
      delta_extra_mills: 0,
      reason: 'initial_purchase',
      source_id: `${prefix}-paid-evt`,
    });

    const { code } = await getOrCreateReferralCode(referrer, 'Quinn');
    const result = await redeemReferralCode(redeemer, code);

    expect(result.bonusPending).toBe(false);
    expect(result.balance.extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);
    expect((await getProfile(referrer)).extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);
  });

  it('second redemption by the same redeemer is rejected', async () => {
    const refA = track(`${prefix}-dup-a`);
    const refB = track(`${prefix}-dup-b`);
    const redeemer = track(`${prefix}-dup-redeemer`);
    for (const u of [refA, refB, redeemer]) await cleanup(u);

    const { code: codeA } = await getOrCreateReferralCode(refA, 'AAA');
    const { code: codeB } = await getOrCreateReferralCode(refB, 'BBB');

    await redeemReferralCode(redeemer, codeA);
    await expect(redeemReferralCode(redeemer, codeB)).rejects.toBeInstanceOf(AlreadyRedeemedError);
    expect((await getProfile(redeemer)).referred_by).toBe(refA);
  });

  it('replaying the same redemption is idempotent', async () => {
    const referrer = track(`${prefix}-idem-referrer`);
    const redeemer = track(`${prefix}-idem-redeemer`);
    await cleanup(referrer);
    await cleanup(redeemer);

    const { code } = await getOrCreateReferralCode(referrer, 'Rex');

    await redeemReferralCode(redeemer, code);
    const replayed = await redeemReferralCode(redeemer, code);
    expect(replayed.bonusPending).toBe(true);
    expect(await referralTxs([referrer, redeemer])).toHaveLength(0);
  });
});
