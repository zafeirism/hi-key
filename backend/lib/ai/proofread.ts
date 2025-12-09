import OpenAI from 'openai';
import { z } from 'zod';
import { zodTextFormat } from 'openai/helpers/zod';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  dangerouslyAllowBrowser: true,
});

export interface ProofreadPrompt {
  improved_prompt: string;
}

const ProofreadPromptSchema = z.object({
  improved_prompt: z.string().describe('Improved image prompt'),
});

const format = zodTextFormat(ProofreadPromptSchema, 'proofreadPromptSchema');

const SYSTEM_PROMPT = `You are a proofreading assistant for AI image-generation prompts.
Your task is to proofread user prompts.

Guidelines:
- Make minimal changes: fix only grammar, spelling, and syntax; not content or meaning.
- If the prompt includes text meant to appear inside the generated image, do not edit that text; leave it exactly as provided.`;

export async function proofread(currentPrompt: string): Promise<ProofreadPrompt> {
  const response = await openai.responses.parse({
    model: 'gpt-4.1',
    input: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: currentPrompt },
    ],
    text: {
      format,
    },
    temperature: 1.2,
  });

  const result = response!.output_parsed as ProofreadPrompt;

  return result;
}
