import { NextResponse } from 'next/server';
import { isBypassUser, withAuth } from '@/lib/auth/jwt';
import { toDisplayCredits } from '@/lib/credits/balance';
import { getProfile } from '@/lib/profile/profile';

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
      double_credits: false,
      active_sub_product_id: null,
    });
  }

  const profile = await getProfile(user.id);

  return NextResponse.json({
    credits: {
      sub_credits: toDisplayCredits(profile.sub_credits_mills),
      extra_credits: toDisplayCredits(profile.extra_credits_mills),
      next_reset_at: null,
    },
    profile: {
      name: profile.name,
      referral_code: profile.referral_code,
    },
    referred_by: profile.referred_by,
    double_credits: profile.double_credits,
    active_sub_product_id: profile.active_sub_product_id,
  });
});
