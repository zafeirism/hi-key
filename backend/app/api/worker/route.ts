import { NextRequest, NextResponse } from 'next/server';
import { verifySignatureAppRouter } from '@upstash/qstash/nextjs';
import { upsamplePrompt, UpsampledPrompt } from '@/lib/ai/prompt-upsampler';
import { supabaseAdmin } from '@/lib/supabase/server';
import { IMAGE_MODEL_SETUPS, ImageModelsEnum } from '@/lib/ai/image-models';
import { generateImage, pickModelRandomly } from '@/lib/ai/image-generator';
import { GenerationStatus } from '@/lib/supabase/helpers';

export const POST = verifySignatureAppRouter(async (request: NextRequest) => {
  const { generationIds } = await request.json();
  console.log(`${new Date().toISOString()} Worker received for generation IDs: ${generationIds}`);

  const { data: generations, error: fetchError } = await supabaseAdmin
    .from('generations')
    .select('*')
    .in('id', generationIds);

  if (fetchError || !generations?.length || generations.length !== generationIds.length) {
    console.error(
      `${new Date().toISOString()} Generations not found: ${generationIds} - error: ${JSON.stringify(fetchError)}`
    );
    return NextResponse.json({ error: 'Generations not found' }, { status: 200 });
  }

  const upsamplingStartedAt = Date.now();
  console.log(`${new Date().toISOString()} Worker upsampling for generation IDs: ${generationIds}`);
  const upsampledPrompt = await upsamplePrompt(generations[0]!.user_prompt!, 2);
  console.log(`${new Date().toISOString()} Worker upsampled for generation IDs: ${generationIds}`);
  const upsamplingDurationMs = Date.now() - upsamplingStartedAt;

  const models = getAppropriateModels(upsampledPrompt);
  const prompts = upsampledPrompt.additional_prompts.concat(upsampledPrompt.improved_prompt);

  const generationStartedAt = new Date();
  console.log(`${new Date().toISOString()} Worker posting models ${models[0]} and ${models[1]}`);
  await Promise.all(
    models.map((model, idx) =>
      generateImage(model, {
        userPrompt: prompts[idx]!,
        generationId: generationIds[idx]!,
      })
    )
  );
  console.log(`${new Date().toISOString()} Worker posted models ${models[0]} and ${models[1]}`);
  const [result1, result2] = await Promise.all([
    supabaseAdmin
      .from('generations')
      .update({
        improved_prompt: prompts[0]!,
        text_in_image: upsampledPrompt.user_phrases,
        model: models[0]!,
        cost_usd_mills: IMAGE_MODEL_SETUPS[models[0]!].costPerImage,
        status: 'generating' as GenerationStatus,
        upsampling_duration_ms: upsamplingDurationMs,
        generation_started_at: generationStartedAt.toISOString(),
      })
      .eq('id', generationIds[0]!),

    supabaseAdmin
      .from('generations')
      .update({
        improved_prompt: prompts[1]!,
        text_in_image: upsampledPrompt.user_phrases,
        model: models[1]!,
        cost_usd_mills: IMAGE_MODEL_SETUPS[models[1]!].costPerImage,
        status: 'generating' as GenerationStatus,
        upsampling_duration_ms: upsamplingDurationMs,
        generation_started_at: generationStartedAt.toISOString(),
      })
      .eq('id', generationIds[1]!),
  ]);

  if (result1.error || result2.error) {
    console.error(
      `${new Date().toISOString()} Failed to update: ${generationIds} - error: ${JSON.stringify(result1.error)}\n\n\n${JSON.stringify(result2.error)}`
    );
    return NextResponse.json(
      {
        error: 'Failed to update generations',
        details: { error1: result1.error, error2: result2.error },
      },
      { status: 200 }
    );
  }

  console.log(`${new Date().toISOString()} Worker completed successfully: ${generationIds}`);
  return NextResponse.json({
    success: true,
  });
});

function getAppropriateModels(upsampledPrompt: UpsampledPrompt): ImageModelsEnum[] {
  const result: ImageModelsEnum[] = [];

  if (upsampledPrompt.user_phrases.length > 0) {
    result.push(ImageModelsEnum.FLUX_2_PRO_UPSAMPLED);
    if (hasComplexText(upsampledPrompt.user_phrases)) {
      result.push(ImageModelsEnum.FLUX_2_PRO);
    } else {
      const randomModel = pickModelRandomly([
        ImageModelsEnum.FLUX_KREA_DEV,
        ImageModelsEnum.IMAGEN_4_FAST,
        ImageModelsEnum.FLUX_2_DEV,
        ImageModelsEnum.FLUX_2_PRO,
      ]);
      result.push(randomModel);
    }
    return result;
  }

  result.push(ImageModelsEnum.FLUX_SCHNELL);

  const randomModel = pickModelRandomly([
    ImageModelsEnum.FLUX_KREA_DEV,
    ImageModelsEnum.IMAGEN_4_FAST,
    ImageModelsEnum.FLUX_2_PRO_UPSAMPLED,
    ImageModelsEnum.FLUX_2_PRO,
    ImageModelsEnum.FLUX_2_DEV,
  ]);
  result.push(randomModel);

  return result;
}

function hasComplexText(userPhrases: string[]): boolean {
  return (
    userPhrases.length > 1 ||
    userPhrases.some((phrase) => phrase.split(/\s+/).length > 5 || phrase.length > 30)
  );
}
