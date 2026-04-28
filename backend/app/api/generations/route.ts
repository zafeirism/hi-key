import { NextResponse } from 'next/server';
import { withAuth } from '@/lib/auth/jwt';
import { supabaseAdmin } from '@/lib/supabase/server';

const MAX_IDS = 16;

export const POST = withAuth(async (request, user) => {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'invalid_json' }, { status: 400 });
  }

  const ids = (body as { ids?: unknown })?.ids;
  if (!Array.isArray(ids) || !ids.every((id) => typeof id === 'string')) {
    return NextResponse.json({ error: 'ids must be an array of strings' }, { status: 400 });
  }

  if (ids.length === 0) {
    return NextResponse.json({ generations: [] });
  }

  if (ids.length > MAX_IDS) {
    return NextResponse.json({ error: `too many ids (max ${MAX_IDS})` }, { status: 400 });
  }

  const { data, error } = await supabaseAdmin
    .from('generations')
    .select('id, status')
    .eq('user_id', user.id)
    .in('id', ids as string[]);

  if (error) {
    console.error(
      `${new Date().toISOString()} Failed to fetch generations: ${JSON.stringify(error)}`
    );
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }

  return NextResponse.json({ generations: data ?? [] });
});
