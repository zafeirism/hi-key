import { NextResponse } from 'next/server';
import { withAuth } from '@/lib/auth/jwt';
import { getOrCreateReferralCode, InvalidNameError } from '@/lib/referrals/service';

export const POST = withAuth(async (request, user) => {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'invalid_json' }, { status: 400 });
  }

  const name = (body as { name?: unknown })?.name;
  if (typeof name !== 'string') {
    return NextResponse.json({ error: 'name is required' }, { status: 400 });
  }

  try {
    const profile = await getOrCreateReferralCode(user.id, name);
    return NextResponse.json({ name: profile.name, code: profile.code });
  } catch (err) {
    if (err instanceof InvalidNameError) {
      return NextResponse.json({ error: 'invalid_name' }, { status: 400 });
    }
    console.error(
      `${new Date().toISOString()} Failed to create referral code: ${
        err instanceof Error ? err.message : String(err)
      }`
    );
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }
});
