import { describe, it, expect, afterAll } from 'vitest';
import { supabaseAdmin } from '@/lib/supabase/server';
import { getBalance } from '@/lib/credits/balance';
import {
  AlreadyRedeemedError,
  CodeNotFoundError,
  InvalidCodeError,
  InvalidNameError,
  REFERRAL_BONUS_MILLS,
  SelfReferralError,
  getOrCreateReferralCode,
  getReferralProfile,
  redeemReferralCode,
} from '../service';

const shouldRunTests =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.SUPABASE_SECRET_KEY;

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
    expect(first.name).toBe('JANE');
    expect(first.code.startsWith('JANE-')).toBe(true);

    const second = await getOrCreateReferralCode(user, 'SomeoneElse');
    expect(second.code).toBe(first.code);
    expect(second.name).toBe('JANE');
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

  it('redeems happy path: both sides get bonus, referred_by set, ledger rows written', async () => {
    const referrer = track(`${prefix}-hr-referrer`);
    const redeemer = track(`${prefix}-hr-redeemer`);
    await cleanup(referrer);
    await cleanup(redeemer);

    const { code } = await getOrCreateReferralCode(referrer, 'Alice');
    const balance = await redeemReferralCode(redeemer, code);

    expect(balance.extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);

    const referrerBalance = await getBalance(referrer);
    expect(referrerBalance.extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);

    const profile = await getReferralProfile(redeemer);
    expect(profile.referred_by).toBe(referrer);

    const { data: txs } = await supabaseAdmin
      .from('credit_transactions')
      .select('user_id, delta_extra_mills, source_id, reason')
      .eq('reason', 'referral')
      .in('user_id', [referrer, redeemer]);
    expect(txs?.length).toBe(2);
    expect(txs?.every((t) => t.delta_extra_mills === REFERRAL_BONUS_MILLS)).toBe(true);
  });

  it('second redemption by the same redeemer is rejected and does not double-grant', async () => {
    const refA = track(`${prefix}-dup-a`);
    const refB = track(`${prefix}-dup-b`);
    const redeemer = track(`${prefix}-dup-redeemer`);
    for (const u of [refA, refB, redeemer]) await cleanup(u);

    const { code: codeA } = await getOrCreateReferralCode(refA, 'AAA');
    const { code: codeB } = await getOrCreateReferralCode(refB, 'BBB');

    await redeemReferralCode(redeemer, codeA);
    await expect(redeemReferralCode(redeemer, codeB)).rejects.toBeInstanceOf(AlreadyRedeemedError);

    const redeemerBalance = await getBalance(redeemer);
    expect(redeemerBalance.extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);

    const balanceB = await getBalance(refB);
    expect(balanceB.extra_credits_mills).toBe(0);
  });

  it('replaying the same redemption is idempotent', async () => {
    const referrer = track(`${prefix}-idem-referrer`);
    const redeemer = track(`${prefix}-idem-redeemer`);
    await cleanup(referrer);
    await cleanup(redeemer);

    const { code } = await getOrCreateReferralCode(referrer, 'Rex');

    await redeemReferralCode(redeemer, code);
    // Second call for the same (redeemer, referrer) pair: the fast-path in
    // redeem_referral detects the existing ledger row and returns idempotent success,
    // so the service returns the same balance rather than throwing.
    const replayed = await redeemReferralCode(redeemer, code);
    expect(replayed.extra_credits_mills).toBe(REFERRAL_BONUS_MILLS);

    const { data: txs } = await supabaseAdmin
      .from('credit_transactions')
      .select('id')
      .eq('reason', 'referral')
      .in('user_id', [referrer, redeemer]);
    expect(txs?.length).toBe(2);
  });
});
