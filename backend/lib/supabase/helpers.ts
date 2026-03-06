import type { Tables, TablesInsert, TablesUpdate } from './types';

export type Generation = Tables<'generations'>;
export type GenerationInsert = TablesInsert<'generations'>;
export type GenerationUpdate = TablesUpdate<'generations'>;

export type GenerationStatus = 'initializing' | 'generating' | 'ready' | 'error';

export type WaitlistEntry = Tables<'waitlist'>;
export type WaitlistInsert = TablesInsert<'waitlist'>;
