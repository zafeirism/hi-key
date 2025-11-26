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
  const webhookStartedAt = new Date();
  console.log(`${new Date().toISOString()} Replicate received`);
  const secret = process.env.REPLICATE_WEBHOOK_SIGNING_SECRET!;
  const webhookIsValid = await validateWebhook(request.clone(), secret);
  if (!webhookIsValid) {
    console.error('Webhook is invalid');
    return NextResponse.json({ detail: 'Webhook is invalid' }, { status: 401 });
  }

  const generationId = request.nextUrl.searchParams.get('id');
  console.log(`${new Date().toISOString()} Replicate validated for generation ID: ${generationId}`);
  if (!generationId) {
    console.error('Generation ID is required');
    return NextResponse.json({ detail: 'Generation ID is required' }, { status: 200 });
  }

  const { data: generation, error: fetchError } = await supabaseAdmin
    .from('generations')
    .select('*')
    .eq('id', generationId)
    .single();

  if (fetchError || !generation) {
    console.error(`Generation not found: ${generationId} - error: ${fetchError}`);
    return NextResponse.json({ error: 'Generation not found' }, { status: 200 });
  }

  console.log(`${new Date().toISOString()} Replicate fetched generation: ${generationId}`);
  const { id: replicateId, output, status, metrics, error } = await request.json();

  const imageUrl = Array.isArray(output) ? output[0] : output;
  if (!imageUrl || status !== 'succeeded') {
    console.error(`Replicate failed:  ${generationId}: ${status} - error: ${error}`);
    return NextResponse.json(
      { detail: `${generationId}: ${status} - Replicate prediction failed: ${error}` },
      { status: 200 }
    );
  }
  const imageResponse = await fetch(imageUrl);
  const imageBuffer = Buffer.from(await imageResponse.arrayBuffer());
  console.log(`${new Date().toISOString()} Replicate uploading for generation: ${generationId}`);
  await uploadImage(imageBuffer, generation.user_id!, generation.id, generation.file_extension!);
  console.log(`${new Date().toISOString()} Replicate uploaded for generation: ${generationId}`);

  const generationStartedAt = new Date(generation.generation_started_at!);
  const generationDurationMs = webhookStartedAt.getTime() - generationStartedAt.getTime();
  const createdAt = new Date(generation.created_at!);
  const totalDurationMs = Date.now() - createdAt.getTime();

  const { error: updateError } = await supabaseAdmin
    .from('generations')
    .update({
      file_size_bytes: imageBuffer.length,
      generation_duration_ms: generationDurationMs,
      total_duration_ms: totalDurationMs,
      status: 'ready' as GenerationStatus,
      comments: { replicateId, replicateTime: metrics?.total_time },
    })
    .eq('id', generationId);

  if (updateError) {
    console.error(`Failed to update generation: ${generationId} - error: ${updateError}`);
    return NextResponse.json({ error: 'Failed to update generation' }, { status: 200 });
  }

  console.log(`${new Date().toISOString()} Replicate completed for generation ${generationId}`);
  return NextResponse.json({ detail: 'Generation updated' }, { status: 200 });
}
