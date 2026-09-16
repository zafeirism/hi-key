import { NextResponse } from 'next/server';
import { isBypassUser, withAuth } from '@/lib/auth/jwt';
import { supabaseAdmin } from '@/lib/supabase/server';
import type { GenerationInsert, GenerationStatus } from '@/lib/supabase/helpers';
import { generateImage } from '@/lib/ai/image-generator';
import { ImageModelsEnum, IMAGE_MODEL_SETUPS } from '@/lib/ai/image-models';
import { continueOnBackground } from '@/lib/qstash/backgroundScheduler';
import { randomUUID } from 'crypto';
import { getKey, getSignedImageUrl } from '@/lib/storage/r2';
import { hasStyle } from '@/lib/ai/detectPromptStyle';
import { proofread } from '@/lib/ai/proofread';
import { checkBlocklist } from '@/lib/moderation/blocklist';
import { moderateWithOpenAI } from '@/lib/moderation/moderate';
import {
  debit,
  grant,
  InsufficientCreditsError,
  toDisplayCredits,
  type Balance,
} from '@/lib/credits/balance';

// UPDATE: Changed to GPT_IMAGE_25_FLARE because FLUX are now queued on Replicate
// The 4th image runs in /api/worker, which picks FLUX_2_DEV (12 mills) or FLUX_2_KLEIN (1 mill)
// at runtime based on whether the prompt has text phrases. We reserve the ceiling at /generate
// time and let the Replicate webhook refund the delta once the actual cost_usd_mills is known.
const WORKER_IMAGE_RESERVED_MILLS =
  IMAGE_MODEL_SETUPS[ImageModelsEnum.GPT_IMAGE_25_FLARE].costPerImage;

