import { NextResponse } from 'next/server';
import { withAuth } from '@/lib/auth/jwt';
import { supabaseAdmin } from '@/lib/supabase/server';

export const POST = withAuth(async (request, user) => {
  const body = await request.json();
  const { generationId } = body;

  if (!generationId) {
    return NextResponse.json({ error: 'generationId is required' }, { status: 400 });
  }

  const { data: generation, error: fetchError } = await supabaseAdmin
    .from('generations')
    .select('id, user_id')
    .eq('id', generationId)
    .single();

  if (fetchError || !generation) {
    return NextResponse.json({ error: 'Generation not found' }, { status: 404 });
  }

  if (generation.user_id !== user.id) {
    return NextResponse.json({ error: 'Generation not found' }, { status: 404 });
  }

  const { error: updateError } = await supabaseAdmin
    .from('generations')
    .update({ copied_at: new Date().toISOString() })
    .eq('id', generationId);

  if (updateError) {
    console.error(
      `${new Date().toISOString()} Failed to update copied_at: ${JSON.stringify(updateError)}`
    );
    return NextResponse.json({ error: 'Failed to update generation' }, { status: 500 });
  }

  return NextResponse.json({ success: true });
});
