import type { Tables, TablesInsert, TablesUpdate } from './types';

export type Generation = Tables<'generations'>;
export type GenerationInsert = TablesInsert<'generations'>;
export type GenerationUpdate = TablesUpdate<'generations'>;

export type GenerationStatus = 'initializing' | 'generating' | 'ready' | 'error';

export type WaitlistEntry = Tables<'waitlist'>;
export type WaitlistInsert = TablesInsert<'waitlist'>;

export type UserProfile = Tables<'user_profiles'>;
export type UserProfileInsert = TablesInsert<'user_profiles'>;

export type CreditTransaction = Tables<'credit_transactions'>;
export type CreditTransactionInsert = TablesInsert<'credit_transactions'>;

export type CreditReason =
  | 'initial_purchase'
  | 'renewal'
  | 'pack'
  | 'generation_debit'
  | 'generation_refund'
  | 'refund'
  | 'expiration_reset'
  | 'referral'
  | 'waitlist_claim';
