import { describe, it, expect } from 'vitest';
import {
  REFERRAL_CODE_REGEX,
  buildReferralCode,
  generateSuffix,
  normalizeCodeInput,
  sanitizeName,
} from '../code';

describe('sanitizeName', () => {
  it('uppercases and truncates to 6 chars', () => {
    expect(sanitizeName('jane')).toBe('JANE');
    expect(sanitizeName('alexandra')).toBe('ALEXAN');
  });

  it('strips non-letters and diacritics', () => {
    expect(sanitizeName('José')).toBe('JOSE');
    expect(sanitizeName('Jane-123')).toBe('JANE');
    expect(sanitizeName('Zoë Müller')).toBe('ZOEMUL');
  });

  it('returns null for empty / pure-non-ASCII / emoji input', () => {
    expect(sanitizeName('')).toBeNull();
    expect(sanitizeName('   ')).toBeNull();
    expect(sanitizeName('李')).toBeNull();
    expect(sanitizeName('🎉👋')).toBeNull();
  });
});

describe('generateSuffix', () => {
  it('produces 6 Crockford Base32 chars', () => {
    for (let i = 0; i < 100; i++) {
      const suffix = generateSuffix();
      expect(suffix).toMatch(/^[0-9A-HJKMNP-TV-Z]{6}$/);
      expect(suffix).not.toMatch(/[ILOU]/);
    }
  });
});

describe('buildReferralCode', () => {
  it('produces NAME-XXXXXX format that passes the regex', () => {
    const code = buildReferralCode('JANE');
    expect(code.startsWith('JANE-')).toBe(true);
    expect(REFERRAL_CODE_REGEX.test(code)).toBe(true);
  });
});

describe('normalizeCodeInput', () => {
  it('trims and uppercases', () => {
    expect(normalizeCodeInput(' jane-abcdef ')).toBe('JANE-ABCDEF');
  });
});
