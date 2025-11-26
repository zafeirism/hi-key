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

  const inputParams = modelSetup.getInputParams(userPrompt);
  console.log(`${new Date().toISOString()} Posting generation: ${generationId}, model: ${model}`);
  await replicate.predictions.create({
    version: modelSetup.model,
    input: inputParams,
    webhook: webhookUrl,
    webhook_events_filter: ['completed'],
  });
  console.log(`${new Date().toISOString()} Posted generation: ${generationId}`);
}

export function pickModelRandomly(models: ImageModelsEnum[]): ImageModelsEnum {
  return models[Math.floor(Math.random() * models.length)]!;
}
