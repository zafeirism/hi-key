import { NextResponse } from 'next/server';
import { withAuth } from '@/lib/auth/jwt';
import { toDisplayCredits } from '@/lib/credits/balance';
import { getProfile } from '@/lib/profile/profile';

export const GET = withAuth(async (_request, user) => {
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
