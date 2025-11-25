import { NextResponse } from 'next/server';
import { withAuth } from '@/lib/auth/jwt';
import { supabaseAdmin } from '@/lib/supabase/server';
import type { GenerationInsert, GenerationStatus } from '@/lib/supabase/helpers';
import { generateImage, pickModelRandomly } from '@/lib/ai/image-generator';
import { ImageModelsEnum, IMAGE_MODEL_SETUPS } from '@/lib/ai/image-models';
import { continueOnBackground } from '@/lib/qstash/backgroundScheduler';
import { randomUUID } from 'crypto';
import { getKey, getSignedImageUrl } from '@/lib/storage/r2';

export const POST = withAuth(async (request, user) => {
  const body = await request.json();
  const { prompt, session_id, request_id } = body;

  if (!prompt || !session_id || !request_id) {
    return NextResponse.json(
      { error: 'prompt, session_id, and request_id are required' },
      { status: 400 }
    );
  }

  // 1. Create 4 generation records in Supabase - 2 that run now and 2 on the background
  const generationIds = [randomUUID(), randomUUID(), randomUUID(), randomUUID()];
  const randomModel = pickModelRandomly([
    ImageModelsEnum.FLUX_KREA_DEV,
    ImageModelsEnum.IMAGEN_4_FAST,
  ]);
  const imageModels = [
    IMAGE_MODEL_SETUPS[ImageModelsEnum.FLUX_SCHNELL],
    IMAGE_MODEL_SETUPS[randomModel],
    null, // We're creating the extra two that will run on the background
    null,
  ];
  console.log(
    `Will run immediately with models ${randomModel} and ${ImageModelsEnum.FLUX_SCHNELL}`
  );

  const records: GenerationInsert[] = generationIds.map((id, idx) => ({
    id,
    user_id: user.id,
    session_id,
    request_id,
    user_prompt: prompt,
    model: imageModels[idx]?.id,
    file_extension: imageModels[idx]?.outputFormat || 'jpg', // this is hardcoded to jpg for background generations
    cost_usd_mills: imageModels[idx]?.costPerImage,
    status: (imageModels[idx] ? 'generating' : 'initializing') as GenerationStatus,
    generation_started_at: imageModels[idx] ? new Date().toISOString() : null,
  }));

  const { error: insertError } = await supabaseAdmin.from('generations').insert(records);

  if (insertError) {
    return NextResponse.json({ error: 'Failed to create generations' }, { status: 500 });
  }

  // 2. Start generating the 2 images immediately
  await Promise.all(
    generationIds.slice(0, 2).map((id, idx) =>
      generateImage(imageModels[idx]!.id, {
        userPrompt: prompt,
        generationId: id,
      })
    )
  );

  // 3. Send the other 2 images to be worked on the background
  await continueOnBackground(generationIds.slice(2));

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
