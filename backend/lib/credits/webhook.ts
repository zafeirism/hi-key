import { lookupProduct } from './catalog';
import { grant, resetSub, getBalance, type Balance } from './balance';

/**
 * Minimal subset of the RC webhook event we care about.
 * Full schema: https://www.revenuecat.com/docs/integrations/webhooks
 */
export type RevenueCatEvent = {
  type: string;
  app_user_id?: string;
  original_app_user_id?: string;
  product_id?: string;
  id: string;
  original_transaction_id?: string;
};

export type EventOutcome =
  | { handled: true; balance: Balance; summary: string }
  | { handled: false; summary: string };

export async function handleRevenueCatEvent(event: RevenueCatEvent): Promise<EventOutcome> {
  const userId = event.app_user_id ?? event.original_app_user_id;
  if (!userId) {
    return { handled: false, summary: `missing app_user_id (type=${event.type})` };
  }

  const product = lookupProduct(event.product_id);

  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'NON_RENEWING_PURCHASE': {
      if (!product) {
        return { handled: false, summary: `unknown product_id=${event.product_id}` };
      }
      if (product.kind === 'sub') {
        const balance = await grant(userId, {
          deltaSubMills: product.tierMaxMills,
          deltaExtraMills: 0,
          reason: 'initial_purchase',
          sourceId: event.id,
        });
        return { handled: true, balance, summary: `initial_purchase sub +${product.tierMaxMills}` };
      }
      const balance = await grant(userId, {
        deltaSubMills: 0,
        deltaExtraMills: product.amountMills,
        reason: 'pack',
        sourceId: event.id,
      });
      return { handled: true, balance, summary: `pack +${product.amountMills}` };
    }

    case 'RENEWAL': {
      if (!product || product.kind !== 'sub') {
        return { handled: false, summary: `renewal for non-sub product=${event.product_id}` };
      }
      const balance = await resetSub(userId, product.tierMaxMills, {
        reason: 'renewal',
        sourceId: event.id,
      });
      return { handled: true, balance, summary: `renewal sub=${product.tierMaxMills}` };
    }

    case 'EXPIRATION': {
      const balance = await resetSub(userId, 0, {
        reason: 'expiration_reset',
        sourceId: event.id,
      });
      return { handled: true, balance, summary: 'expiration sub=0' };
    }

    case 'REFUND': {
      if (!product) {
        // Log-only refund (unknown product) — record nothing, return current state.
        const balance = await getBalance(userId);
        return { handled: true, balance, summary: `refund ignored (unknown product)` };
      }
      if (product.kind === 'sub') {
        const balance = await getBalance(userId);
        return { handled: true, balance, summary: `refund sub (no clawback policy)` };
      }
      // Pack refund: claw back up to the pack size from remaining extra_credits.
      const current = await getBalance(userId);
      const clawback = Math.min(product.amountMills, current.extra_credits_mills);
      const balance = await grant(userId, {
        deltaSubMills: 0,
        deltaExtraMills: -clawback,
        reason: 'refund',
        sourceId: event.id,
      });
      return { handled: true, balance, summary: `refund pack -${clawback}` };
    }

    case 'CANCELLATION': {
      const balance = await getBalance(userId);
      return { handled: true, balance, summary: 'cancellation (no balance change)' };
    }

    default:
      return { handled: false, summary: `unhandled event type=${event.type}` };
  }
}
