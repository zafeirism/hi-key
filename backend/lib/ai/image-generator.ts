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

  const maxRetries = 2;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      console.log(
        `${new Date().toISOString()} #${attempt + 1} Posting generation: ${generationId}, model: ${model}`
      );
      await replicate.predictions.create({
        version: modelSetup.model,
        input: inputParams,
        webhook: webhookUrl,
        webhook_events_filter: ['completed'],
      });
      console.log(`${new Date().toISOString()} Posted generation: ${generationId}`);
      return;
    } catch (error) {
      if (attempt === maxRetries || !is429error(error)) {
        throw error;
      }
      console.warn(
        `${new Date().toISOString()} Rate limited (429) for generation: ${generationId}. Will retry.`
      );
      await waitSeconds(getRetryDelay(error));
    }
  }
}

function is429error(error: any): boolean {
  return (
    !!error &&
    typeof error === 'object' &&
    'response' in error &&
    error.response &&
    typeof error.response === 'object' &&
    'status' in error.response &&
    error.response.status === 429
  );
}

function getRetryDelay(error: any): number {
  const response = (error as { response: { headers?: { get?: (key: string) => string | null } } })
    .response;
  const retryAfterHeader = response.headers?.get?.('retry-after');
  const retryAfterSeconds = retryAfterHeader ? parseInt(retryAfterHeader, 10) : 5;
  return retryAfterSeconds;
}

function waitSeconds(seconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
}
