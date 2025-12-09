import { NextResponse } from 'next/server';
import { withAuth } from '@/lib/auth/jwt';
import { supabaseAdmin } from '@/lib/supabase/server';
import type { GenerationInsert, GenerationStatus } from '@/lib/supabase/helpers';
import { generateImage } from '@/lib/ai/image-generator';
import { ImageModelsEnum, IMAGE_MODEL_SETUPS } from '@/lib/ai/image-models';
import { continueOnBackground } from '@/lib/qstash/backgroundScheduler';
import { randomUUID } from 'crypto';
import { getKey, getSignedImageUrl } from '@/lib/storage/r2';
import { hasStyle } from '@/lib/ai/detectPromptStyle';
import { proofread } from '@/lib/ai/proofread';
import { pickStylesRandomly } from '@/lib/ai/imageStyles';

export const POST = withAuth(async (request, user) => {
  const requestStartedAt = new Date();
  const body = await request.json();
  const { prompt, session_id, request_id } = body;

  if (!prompt || !session_id || !request_id) {
    return NextResponse.json(
      { error: 'prompt, session_id, and request_id are required' },
      { status: 400 }
    );
  }

  const hasStyleTask = hasStyle(prompt);
  const proofreadTask = proofread(prompt);

  // 1. Create 4 generation records in Supabase - 2 that run now and 2 on the background
  const generationIds = [randomUUID(), randomUUID(), randomUUID(), randomUUID()];

  const imageModels = [
    IMAGE_MODEL_SETUPS[ImageModelsEnum.FLUX_2_DEV],
    IMAGE_MODEL_SETUPS[ImageModelsEnum.FLUX_2_PRO],
    IMAGE_MODEL_SETUPS[ImageModelsEnum.FLUX_2_PRO_UPSAMPLED],
    null, // We're creating an extra that will run on the background
  ];

  const records: GenerationInsert[] = generationIds.map((id, idx) => ({
    id,
    user_id: user.id,
    session_id,
    request_id,
    created_at: requestStartedAt.toISOString(),
    user_prompt: prompt,
    model: imageModels[idx]?.id,
    file_extension: imageModels[idx]?.outputFormat || 'jpg', // this is hardcoded to jpg for background generations
    cost_usd_mills: imageModels[idx]?.costPerImage,
    status: (imageModels[idx] ? 'generating' : 'initializing') as GenerationStatus,
    generation_started_at: imageModels[idx] ? new Date().toISOString() : null,
  }));

  const { error: insertError } = await supabaseAdmin.from('generations').insert(records);

  if (insertError) {
    console.error(
      `${new Date().toISOString()} Failed to create generations: ${JSON.stringify(insertError)}`
    );
    return NextResponse.json({ error: 'Failed to create generations' }, { status: 500 });
  }

  const [hasStyleResult, proofreadResult] = await Promise.all([hasStyleTask, proofreadTask]);

  const prompts: string[] = [];
  if (hasStyleResult.has_style) {
    prompts.push(
      proofreadResult.improved_prompt,
      proofreadResult.improved_prompt,
      proofreadResult.improved_prompt
    );
  } else {
    const styles = pickStylesRandomly(3);
    for (const style of styles) {
      prompts.push(`${style} style: ${proofreadResult.improved_prompt}`);
      console.log(`${style} style: ${proofreadResult.improved_prompt}`);
    }
  }

  // 2. Start generating the 3 images immediately
  await Promise.all(
    imageModels.slice(0, 3).map((m, idx) =>
      generateImage(m!.id, {
        userPrompt: prompts[idx]!,
        generationId: generationIds[idx]!,
      })
    )
  );

  // 3. Send the last image to be worked on the background
  await continueOnBackground(generationIds.slice(3));

  // 4. Create signed urls for all 4 images and return to the client
  const signedUrls = await Promise.all(
    generationIds.map((id, idx) =>
      getSignedImageUrl(getKey(user.id, id, imageModels[idx]?.outputFormat || 'jpg'))
    )
  );

  return NextResponse.json({
    success: true,
    signedUrls,
  });
});
