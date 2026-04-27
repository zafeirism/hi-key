import { describe, it, expect, afterAll, beforeEach } from 'vitest';
import { supabaseAdmin } from '@/lib/supabase/server';
import { getProfile } from '@/lib/profile/profile';
import { generateClaimCode } from '../code';
import {
  AlreadyClaimedError,
  AlreadyDoubledError,
  CodeNotFoundError,
  InvalidCodeError,
  claimWaitlistCode,
} from '../service';

const shouldRunTests =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.SUPABASE_SECRET_KEY;

const prefix = `test-waitlist-${Date.now()}`;

async function cleanupUser(userId: string) {
  await supabaseAdmin.from('credit_transactions').delete().eq('user_id', userId);
  await supabaseAdmin.from('user_profiles').delete().eq('user_id', userId);
}

async function cleanupWaitlistEmails(emails: string[]) {
  if (emails.length === 0) return;
  await supabaseAdmin.from('waitlist').delete().in('email', emails);
}

async function seedWaitlistRow(email: string, code: string) {
  const { error } = await supabaseAdmin.from('waitlist').insert({ email, claim_code: code });
  if (error) throw error;
}

async function setActiveSub(userId: string, productId: string) {
  const { error } = await supabaseAdmin
    .from('user_profiles')
    .upsert(
      { user_id: userId, active_sub_product_id: productId },
      { onConflict: 'user_id' }
    );
  if (error) throw error;
}

describe.skipIf(!shouldRunTests)('waitlist service integration', () => {
  const users: string[] = [];
  const emails: string[] = [];

  afterAll(async () => {
    for (const u of users) await cleanupUser(u);
    await cleanupWaitlistEmails(emails);
  });

  beforeEach(() => {
    // track between tests
  });

  it('rejects malformed codes before hitting the DB', async () => {
    await expect(claimWaitlistCode(`${prefix}-x`, 'not-a-code')).rejects.toBeInstanceOf(
      InvalidCodeError
    );
  });

  it('throws CodeNotFoundError for an unknown valid-format code', async () => {
    const user = `${prefix}-unknown`;
    users.push(user);
    await cleanupUser(user);

    await expect(claimWaitlistCode(user, 'HI-99999999')).rejects.toBeInstanceOf(
      CodeNotFoundError
    );
  });

  it('claims with no bonus when the user has no active sub', async () => {
    const user = `${prefix}-no-sub`;
    const email = `${user}@example.com`;
    const code = generateClaimCode();
    users.push(user);
    emails.push(email);
    await cleanupUser(user);
    await seedWaitlistRow(email, code);

    const before = await getProfile(user);
    const after = await claimWaitlistCode(user, code);

    expect(after.sub_credits_mills).toBe(before.sub_credits_mills);

    const { data: profile } = await supabaseAdmin
      .from('user_profiles')
      .select('double_credits')
      .eq('user_id', user)
      .maybeSingle();
    expect(profile?.double_credits).toBe(true);
  });

  it('adds one full tier to sub_credits_mills when the user has an active sub', async () => {
    const user = `${prefix}-with-sub`;
    const email = `${user}@example.com`;
    const code = generateClaimCode();
    users.push(user);
    emails.push(email);
    await cleanupUser(user);
    await setActiveSub(user, 'plus.weekly');
    await seedWaitlistRow(email, code);

    const before = await getProfile(user);
    const after = await claimWaitlistCode(user, code);

    // plus.weekly tierMaxMills = 2000
    expect(after.sub_credits_mills).toBe(before.sub_credits_mills + 2000);
  });

  it('is idempotent when the same user re-applies the same code', async () => {
    const user = `${prefix}-idem`;
    const email = `${user}@example.com`;
    const code = generateClaimCode();
    users.push(user);
    emails.push(email);
    await cleanupUser(user);
    await seedWaitlistRow(email, code);

    const first = await claimWaitlistCode(user, code);
    const second = await claimWaitlistCode(user, code);
    expect(second.sub_credits_mills).toBe(first.sub_credits_mills);
    expect(second.extra_credits_mills).toBe(first.extra_credits_mills);
  });

  it('rejects a second, different code for an already-doubled user', async () => {
    const user = `${prefix}-already-doubled`;
    const email1 = `${user}-1@example.com`;
    const email2 = `${user}-2@example.com`;
    const code1 = generateClaimCode();
    const code2 = generateClaimCode();
    users.push(user);
    emails.push(email1, email2);
    await cleanupUser(user);
    await seedWaitlistRow(email1, code1);
    await seedWaitlistRow(email2, code2);

    await claimWaitlistCode(user, code1);
    await expect(claimWaitlistCode(user, code2)).rejects.toBeInstanceOf(AlreadyDoubledError);

    // The second code should remain unclaimed so it can still be used by someone else.
    const { data: row } = await supabaseAdmin
      .from('waitlist')
      .select('claimed_at, claimed_by_user_id')
      .eq('claim_code', code2)
      .maybeSingle();
    expect(row?.claimed_at).toBeNull();
    expect(row?.claimed_by_user_id).toBeNull();
  });

  it('rejects a code that another user already claimed', async () => {
    const userA = `${prefix}-owner`;
    const userB = `${prefix}-thief`;
    const email = `${userA}@example.com`;
    const code = generateClaimCode();
    users.push(userA, userB);
    emails.push(email);
    await cleanupUser(userA);
    await cleanupUser(userB);
    await seedWaitlistRow(email, code);

    await claimWaitlistCode(userA, code);
    await expect(claimWaitlistCode(userB, code)).rejects.toBeInstanceOf(AlreadyClaimedError);
  });
});
