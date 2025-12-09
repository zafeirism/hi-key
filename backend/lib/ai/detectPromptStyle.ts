import OpenAI from 'openai';
import { z } from 'zod';
import { zodTextFormat } from 'openai/helpers/zod';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  dangerouslyAllowBrowser: true,
});

export interface DetectPromptStyle {
  has_style: boolean;
}

const DetectPromptStyleSchema = z.object({
  has_style: z.boolean().describe('Whether the prompt has a visual style'),
});

const format = zodTextFormat(DetectPromptStyleSchema, 'detectPromptStyleSchema');

const SYSTEM_PROMPT = `You are a Visual Style Detector for AI image-generation prompts.
Your task is to determine whether the given user prompt explicitly or implicitly references a visual style.

Guidelines
- Return \`true\` if the prompt specifies or clearly implies any visual style.
- Return \`false\` if no visual style is present.
- A visual style can include (but is not limited to) terms such as: Watercolor, Oil painting, Pastel, Charcoal, Comic book, Manga, Graphic novel, Pixar-like, Ghibli-like, Disney Renaissance, 90s anime, Impressionist, Surrealist, Expressionist, Pop art, Vaporwave, Synthwave, Cyberpunk, Steampunk, Photorealistic, Cinematic, Documentary, Analog film, Retro poster, Minimalism, Low poly, Pixel art, Sketch, 3D render, Realism, Hyperrealism, Baroque, Rococo, Art Nouveau, Art Deco, Cubism, Fauvism, Ukiyo-e, Noir, Film noir, Neon noir, Fantasy illustration, Matte painting, Isometric, Line art, Chiaroscuro, Graffiti, Street art.
- These examples are not exhaustive, and the style does not need to match the wording above exactly.`;

export async function hasStyle(prompt: string): Promise<DetectPromptStyle> {
  const response = await openai.responses.parse({
    model: 'gpt-4.1',
    input: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: prompt },
    ],
    text: {
      format,
    },
    temperature: 0.8,
  });

  const result = response!.output_parsed as DetectPromptStyle;

  return result;
}
