import { supabaseAdmin } from '@/lib/supabase/server';
import { getProfile } from '@/lib/profile/profile';
import { lookupProduct, type SubProduct } from './catalog';
import { grant, resetSub, type Balance } from './balance';

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
  period_type?: 'TRIAL' | 'NORMAL' | 'INTRO' | 'PROMOTIONAL';
};

export type EventOutcome =
  | { handled: true; balance: Balance; summary: string }
  | { handled: false; summary: string };

async function readDoublingMultiplier(userId: string): Promise<number> {
  const profile = await getProfile(userId);
  return profile.double_credits ? 2 : 1;
}

async function readBalance(userId: string): Promise<Balance> {
  const profile = await getProfile(userId);
  return {
    sub_credits_mills: profile.sub_credits_mills,
    extra_credits_mills: profile.extra_credits_mills,
  };
}

function resolveSubGrant(
  product: SubProduct,
  event: RevenueCatEvent,
  multiplier: number
): { mills: number; isTrial: boolean } {
  const isTrial = event.period_type === 'TRIAL' && product.trialMills !== undefined;
  const baseMills = isTrial ? product.trialMills! : product.tierMaxMills;
  return { mills: baseMills * multiplier, isTrial };
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
        const { mills: subMills, isTrial } = resolveSubGrant(product, event, multiplier);
        const reason = isTrial ? 'trial_start' : 'initial_purchase';
        const balance = await grant(userId, {
          deltaSubMills: subMills,
          deltaExtraMills: 0,
          reason,
          sourceId: event.id,
        });
        await setActiveSubProduct(userId, event.product_id ?? null);
        return {
          handled: true,
          balance,
          summary: `${reason} sub +${subMills}${multiplier > 1 ? ' (x2)' : ''}`,
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
      const { mills: subMills, isTrial } = resolveSubGrant(product, event, multiplier);
      const reason = isTrial ? 'trial_start' : 'renewal';
      const balance = await resetSub(userId, subMills, {
        reason,
        sourceId: event.id,
      });
      await setActiveSubProduct(userId, event.product_id ?? null);
      return {
        handled: true,
        balance,
        summary: `${reason} sub=${subMills}${multiplier > 1 ? ' (x2)' : ''}`,
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
        const balance = await readBalance(userId);
        return { handled: true, balance, summary: `refund ignored (unknown product)` };
      }
      if (product.kind === 'sub') {
        const balance = await readBalance(userId);
        return { handled: true, balance, summary: `refund sub (no clawback policy)` };
      }
      // Pack refund: claw back up to the granted amount from remaining extra_credits.
      // For doubled users the original grant was 2x, so claw back 2x too.
      const current = await readBalance(userId);
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
      const balance = await readBalance(userId);
      return { handled: true, balance, summary: 'cancellation (no balance change)' };
    }

    default:
      return { handled: false, summary: `unhandled event type=${event.type}` };
  }
}
