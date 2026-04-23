import { randomBytes } from 'node:crypto';

const CROCKFORD_ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const NAME_MAX_LENGTH = 6;
const SUFFIX_LENGTH = 6;

export const REFERRAL_CODE_REGEX = new RegExp(
  `^[A-Z]{1,${NAME_MAX_LENGTH}}-[${CROCKFORD_ALPHABET}]{${SUFFIX_LENGTH}}$`
);

export function sanitizeName(raw: string): string | null {
  const folded = raw.normalize('NFKD').replace(/[^A-Za-z]/g, '');
  if (folded.length === 0) return null;
  return folded.slice(0, NAME_MAX_LENGTH).toUpperCase();
}

export function generateSuffix(): string {
  const bytes = randomBytes(SUFFIX_LENGTH);
  let out = '';
  for (let i = 0; i < SUFFIX_LENGTH; i++) {
    out += CROCKFORD_ALPHABET[bytes[i]! % 32];
  }
  return out;
}

export function buildReferralCode(name: string): string {
  return `${name}-${generateSuffix()}`;
}

export function normalizeCodeInput(raw: string): string {
  return raw.trim().toUpperCase();
}
