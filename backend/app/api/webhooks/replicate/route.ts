import { NextRequest, NextResponse } from 'next/server';
import { validateWebhook } from 'replicate';
import { supabaseAdmin } from '@/lib/supabase/server';
import type { GenerationStatus } from '@/lib/supabase/helpers';
import { uploadImage } from '@/lib/storage/r2';

/**
 * Webhook endpoint for Replicate predictions
 * Called when a prediction completes (success or failure)
 */
export async function POST(request: NextRequest) {
  const secret = process.env.REPLICATE_WEBHOOK_SIGNING_SECRET!;
  const webhookIsValid = await validateWebhook(request.clone(), secret);
  if (!webhookIsValid) {
    return NextResponse.json({ detail: 'Webhook is invalid' }, { status: 401 });
  }

  const generationId = request.nextUrl.searchParams.get('id');
  if (!generationId) {
    // TODO: Log error
    return NextResponse.json({ detail: 'Generation ID is required' }, { status: 200 });
  }

  const { data: generation, error: fetchError } = await supabaseAdmin
    .from('generations')
    .select('*')
    .eq('id', generationId)
    .single();

  if (fetchError || !generation) {
    // TODO: Log error
    return NextResponse.json({ error: 'Generation not found' }, { status: 200 });
  }

  const { output, status, error } = await request.json();
  const imageUrl = Array.isArray(output) ? output[0] : output;
  if (!imageUrl || status !== 'succeeded') {
    // TODO: Log error
    return NextResponse.json(
      { detail: `${generationId}: ${status} - Replicate prediction failed: ${error}` },
      { status: 200 }
    );
  }
  const imageResponse = await fetch(imageUrl);
  const imageBuffer = Buffer.from(await imageResponse.arrayBuffer());
  await uploadImage(imageBuffer, generation.user_id!, generation.id, generation.file_extension!);

  const startedAt = new Date(generation.generation_started_at!);
  const durationMs = Date.now() - startedAt.getTime();

  const { error: updateError } = await supabaseAdmin
    .from('generations')
    .update({
      file_size_bytes: imageBuffer.length,
      duration_ms: durationMs,
      status: 'ready' as GenerationStatus,
    })
    .eq('id', generationId);

  if (updateError) {
    // TODO: Log error
    return NextResponse.json({ error: 'Failed to update generation' }, { status: 200 });
  }

  return NextResponse.json({ detail: 'Generation updated' }, { status: 200 });
}
