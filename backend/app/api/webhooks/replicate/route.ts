import { NextRequest, NextResponse } from 'next/server';
import { validateWebhook } from 'replicate';
import { supabaseAdmin } from '@/lib/supabase/server';
import type { GenerationStatus } from '@/lib/supabase/helpers';
import { uploadImage } from '@/lib/storage/r2';
import { grant } from '@/lib/credits/balance';

function isBypassUserId(userId: string | null | undefined): boolean {
  if (!userId) return true;
  return (
    userId.startsWith('demo-') || userId.startsWith('warmup-') || userId.startsWith('social-')
  );
}

async function refundGeneration(
  userId: string,
  generationId: string,
  amountMills: number
): Promise<void> {
  if (amountMills <= 0) return;
  try {
    await grant(userId, {
      deltaSubMills: amountMills,
      deltaExtraMills: 0,
      reason: 'generation_refund',
      sourceId: generationId,
      generationId,
    });
  } catch (err) {
    console.error(
      `${new Date().toISOString()} Refund failed for generation ${generationId} (${amountMills} mills): ${JSON.stringify(err)}`
    );
  }
}

/**
 * Webhook endpoint for Replicate predictions
 * Called when a prediction completes (success or failure)
 */
export async function POST(request: NextRequest) {
  const webhookStartedAt = new Date();
  const generationId = request.nextUrl.searchParams.get('id');

  if (generationId === 'warmup') {
    return NextResponse.json({ status: 200 });
  }

  console.log(`${new Date().toISOString()} Replicate received`);
  const secret = process.env.REPLICATE_WEBHOOK_SIGNING_SECRET!;
  const webhookIsValid = await validateWebhook(request.clone(), secret);
  if (!webhookIsValid) {
    console.error(`${new Date().toISOString()} Webhook is invalid`);
    return NextResponse.json({ detail: 'Webhook is invalid' }, { status: 401 });
  }

  if (!generationId) {
    console.error(`${new Date().toISOString()} Generation ID is required`);
    return NextResponse.json({ detail: 'Generation ID is required' }, { status: 200 });
  }

  const fetchStartedAt = Date.now();
  const { data: generation, error: fetchError } = await supabaseAdmin
    .from('generations')
    .select('*')
    .eq('id', generationId)
    .single();
  const fetchDurationMs = Date.now() - fetchStartedAt;

  if (fetchError || !generation) {
    console.error(
      `${new Date().toISOString()} Generation not found: ${generationId} - error: ${JSON.stringify(fetchError)}`
    );
    return NextResponse.json({ error: 'Generation not found' }, { status: 200 });
  }
  (generation.comments as { dbTimes: number[] })!.dbTimes!.push(fetchDurationMs);

  const replicateFetchStartedAt = Date.now();
  const { id: replicateId, output, status, metrics, error } = await request.json();

  const imageUrl = Array.isArray(output) ? output[0] : output;
  if (!imageUrl || status !== 'succeeded') {
    console.error(
      `${new Date().toISOString()} Replicate failed:  ${generationId}: ${status} - error: ${JSON.stringify(error)}`
    );
    if (!isBypassUserId(generation.user_id) && generation.reserved_usd_mills) {
      await refundGeneration(
        generation.user_id!,
        generation.id,
        generation.reserved_usd_mills
      );
    }
    await supabaseAdmin
      .from('generations')
      .update({ status: 'error' as GenerationStatus })
      .eq('id', generationId);
    return NextResponse.json(
      { detail: `${generationId}: ${status} - Replicate prediction failed: ${error}` },
      { status: 200 }
    );
  }
  const imageResponse = await fetch(imageUrl);
  const imageBuffer = Buffer.from(await imageResponse.arrayBuffer());
  const replicateFetchDurationMs = Date.now() - replicateFetchStartedAt;

  const r2UploadStartedAt = Date.now();
  await uploadImage(imageBuffer, generation.user_id!, generation.id, generation.file_extension!);
  const r2UploadDurationMs = Date.now() - r2UploadStartedAt;

  (generation.comments as { replicateFetchDurationMs: number })!.replicateFetchDurationMs =
    replicateFetchDurationMs;
  (generation.comments as { r2UploadDurationMs: number })!.r2UploadDurationMs = r2UploadDurationMs;
  (generation.comments as { replicateTime: number })!.replicateTime = metrics?.total_time;
  (generation.comments as { replicateId: string })!.replicateId = replicateId;

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
      comments: generation.comments,
    })
    .eq('id', generationId);

  if (updateError) {
    console.error(
      `${new Date().toISOString()} Failed to update generation: ${generationId} - error: ${JSON.stringify(updateError)}`
    );
    return NextResponse.json({ error: 'Failed to update generation' }, { status: 200 });
  }

  if (
    !isBypassUserId(generation.user_id) &&
    generation.reserved_usd_mills != null &&
    generation.cost_usd_mills != null
  ) {
    const refundMills = generation.reserved_usd_mills - generation.cost_usd_mills;
    if (refundMills > 0) {
      await refundGeneration(generation.user_id!, generation.id, refundMills);
    }
  }

  console.log(`${new Date().toISOString()} Replicate completed for generation ${generationId}`);
  return NextResponse.json({ detail: 'Generation updated' }, { status: 200 });
}
