import { NextResponse } from 'next/server';
import { isBypassUser, withAuth } from '@/lib/auth/jwt';
import { toDisplayCredits } from '@/lib/credits/balance';
import {
  AlreadyRedeemedError,
  CodeNotFoundError,
  InvalidCodeError,
  SelfReferralError,
  redeemReferralCode,
} from '@/lib/referrals/service';

export const POST = withAuth(async (request, user) => {
  if (isBypassUser(user)) {
    return NextResponse.json({ error: 'bypass_user' }, { status: 403 });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'invalid_json' }, { status: 400 });
  }

  const code = (body as { code?: unknown })?.code;
  if (typeof code !== 'string') {
    return NextResponse.json({ error: 'code is required' }, { status: 400 });
  }

  try {
    const balance = await redeemReferralCode(user.id, code);
    return NextResponse.json({
      credits: {
        sub_credits: toDisplayCredits(balance.sub_credits_mills),
        extra_credits: toDisplayCredits(balance.extra_credits_mills),
        next_reset_at: null,
      },
    });
  } catch (err) {
    if (err instanceof InvalidCodeError) {
      return NextResponse.json({ error: 'invalid_code' }, { status: 400 });
    }
    if (err instanceof SelfReferralError) {
      return NextResponse.json({ error: 'self_referral' }, { status: 400 });
    }
    if (err instanceof CodeNotFoundError) {
      return NextResponse.json({ error: 'code_not_found' }, { status: 404 });
    }
    if (err instanceof AlreadyRedeemedError) {
      return NextResponse.json(
        {
          error: 'already_redeemed',
          credits: {
            sub_credits: toDisplayCredits(err.balance.sub_credits_mills),
            extra_credits: toDisplayCredits(err.balance.extra_credits_mills),
            next_reset_at: null,
          },
        },
        { status: 409 }
      );
    }
    console.error(
      `${new Date().toISOString()} Failed to redeem referral code: ${
        err instanceof Error ? err.message : String(err)
      }`
    );
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }
});
