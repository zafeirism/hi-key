import { NextResponse } from 'next/server';
import { isBypassUser, withAuth } from '@/lib/auth/jwt';
import { getBalance, toDisplayCredits } from '@/lib/credits/balance';
import { getReferralProfile } from '@/lib/referrals/service';

export const GET = withAuth(async (_request, user) => {
  if (isBypassUser(user)) {
    return NextResponse.json({
      credits: {
        sub_credits: 0,
        extra_credits: 0,
        next_reset_at: null,
      },
      profile: null,
      referred_by: null,
    });
  }

  const [balance, profile] = await Promise.all([
    getBalance(user.id),
    getReferralProfile(user.id),
  ]);

  return NextResponse.json({
    credits: {
      sub_credits: toDisplayCredits(balance.sub_credits_mills),
      extra_credits: toDisplayCredits(balance.extra_credits_mills),
      next_reset_at: null,
    },
    profile: {
      name: profile.name,
      referral_code: profile.referral_code,
    },
    referred_by: profile.referred_by,
  });
});
