import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Balance } from '../balance';

const grantMock = vi.fn();
const resetSubMock = vi.fn();
const getBalanceMock = vi.fn();

vi.mock('../balance', () => ({
  grant: (...args: unknown[]) => grantMock(...args),
  resetSub: (...args: unknown[]) => resetSubMock(...args),
  getBalance: (...args: unknown[]) => getBalanceMock(...args),
}));

import { handleRevenueCatEvent } from '../webhook';

const USER_ID = 'user-abc';
const EVENT_ID = 'evt-123';

const emptyBalance: Balance = { sub_credits_mills: 0, extra_credits_mills: 0 };

beforeEach(() => {
  grantMock.mockReset();
  resetSubMock.mockReset();
  getBalanceMock.mockReset();
});

describe('handleRevenueCatEvent', () => {
  it('returns unhandled when app_user_id is missing', async () => {
    const out = await handleRevenueCatEvent({ id: EVENT_ID, type: 'INITIAL_PURCHASE' });
    expect(out.handled).toBe(false);
    expect(grantMock).not.toHaveBeenCalled();
  });

  it('falls back to original_app_user_id when app_user_id is absent', async () => {
    grantMock.mockResolvedValue({ sub_credits_mills: 1000, extra_credits_mills: 0 });
    await handleRevenueCatEvent({
      id: EVENT_ID,
      type: 'INITIAL_PURCHASE',
      original_app_user_id: USER_ID,
      product_id: 'starter.weekly',
    });
    expect(grantMock).toHaveBeenCalledWith(
      USER_ID,
      expect.objectContaining({ deltaSubMills: 1000 })
    );
  });

  describe('INITIAL_PURCHASE', () => {
    it('grants sub credits for a sub product', async () => {
      grantMock.mockResolvedValue({ sub_credits_mills: 3000, extra_credits_mills: 0 });
      const out = await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'INITIAL_PURCHASE',
        app_user_id: USER_ID,
        product_id: 'super.weekly',
      });
      expect(out.handled).toBe(true);
      expect(grantMock).toHaveBeenCalledWith(USER_ID, {
        deltaSubMills: 3000,
        deltaExtraMills: 0,
        reason: 'initial_purchase',
        sourceId: EVENT_ID,
      });
    });

    it('grants extra credits for a pack product', async () => {
      grantMock.mockResolvedValue({ sub_credits_mills: 0, extra_credits_mills: 500 });
      const out = await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'INITIAL_PURCHASE',
        app_user_id: USER_ID,
        product_id: 'pack.mini',
      });
      expect(out.handled).toBe(true);
      expect(grantMock).toHaveBeenCalledWith(USER_ID, {
        deltaSubMills: 0,
        deltaExtraMills: 500,
        reason: 'pack',
        sourceId: EVENT_ID,
      });
    });

    it('is unhandled when product_id is unknown', async () => {
      const out = await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'INITIAL_PURCHASE',
        app_user_id: USER_ID,
        product_id: 'mystery.product',
      });
      expect(out.handled).toBe(false);
      expect(grantMock).not.toHaveBeenCalled();
    });
  });

  describe('NON_RENEWING_PURCHASE', () => {
    it('grants extra credits like a pack purchase', async () => {
      grantMock.mockResolvedValue({ sub_credits_mills: 0, extra_credits_mills: 3000 });
      await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'NON_RENEWING_PURCHASE',
        app_user_id: USER_ID,
        product_id: 'pack.mega',
      });
      expect(grantMock).toHaveBeenCalledWith(USER_ID, {
        deltaSubMills: 0,
        deltaExtraMills: 3000,
        reason: 'pack',
        sourceId: EVENT_ID,
      });
    });
  });

  describe('RENEWAL', () => {
    it('resets sub credits to the tier max', async () => {
      resetSubMock.mockResolvedValue({ sub_credits_mills: 2000, extra_credits_mills: 0 });
      await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'RENEWAL',
        app_user_id: USER_ID,
        product_id: 'plus.weekly',
      });
      expect(resetSubMock).toHaveBeenCalledWith(USER_ID, 2000, {
        reason: 'renewal',
        sourceId: EVENT_ID,
      });
    });

    it('is unhandled for non-sub products', async () => {
      const out = await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'RENEWAL',
        app_user_id: USER_ID,
        product_id: 'pack.mini',
      });
      expect(out.handled).toBe(false);
      expect(resetSubMock).not.toHaveBeenCalled();
    });
  });

  describe('EXPIRATION', () => {
    it('resets sub credits to 0 regardless of product', async () => {
      resetSubMock.mockResolvedValue({ sub_credits_mills: 0, extra_credits_mills: 500 });
      await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'EXPIRATION',
        app_user_id: USER_ID,
        product_id: 'starter.weekly',
      });
      expect(resetSubMock).toHaveBeenCalledWith(USER_ID, 0, {
        reason: 'expiration_reset',
        sourceId: EVENT_ID,
      });
    });
  });

  describe('REFUND', () => {
    it('claws back up to pack size from extra credits', async () => {
      getBalanceMock.mockResolvedValue({ sub_credits_mills: 200, extra_credits_mills: 700 });
      grantMock.mockResolvedValue({ sub_credits_mills: 200, extra_credits_mills: 200 });
      await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'REFUND',
        app_user_id: USER_ID,
        product_id: 'pack.mini',
      });
      expect(grantMock).toHaveBeenCalledWith(USER_ID, {
        deltaSubMills: 0,
        deltaExtraMills: -500,
        reason: 'refund',
        sourceId: EVENT_ID,
      });
    });

    it('caps clawback at current extra balance', async () => {
      getBalanceMock.mockResolvedValue({ sub_credits_mills: 0, extra_credits_mills: 100 });
      grantMock.mockResolvedValue({ sub_credits_mills: 0, extra_credits_mills: 0 });
      await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'REFUND',
        app_user_id: USER_ID,
        product_id: 'pack.mega',
      });
      expect(grantMock).toHaveBeenCalledWith(USER_ID, {
        deltaSubMills: 0,
        deltaExtraMills: -100,
        reason: 'refund',
        sourceId: EVENT_ID,
      });
    });

    it('does not mutate balance for sub refunds', async () => {
      getBalanceMock.mockResolvedValue(emptyBalance);
      await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'REFUND',
        app_user_id: USER_ID,
        product_id: 'super.weekly',
      });
      expect(grantMock).not.toHaveBeenCalled();
      expect(resetSubMock).not.toHaveBeenCalled();
    });

    it('ignores unknown products but still returns handled', async () => {
      getBalanceMock.mockResolvedValue(emptyBalance);
      const out = await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'REFUND',
        app_user_id: USER_ID,
        product_id: 'mystery.product',
      });
      expect(out.handled).toBe(true);
      expect(grantMock).not.toHaveBeenCalled();
    });
  });

  describe('CANCELLATION', () => {
    it('does not mutate balance', async () => {
      getBalanceMock.mockResolvedValue({ sub_credits_mills: 1000, extra_credits_mills: 0 });
      const out = await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'CANCELLATION',
        app_user_id: USER_ID,
        product_id: 'starter.weekly',
      });
      expect(out.handled).toBe(true);
      expect(grantMock).not.toHaveBeenCalled();
      expect(resetSubMock).not.toHaveBeenCalled();
    });
  });

  describe('unhandled types', () => {
    it('returns unhandled for unknown event types', async () => {
      const out = await handleRevenueCatEvent({
        id: EVENT_ID,
        type: 'SOMETHING_NEW',
        app_user_id: USER_ID,
      });
      expect(out.handled).toBe(false);
      expect(grantMock).not.toHaveBeenCalled();
      expect(resetSubMock).not.toHaveBeenCalled();
    });
  });
});
