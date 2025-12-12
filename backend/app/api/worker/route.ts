import { NextRequest, NextResponse } from 'next/server';
import { verifySignatureAppRouter } from '@upstash/qstash/nextjs';
import { upsamplePrompt } from '@/lib/ai/prompt-upsampler';
import { supabaseAdmin } from '@/lib/supabase/server';
import { IMAGE_MODEL_SETUPS, ImageModelsEnum } from '@/lib/ai/image-models';
import { generateImage } from '@/lib/ai/image-generator';
import { GenerationStatus } from '@/lib/supabase/helpers';

export const POST = verifySignatureAppRouter(async (request: NextRequest) => {
  const { generationIds, warmup } = await request.json();
  if (warmup) {
    return NextResponse.json({ success: true });
  }

  const [generationId] = generationIds;
  console.log(`${new Date().toISOString()} Worker received for generation IDs: ${generationIds}`);

  const fetchStartedAt = Date.now();
  const { data: generation, error: fetchError } = await supabaseAdmin
    .from('generations')
    .select('*')
    .eq('id', generationId!)
    .single();

  const fetchDurationMs = Date.now() - fetchStartedAt;

  if (fetchError || !generation) {
    console.error(
      `${new Date().toISOString()} Generation not found: ${generationId} - error: ${JSON.stringify(fetchError)}`
    );
    return NextResponse.json({ error: 'Generation not found' }, { status: 400 });
  }
  (generation.comments as { dbTimes: number[] })!.dbTimes!.push(fetchDurationMs);

  const upsamplingStartedAt = Date.now();
  const upsampledPrompt = await upsamplePrompt(generation.user_prompt!);
  const upsamplingDurationMs = Date.now() - upsamplingStartedAt;

  const model = ImageModelsEnum.FLUX_2_DEV;

  const generationStartedAt = new Date();
  await generateImage(model, {
    userPrompt: upsampledPrompt.improved_prompt,
    generationId: generationId!,
  });

  const { error: updateError } = await supabaseAdmin
    .from('generations')
    .update({
      improved_prompt: upsampledPrompt.improved_prompt,
      text_in_image: upsampledPrompt.user_phrases,
      model,
      cost_usd_mills: IMAGE_MODEL_SETUPS[model].costPerImage,
      status: 'generating' as GenerationStatus,
      upsampling_duration_ms: upsamplingDurationMs,
      generation_started_at: generationStartedAt.toISOString(),
      comments: generation.comments,
    })
    .eq('id', generationId);

  if (updateError) {
    console.error(
      `${new Date().toISOString()} Failed to update: ${generationId} - error: ${JSON.stringify(updateError)}`
    );
    return NextResponse.json(
      {
        error: 'Failed to update generation',
        details: { error: updateError },
      },
      { status: 400 }
    );
  }

  console.log(`${new Date().toISOString()} Worker completed successfully: ${generationId}`);
  return NextResponse.json({
    success: true,
  });
});
