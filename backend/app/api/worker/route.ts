import { NextRequest, NextResponse } from 'next/server';
import { verifySignatureAppRouter } from '@upstash/qstash/nextjs';
import { upsamplePrompt, UpsampledPrompt } from '@/lib/ai/prompt-upsampler';
import { supabaseAdmin } from '@/lib/supabase/server';
import { IMAGE_MODEL_SETUPS, ImageModelsEnum } from '@/lib/ai/image-models';
import { generateImage, pickModelRandomly } from '@/lib/ai/image-generator';
import { GenerationStatus } from '@/lib/supabase/helpers';

export const POST = verifySignatureAppRouter(async (request: NextRequest) => {
  const { generationIds } = await request.json();
  console.log(`Continuing on background for generation IDs: ${generationIds}`);

  const { data: generations, error: fetchError } = await supabaseAdmin
    .from('generations')
    .select('*')
    .in('id', generationIds);

  if (fetchError || !generations?.length || generations.length !== generationIds.length) {
    // TODO: Log error
    return NextResponse.json({ error: 'Generations not found' }, { status: 200 });
  }

  const upsampledPrompt = await upsamplePrompt(generations[0]!.user_prompt!, 2);
  const models = getAppropriateModels(upsampledPrompt);
  const prompts = upsampledPrompt.additional_prompts.concat(upsampledPrompt.improved_prompt);

  console.log(`Will run background generations with models ${models[0]} and ${models[1]}`);
  await Promise.all(
    models.map((model, idx) =>
      generateImage(model, {
        userPrompt: prompts[idx]!,
        generationId: generationIds[idx]!,
      })
    )
  );

  const [result1, result2] = await Promise.all([
    supabaseAdmin
      .from('generations')
      .update({
        improved_prompt: prompts[0]!,
        text_in_image: upsampledPrompt.user_phrases,
        model: models[0]!,
        cost_usd_mills: IMAGE_MODEL_SETUPS[models[0]!].costPerImage,
        status: 'generating' as GenerationStatus,
        generation_started_at: new Date().toISOString(),
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
        generation_started_at: new Date().toISOString(),
      })
      .eq('id', generationIds[1]!),
  ]);

  if (result1.error || result2.error) {
    // Consider rollback logic here if one succeeded
    return NextResponse.json(
      {
        error: 'Failed to update generations',
        details: { error1: result1.error, error2: result2.error },
      },
      { status: 200 }
    );
  }

  return NextResponse.json({
    success: true,
  });
});

function getAppropriateModels(upsampledPrompt: UpsampledPrompt): ImageModelsEnum[] {
  const result: ImageModelsEnum[] = [];

  if (upsampledPrompt.user_phrases.length > 0) {
    result.push(ImageModelsEnum.FLUX_KONTEXT_MAX);
    if (hasComplexText(upsampledPrompt.user_phrases)) {
      result.push(ImageModelsEnum.FLUX_KONTEXT_MAX);
    } else {
      const randomModel = pickModelRandomly([
        ImageModelsEnum.FLUX_KREA_DEV,
        ImageModelsEnum.IMAGEN_4_FAST,
        ImageModelsEnum.SD_3_5_LARGE_TURBO,
        ImageModelsEnum.FLUX_1_1_PRO,
      ]);
      result.push(randomModel);
    }
    return result;
  }

  result.push(ImageModelsEnum.FLUX_SCHNELL);
  if (upsampledPrompt.improved_prompt.includes('photorealistic')) {
    result.push(ImageModelsEnum.FLUX_KREA_DEV);
  } else {
    const randomModel = pickModelRandomly([
      ImageModelsEnum.FLUX_KREA_DEV,
      ImageModelsEnum.IMAGEN_4_FAST,
      ImageModelsEnum.SD_3_5_LARGE_TURBO,
      ImageModelsEnum.FLUX_1_1_PRO,
      ImageModelsEnum.FLUX_1_DEV,
    ]);
    result.push(randomModel);
  }
  return result;
}

function hasComplexText(userPhrases: string[]): boolean {
  return (
    userPhrases.length > 1 ||
    userPhrases.some((phrase) => phrase.split(/\s+/).length > 5 || phrase.length > 30)
  );
}
