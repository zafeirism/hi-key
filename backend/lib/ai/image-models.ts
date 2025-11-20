/**
 * Configuration for all available image generation models
 * Each model can have different parameters and capabilities
 */

export interface ImageModel {
  id: string;
  model: string; // Full Replicate model identifier with version
  priority: number; // Higher = more likely to be selected
  avgDuration: number; // Estimated duration in ms
  costPerImage: number; // Cost in mills ($0.001)
  supportsText: boolean; // Can render text inside images
  outputFormat: 'jpg' | 'webp' | 'png';
}

export const IMAGE_MODELS: ImageModel[] = [
  {
    id: 'flux-schnell',
    model: 'black-forest-labs/flux-schnell:abc123...', // Replace with actual version
    priority: 3,
    avgDuration: 2000,
    costPerImage: 15,
    supportsText: true,
    outputFormat: 'webp',
  },
  {
    id: 'sdxl-lightning',
    model: 'bytedance/sdxl-lightning-4step:def456...', // Replace with actual version
    priority: 2,
    avgDuration: 2500,
    costPerImage: 12,
    supportsText: false,
    outputFormat: 'jpg',
  },
  // Easy to add more models here...
];

/**
 * Selects N models for parallel generation
 * TODO: Implement selection algorithm (random, weighted, round-robin, etc.)
 *
 * @param count - Number of models to select
 * @param requireText - If true, only select models that support text
 * @returns Array of selected models
 */
export function selectModels(count: number, requireText: boolean = false): ImageModel[] {
  let availableModels = IMAGE_MODELS;

  // Filter by text support if required
  if (requireText) {
    availableModels = availableModels.filter((m) => m.supportsText);
  }

  // Placeholder: just take first N models
  // TODO: Implement weighted random selection based on priority
  return availableModels.slice(0, Math.min(count, availableModels.length));
}

/**
 * Gets a model by ID
 */
export function getModelById(id: string): ImageModel | undefined {
  return IMAGE_MODELS.find((m) => m.id === id);
}
