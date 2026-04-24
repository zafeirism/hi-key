import { supabaseAdmin } from '@/lib/supabase/server';
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

async function readDoublingMultiplier(userId: string): Promise<number> {
  const { data, error } = await supabaseAdmin
    .from('user_profiles')
    .select('double_credits')
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw error;
  return data?.double_credits ? 2 : 1;
}

async function setActiveSubProduct(userId: string, productId: string | null): Promise<void> {
  const { error } = await supabaseAdmin
    .from('user_profiles')
    .upsert(
      {
        user_id: userId,
        active_sub_product_id: productId,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id' }
    );
  if (error) throw error;
}

export async function handleRevenueCatEvent(event: RevenueCatEvent): Promise<EventOutcome> {
  const userId = (event.app_user_id ?? event.original_app_user_id)?.toLowerCase();
  if (!userId) {
    return { handled: false, summary: `missing app_user_id (type=${event.type})` };
  }

  const product = lookupProduct(event.product_id);
  const multiplier = await readDoublingMultiplier(userId);

  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'NON_RENEWING_PURCHASE': {
      if (!product) {
        return { handled: false, summary: `unknown product_id=${event.product_id}` };
      }
      if (product.kind === 'sub') {
        const subMills = product.tierMaxMills * multiplier;
        const balance = await grant(userId, {
          deltaSubMills: subMills,
          deltaExtraMills: 0,
          reason: 'initial_purchase',
          sourceId: event.id,
        });
        await setActiveSubProduct(userId, event.product_id ?? null);
        return {
          handled: true,
          balance,
          summary: `initial_purchase sub +${subMills}${multiplier > 1 ? ' (x2)' : ''}`,
        };
      }
      const packMills = product.amountMills * multiplier;
      const balance = await grant(userId, {
        deltaSubMills: 0,
        deltaExtraMills: packMills,
        reason: 'pack',
        sourceId: event.id,
      });
      return {
        handled: true,
        balance,
        summary: `pack +${packMills}${multiplier > 1 ? ' (x2)' : ''}`,
      };
    }

    case 'RENEWAL': {
      if (!product || product.kind !== 'sub') {
        return { handled: false, summary: `renewal for non-sub product=${event.product_id}` };
      }
      const subMills = product.tierMaxMills * multiplier;
      const balance = await resetSub(userId, subMills, {
        reason: 'renewal',
        sourceId: event.id,
      });
      await setActiveSubProduct(userId, event.product_id ?? null);
      return {
        handled: true,
        balance,
        summary: `renewal sub=${subMills}${multiplier > 1 ? ' (x2)' : ''}`,
      };
    }

    case 'EXPIRATION': {
      const balance = await resetSub(userId, 0, {
        reason: 'expiration_reset',
        sourceId: event.id,
      });
      await setActiveSubProduct(userId, null);
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
      // Pack refund: claw back up to the granted amount from remaining extra_credits.
      // For doubled users the original grant was 2x, so claw back 2x too.
      const current = await getBalance(userId);
      const grantedMills = product.amountMills * multiplier;
      const clawback = Math.min(grantedMills, current.extra_credits_mills);
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