export const POST = withAuth(async (request, user) => {
  const requestStartedAt = new Date();
  const body = await request.json();
  const { prompt, session_id, request_id, warmup, random_styles } = body;

  if (warmup) {
    return NextResponse.json({ success: true });
  }

  if (!prompt || !session_id || !request_id) {
    return NextResponse.json(
      { error: 'prompt, session_id, and request_id are required' },
      { status: 400 }
    );
  }

  if (
    random_styles !== undefined &&
    (!Array.isArray(random_styles) || random_styles.some((s) => typeof s !== 'string'))
  ) {
    return NextResponse.json(
      { error: 'random_styles must be an array of strings' },
      { status: 400 }
    );
  }

  // First-line moderation: synchronous blocklist. Hits return 403 before any DB write
  // or debit. No logging, no audit row — keep this path as cheap as possible.
  if (checkBlocklist(prompt)) {
    return NextResponse.json({ error: 'blocked' }, { status: 403 });
  }

  const promptAnalysisStartedAt = Date.now();
  const hasStyleTask = hasStyle(prompt);
  const proofreadTask = proofread(prompt);
  const moderationTask = moderateWithOpenAI(prompt);

  // 1. Create 4 generation records in Supabase - 2 that run now and 2 on the background
  const generationIds = [randomUUID(), randomUUID(), randomUUID(), randomUUID()];

  const imageModels = [
    IMAGE_MODEL_SETUPS[ImageModelsEnum.GPT_IMAGE_25_FLARE],
    IMAGE_MODEL_SETUPS[ImageModelsEnum.NANO_BANANA_2_LITE],
    IMAGE_MODEL_SETUPS[ImageModelsEnum.NANO_BANANA_2_LITE],
    null, // We're creating an extra that will run on the background
  ];

  const reservedPerImage = [
    imageModels[0]!.costPerImage,
    imageModels[1]!.costPerImage,
    imageModels[2]!.costPerImage,
    WORKER_IMAGE_RESERVED_MILLS,
  ];
  const totalReservedMills = reservedPerImage.reduce((a, b) => a + b, 0);

  // 2. Debit credits up-front (bypass tokens skip this).
  const bypass = isBypassUser(user);
  let balanceAfterDebit: Balance | null = null;
  if (!bypass) {
    try {
      balanceAfterDebit = await debit(user.id, totalReservedMills, {
        reason: 'generation_debit',
        sourceId: request_id,
        generationId: generationIds[0]!,
      });
    } catch (err) {
      if (err instanceof InsufficientCreditsError) {
        return NextResponse.json(
          {
            error: 'insufficient_credits',
            balance: {
              sub_credits: toDisplayCredits(err.balance.sub_credits_mills),
              extra_credits: toDisplayCredits(err.balance.extra_credits_mills),
            },
          },
          { status: 402 }
        );
      }
      throw err;
    }
  }

  const records: GenerationInsert[] = generationIds.map((id, idx) => ({
    id,
    user_id: user.id,
    session_id,
    request_id,
    created_at: requestStartedAt.toISOString(),
    user_prompt: prompt,
    model: imageModels[idx]?.id,
    file_extension: imageModels[idx]?.outputFormat,
    cost_usd_mills: imageModels[idx]?.costPerImage,
    reserved_usd_mills: reservedPerImage[idx]!,
    status: (imageModels[idx] ? 'generating' : 'initializing') as GenerationStatus,
    generation_started_at: imageModels[idx] ? new Date().toISOString() : null,
    comments: { dbTimes: [] },
  }));

  const dbInsertStartedAt = Date.now();
  const { error: insertError } = await supabaseAdmin.from('generations').insert(records);
  const dbInsertDurationMs = Date.now() - dbInsertStartedAt;

  if (insertError) {
    console.error(
      `${new Date().toISOString()} Failed to create generations: ${JSON.stringify(insertError)}`
    );
    if (!bypass) {
      // Refund the reservation since no generation rows exist to drive per-image
      // webhook refunds. Mirror the debit row's split so credits land back in the
      // same buckets they came from.
      try {
        const { data: debitRow } = await supabaseAdmin
          .from('credit_transactions')
          .select('delta_sub_mills, delta_extra_mills')
          .eq('user_id', user.id)
          .eq('reason', 'generation_debit')
          .eq('source_id', request_id)
          .maybeSingle();
        if (debitRow) {
          await grant(user.id, {
            deltaSubMills: -debitRow.delta_sub_mills,
            deltaExtraMills: -debitRow.delta_extra_mills,
            reason: 'generation_refund',
            sourceId: request_id,
          });
        }
      } catch (e) {
        console.error(
          `${new Date().toISOString()} Refund-on-insert-failure failed: ${JSON.stringify(e)}`
        );
      }
    }
    return NextResponse.json({ error: 'Failed to create generations' }, { status: 500 });
  }

  const [hasStyleResult, proofreadResult, moderationResult] = await Promise.all([
    hasStyleTask,
    proofreadTask,
    moderationTask,
  ]);
  const promptAnalysisDurationMs = Date.now() - promptAnalysisStartedAt;

  // Second-line moderation: OpenAI flagged the prompt. Mark the records we just inserted
  // as blocked, refund the debit (if any), and 403. We accept the wasted DB writes +
  // refund round-trip on this rare path to keep the 99% common case off the critical path.
  if (moderationResult.flagged) {
    console.warn(
      `${new Date().toISOString()} Prompt blocked by OpenAI moderation: ${JSON.stringify({
        userId: user.id,
        requestId: request_id,
        categories: moderationResult.categories,
      })}`
    );

    const blockUpdateTask = supabaseAdmin
      .from('generations')
      .update({
        status: 'blocked' as GenerationStatus,
        comments: { moderation: { source: 'openai', categories: moderationResult.categories } },
      })
      .in('id', generationIds);

    const refundTask: Promise<Balance | null> = bypass
      ? Promise.resolve(null)
      : (async () => {
          const { data: debitRow } = await supabaseAdmin
            .from('credit_transactions')
            .select('delta_sub_mills, delta_extra_mills')
            .eq('user_id', user.id)
            .eq('reason', 'generation_debit')
            .eq('source_id', request_id)
            .maybeSingle();
          if (!debitRow) return null;
          return grant(user.id, {
            deltaSubMills: -debitRow.delta_sub_mills,
            deltaExtraMills: -debitRow.delta_extra_mills,
            reason: 'generation_refund',
            sourceId: request_id,
          });
        })();

    const [blockUpdate, refundedBalance] = await Promise.all([blockUpdateTask, refundTask]);

    if (blockUpdate.error) {
      console.error(
        `${new Date().toISOString()} Failed to mark generations as blocked: ${JSON.stringify(blockUpdate.error)}`
      );
    }

    return NextResponse.json({ error: 'blocked' }, { status: 403 });
  }

  const prompts: string[] = [];
  const styles: string[] = (random_styles ?? []).slice(0, 3);
  if (hasStyleResult.has_style || styles.length === 0) {
    prompts.push(
      proofreadResult.improved_prompt,
      proofreadResult.improved_prompt,
      proofreadResult.improved_prompt
    );
  } else {
    for (let i = 0; i < 3; i++) {
      const style = styles[i % styles.length]!;
      prompts.push(`${style} style: ${proofreadResult.improved_prompt}`);
    }
  }

  // Start generating the 3 images and send the last one on the background
  const delegationStartedAt = Date.now();
  await Promise.all(
    imageModels
      .slice(0, 3)
      .map((m, idx) =>
        generateImage(m!.id, {
          userPrompt: prompts[idx]!,
          generationId: generationIds[idx]!,
        })
      )
      .concat([continueOnBackground(generationIds.slice(3))])
  );
  const delegationDurationMs = Date.now() - delegationStartedAt;

  const udpateTasks = generationIds.slice(0, 3).map((id, idx) => {
    return supabaseAdmin
      .from('generations')
      .update({
        improved_prompt: prompts[idx]!,
        comments: { dbTimes: [dbInsertDurationMs], promptAnalysisDurationMs, delegationDurationMs },
      })
      .eq('id', id);
  });

  const updateErrors = await Promise.all(udpateTasks);

  if (updateErrors.some(({ error }) => !!error)) {
    console.error(
      `${new Date().toISOString()} Failed to update generations: ${JSON.stringify(updateErrors)}`
    );
  }

  // 4. Create signed urls for all 4 images and return to the client
  const images = await Promise.all(
    generationIds.map(async (id, idx) => ({
      id,
      signedUrl: await getSignedImageUrl(
        getKey(user.id, id, imageModels[idx]?.outputFormat || 'webp')
      ),
    }))
  );

  return NextResponse.json({
    success: true,
    images,
    ...(balanceAfterDebit && {
      balance: {
        sub_credits: toDisplayCredits(balanceAfterDebit.sub_credits_mills),
        extra_credits: toDisplayCredits(balanceAfterDebit.extra_credits_mills),
      },
    }),
  });
});
