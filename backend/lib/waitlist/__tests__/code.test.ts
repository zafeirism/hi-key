import { describe, it, expect } from 'vitest';
import { CLAIM_CODE_REGEX, generateClaimCode, normalizeClaimCodeInput } from '../code';

describe('generateClaimCode', () => {
  it('produces HI-XXXXXXXX Crockford Base32 codes', () => {
    for (let i = 0; i < 100; i++) {
      const code = generateClaimCode();
      expect(code).toMatch(/^HI-[0-9A-HJKMNP-TV-Z]{8}$/);
      // Suffix only (prefix contains "I" by design).
      const suffix = code.slice(3);
      expect(suffix).not.toMatch(/[ILOU]/);
      expect(CLAIM_CODE_REGEX.test(code)).toBe(true);
    }
  });
});

describe('normalizeClaimCodeInput', () => {
  it('trims and uppercases', () => {
    expect(normalizeClaimCodeInput(' hi-abcd1234 ')).toBe('HI-ABCD1234');
  });
});

describe('CLAIM_CODE_REGEX', () => {
  it('accepts valid codes', () => {
    expect(CLAIM_CODE_REGEX.test('HI-ABCD1234')).toBe(true);
    expect(CLAIM_CODE_REGEX.test('HI-00000000')).toBe(true);
  });

  it('rejects wrong length, wrong prefix, or ambiguous chars', () => {
    expect(CLAIM_CODE_REGEX.test('HI-ABCD123')).toBe(false);
    expect(CLAIM_CODE_REGEX.test('HEY-ABCD1234')).toBe(false);
    expect(CLAIM_CODE_REGEX.test('HI-ABCDILOU')).toBe(false);
    expect(CLAIM_CODE_REGEX.test('hi-abcd1234')).toBe(false);
  });
});
