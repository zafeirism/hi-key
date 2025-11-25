import Replicate from 'replicate';
import { IMAGE_MODEL_SETUPS, ImageModelsEnum } from './image-models';

const replicate = new Replicate({
  auth: process.env.REPLICATE_API_TOKEN,
});

/**
 * Options for image generation
 */
export interface GenerateImagesOptions {
  userPrompt: string;
  generationId: string;
}

export async function generateImage(model: ImageModelsEnum, options: GenerateImagesOptions) {
  const { userPrompt, generationId } = options;
  const modelSetup = IMAGE_MODEL_SETUPS[model];
  const webhookUrl = `${process.env.NEXT_PUBLIC_APP_URL}/api/webhooks/replicate?id=${generationId}`;

  console.log(`Generating image for generation ID: ${generationId} with model: ${model}`);
  const inputParams = modelSetup.getInputParams(userPrompt);
  await replicate.predictions.create({
    version: modelSetup.model,
    input: inputParams,
    webhook: webhookUrl,
    webhook_events_filter: ['completed'], // Only call webhook when done
  });
}

export function pickModelRandomly(models: ImageModelsEnum[]): ImageModelsEnum {
  return models[Math.floor(Math.random() * models.length)]!;
}
