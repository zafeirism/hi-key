import { randomBytes } from 'node:crypto';

const CROCKFORD_ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const CLAIM_CODE_PREFIX = 'HI';
const CLAIM_CODE_SUFFIX_LENGTH = 8;

export const CLAIM_CODE_REGEX = new RegExp(
  `^${CLAIM_CODE_PREFIX}-[${CROCKFORD_ALPHABET}]{${CLAIM_CODE_SUFFIX_LENGTH}}$`
);

export function normalizeClaimCodeInput(raw: string): string {
  return raw.trim().toUpperCase();
}

export function generateClaimCode(): string {
  const bytes = randomBytes(CLAIM_CODE_SUFFIX_LENGTH);
  let suffix = '';
  for (let i = 0; i < CLAIM_CODE_SUFFIX_LENGTH; i++) {
    suffix += CROCKFORD_ALPHABET[bytes[i]! % 32];
  }
  return `${CLAIM_CODE_PREFIX}-${suffix}`;
}
