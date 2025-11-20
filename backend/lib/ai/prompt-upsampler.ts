import OpenAI from 'openai';
import { z } from 'zod';
import { zodTextFormat } from 'openai/helpers/zod';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  dangerouslyAllowBrowser: true,
});

/**
 * Response format from OpenAI prompt upsampling
 */
export interface UpsampledPrompt {
  improved_prompt: string;
  user_phrases: string[];
  additional_prompts: string[];
}

/**
 * Zod schema for upsampled prompt response
 */
const UpsampledPromptSchema = z.object({
  improved_prompt: z.string().describe('Detailed 40-60 word image generation prompt'),
  user_phrases: z.array(z.string()).describe('Array of phrases to render inside the image'),
});

const format = zodTextFormat(UpsampledPromptSchema, 'upsampledPromptSchema');

/**
 * Zod schema for just the improved prompt response
 */
const ImprovedPromptSchema = z.object({
  improved_prompt: z.string().describe('Detailed ~20 word image generation prompt'),
});

const smallPromptFormat = zodTextFormat(ImprovedPromptSchema, 'improvedPromptSchema');

/**
 * Converts short user prompts into detailed image generation prompts
 */
const SYSTEM_PROMPT = `You are a playful prompt rewriter for a mobile keyboard app that generates AI images.

The user provides a short, free-form scene description (a few words, often fragments, commas, or keywords). Rewrite it into a detailed image prompt and extract any phrases that should appear inside the image.

## user_phrases rules
- List every distinct piece of text the image should visibly contain.
- Include exact wording from quotes or patterns like: "sign that says ...", "reads ...", "label says ...".
- Use EXACT wording from the user when possible. Do not paraphrase, translate or proofread their quoted phrases.
- Do not include generic UI words unless explicitly requested.
- Only include wording the user clearly wants rendered inside the image.
- Only when clearly implied by the description, you may include short conventional sign text like STOP or NO PARKING.

## improved_prompt rules
- 40-60 words, one paragraph, no line breaks.
- Always in English.
- Always include all user_phrases in the improved_prompt.
- Clear, concrete, grammatically correct.
- Describe main subject(s), props, setting/environment, artistic style, mood/lighting, composition/camera angle etc.
- Do NOT mention the user or the prompt itself.
- If the scene includes visible text, include it naturally in the description but do NOT reference "text inside the image" explicitly.

## Style & safety
- Respect user intent, main idea, style, mood etc. but be creative if they haven't specified these details.
- Mild profanity is allowed; hateful or sexual content is not.
- If unsafe content is requested, reinterpret it to a safe, non-harmful version.
- Crude humor ("poop", "shit", "middle finger", "wtf") is allowed if aligned with user intent; hateful or explicit sexual content is never allowed.
- Do not reference real living artists by name. If the user gives one, describe the style indirectly. Generic labels ("ghibli-inspired", "anime", "pixel art", "Pixar-style") are fine.

## General rules
- The improved prompt must be descriptive, vivid, and helpful for text-to-image models.
- The improved prompt should always be in English.
- Prioritize clarity over excessive detail.
- If no visible text is requested, return user_phrases as an empty array.`;

const SYSTEM_PROMPT_SMALL = `You are a playful prompt rewriter for a mobile keyboard app that generates AI images.

The user provides a short, free-form scene description (a few words, often fragments, commas, or keywords). Rewrite it into a detailed image prompt for optimal visual results.

## improved_prompt rules
- 20-25 words, one paragraph, no line breaks.
- Always in English.
- If the user mentions phrases to appear in the image, use their EXACT wording when possible. Do not paraphrase, translate or proofread their quoted phrases.
- Clear, concrete, grammatically correct.
- Describe main subject(s), props, setting/environment, artistic style, mood/lighting, composition/camera angle etc.
- Do NOT mention the user or the prompt itself.
- If the scene includes visible text, include it naturally in the description but do NOT reference "text inside the image" explicitly.

## Style & safety
- Respect user intent, main idea, style, mood etc. but be creative if they haven't specified these details.
- Mild profanity is allowed; hateful or sexual content is not.
- If unsafe content is requested, reinterpret it to a safe, non-harmful version.
- Crude humor ("poop", "shit", "middle finger", "wtf") is allowed if aligned with user intent; hateful or explicit sexual content is never allowed.
- Do not reference real living artists by name. If the user gives one, describe the style indirectly. Generic labels ("ghibli-inspired", "anime", "pixel art", "Pixar-style") are fine.

## General rules
- The improved prompt must be descriptive, vivid, and helpful for text-to-image models.
- The improved prompt should always be in English.
- Prioritize clarity over excessive detail.`;
/**
 * Upsample a user's short prompt into a detailed image generation prompt
 *
 * @param userPrompt - Short user input (e.g., "cat in space")
 * @param total - Number of prompts to generate (default: 1)
 * @returns Upsampled prompt with improved_prompt and texts array
 * @throws Error if OpenAI API fails or returns invalid response
 */
export async function upsamplePrompt(
  userPrompt: string,
  total: number = 1
): Promise<UpsampledPrompt> {
  const requests = [];
  requests.push(
    openai.responses.parse({
      model: 'gpt-4.1-mini',
      input: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userPrompt },
      ],
      text: {
        format,
      },
      temperature: 1.2,
    })
  );

  for (let i = 1; i < total; i++) {
    requests.push(
      openai.responses.parse({
        model: 'gpt-4.1-mini',
        input: [
          { role: 'system', content: SYSTEM_PROMPT_SMALL },
          { role: 'user', content: userPrompt },
        ],
        text: {
          format: smallPromptFormat,
        },
        temperature: 1.2,
      })
    );
  }
  const responses = await Promise.all(requests);
  const result = responses[0]!.output_parsed as UpsampledPrompt;
  result.additional_prompts = [];
  responses.slice(1).forEach((response) => {
    const parsedResponse = response.output_parsed as UpsampledPrompt;
    result.additional_prompts.push(parsedResponse.improved_prompt);
  });

  return result;
}
