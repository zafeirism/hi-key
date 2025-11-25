/**
 * Enum of all available image model setup IDs
 */
export enum ImageModelsEnum {
  FLUX_SCHNELL = 'flux-schnell',
  FLUX_1_DEV = 'flux-1-dev',
  FLUX_1_1_PRO = 'flux-1.1-pro',
  FLUX_KREA_DEV = 'flux-krea-dev',
  FLUX_KONTEXT_MAX = 'flux-kontext-max',
  SD_3_5_LARGE_TURBO = 'sd-3.5-large-turbo',
  IMAGEN_4_FAST = 'imagen-4-fast',
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
  [ImageModelsEnum.FLUX_SCHNELL]: {
    id: ImageModelsEnum.FLUX_SCHNELL,
    model: 'black-forest-labs/flux-schnell',
    avgDuration: 1200,
    costPerImage: 3,
    supportsText: false,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
    }),
  },
  [ImageModelsEnum.FLUX_1_DEV]: {
    id: ImageModelsEnum.FLUX_1_DEV,
    model: 'black-forest-labs/flux-dev',
    avgDuration: 2000,
    costPerImage: 25,
    supportsText: false,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
    }),
  },
  [ImageModelsEnum.FLUX_1_1_PRO]: {
    id: ImageModelsEnum.FLUX_1_1_PRO,
    model: 'black-forest-labs/flux-1.1-pro',
    avgDuration: 3700,
    costPerImage: 40,
    supportsText: true,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
    }),
  },
  [ImageModelsEnum.FLUX_KREA_DEV]: {
    id: ImageModelsEnum.FLUX_KREA_DEV,
    model: 'black-forest-labs/flux-krea-dev',
    avgDuration: 8000,
    costPerImage: 25,
    supportsText: true,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
      guidance: 3,
    }),
  },
  [ImageModelsEnum.FLUX_KONTEXT_MAX]: {
    id: ImageModelsEnum.FLUX_KONTEXT_MAX,
    model: 'black-forest-labs/flux-kontext-max',
    avgDuration: 4000,
    costPerImage: 80,
    supportsText: true,
    outputFormat: 'jpg',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'jpg',
      aspect_ratio: '1:1',
    }),
  },
  [ImageModelsEnum.SD_3_5_LARGE_TURBO]: {
    id: ImageModelsEnum.SD_3_5_LARGE_TURBO,
    model: 'stability-ai/stable-diffusion-3.5-large-turbo',
    avgDuration: 3500,
    costPerImage: 40,
    supportsText: true,
    outputFormat: 'webp',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'webp',
    }),
  },
  [ImageModelsEnum.IMAGEN_4_FAST]: {
    id: ImageModelsEnum.IMAGEN_4_FAST,
    model: 'google/imagen-4-fast',
    avgDuration: 4200,
    costPerImage: 20,
    supportsText: true,
    outputFormat: 'jpg',
    getInputParams: (prompt: string) => ({
      prompt: prompt,
      output_format: 'jpg',
    }),
  },
};
