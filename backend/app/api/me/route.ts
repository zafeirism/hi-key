import { NextResponse } from 'next/server';
import { isBypassUser, withAuth } from '@/lib/auth/jwt';
import { getBalance, toDisplayCredits } from '@/lib/credits/balance';

export const GET = withAuth(async (_request, user) => {
  if (isBypassUser(user)) {
    return NextResponse.json({
      credits: {
        sub_credits: 0,
        extra_credits: 0,
        next_reset_at: null,
      },
    });
  }

  const balance = await getBalance(user.id);
  return NextResponse.json({
    credits: {
      sub_credits: toDisplayCredits(balance.sub_credits_mills),
      extra_credits: toDisplayCredits(balance.extra_credits_mills),
      next_reset_at: null,
    },
  });
});
