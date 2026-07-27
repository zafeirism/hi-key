/**
 * Enum of all available image model setup IDs
 */
export enum ImageModelsEnum {
  FLUX_2_DEV = 'flux-2-dev',
  FLUX_2_PRO = 'flux-2-pro',
  FLUX_2_PRO_UPSAMPLED = 'flux-2-pro-upsampled',
  FLUX_2_KLEIN = 'flux-2-klein',
  NANO_BANANA_2_LITE = 'nano-banana-2-lite',
}

export function pickModelRandomly(models: ImageModelsEnum[]): ImageModelsEnum {
  return models[Math.floor(Math.random() * models.length)]!;
}

/**
 * A "setup" is a complete configuration for an image generation request
 * Can be different models OR same model with different parameters
 */
export interface ImageModelSetup {
  id: ImageModelsEnum;
  model: string;
  avgDuration: number;
  costPerImage: number;
  supportsText: boolean;
  outputFormat: 'jpg' | 'webp' | 'png';

  // Function that returns the input parameters for this specific setup
  getInputParams: (prompt: string) => Record<string, any>;
}

export const IMAGE_MODEL_SETUPS: Record<ImageModelsEnum, ImageModelSetup> = {
  [ImageModelsEnum.FLUX_2_DEV]: {
    id: ImageModelsEnum.FLUX_2_DEV,
    model: 'black-forest-labs/flux-2-dev',
    avgDuration: 3000,
    costPerImage: 12,
    supportsText: true,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
    }),
  },
  [ImageModelsEnum.FLUX_2_PRO]: {
    id: ImageModelsEnum.FLUX_2_PRO,
    model: 'black-forest-labs/flux-2-pro',
    avgDuration: 9000,
    costPerImage: 30,
    supportsText: true,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
    }),
  },
  [ImageModelsEnum.FLUX_2_PRO_UPSAMPLED]: {
    id: ImageModelsEnum.FLUX_2_PRO_UPSAMPLED,
    model: 'black-forest-labs/flux-2-pro',
    avgDuration: 9000,
    costPerImage: 30,
    supportsText: true,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
      prompt_upsampling: true,
    }),
  },
  [ImageModelsEnum.FLUX_2_KLEIN]: {
    id: ImageModelsEnum.FLUX_2_KLEIN,
    model: 'black-forest-labs/flux-2-klein-4b',
    avgDuration: 1000,
    costPerImage: 1,
    supportsText: false,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
    }),
  },
  [ImageModelsEnum.NANO_BANANA_2_LITE]: {
    id: ImageModelsEnum.NANO_BANANA_2_LITE,
    model: 'google/nano-banana-2-lite',
    avgDuration: 5000,
    costPerImage: 34,
    supportsText: true,
    outputFormat: 'jpg',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'jpg',
    }),
  },
};
