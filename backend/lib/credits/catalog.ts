/**
 * Product ID → credit amount. Single source of truth for webhook grants.
 * 1 credit = 10 mills = 1 cent of underlying AI cost.
 */

export type SubProduct = { kind: 'sub'; tierMaxMills: number; trialMills?: number };
export type PackProduct = { kind: 'pack'; amountMills: number };
export type ProductEntry = SubProduct | PackProduct;

export const CREDIT_CATALOG: Record<string, ProductEntry> = {
  'starter.weekly': { kind: 'sub', tierMaxMills: 1000 },
  'plus.weekly': { kind: 'sub', tierMaxMills: 2000 },
  'super.weekly': { kind: 'sub', tierMaxMills: 3000, trialMills: 2000 },
  'pack.mini': { kind: 'pack', amountMills: 500 },
  'pack.mega': { kind: 'pack', amountMills: 3000 },
};

export function lookupProduct(productId: string | undefined | null): ProductEntry | null {
  if (!productId) return null;
  return CREDIT_CATALOG[productId] ?? null;
}
