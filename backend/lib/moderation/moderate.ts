import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  dangerouslyAllowBrowser: true,
});

export type ModerationResult =
  | { flagged: false }
  | { flagged: true; categories: string[] };

// Fail-open on errors: if OpenAI's moderation endpoint is down or slow, we let the
// request through rather than block all generations. The hardcoded blocklist is the
// hard safety net for the worst content; this is the second-line, broader filter.
export async function moderateWithOpenAI(prompt: string): Promise<ModerationResult> {
  try {
    const result = await openai.moderations.create({
      model: 'omni-moderation-latest',
      input: prompt,
    });

    const r = result.results[0];
    if (!r || !r.flagged) return { flagged: false };

    const categories = Object.entries(r.categories)
      .filter(([, isFlagged]) => isFlagged === true)
      .map(([name]) => name);

    return { flagged: true, categories };
  } catch (err) {
    console.error(`${new Date().toISOString()} OpenAI moderation failed: ${JSON.stringify(err)}`);
    return { flagged: false };
  }
}
