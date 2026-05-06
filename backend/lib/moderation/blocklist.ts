// First-line moderation: pure string/regex match, no async, no network.
// Catches the most clearly objectionable inputs so we can 403 before any DB write,
// debit, or downstream API call. Anything subtler is left to the OpenAI moderation API.
//
// Patterns are intentionally narrow to avoid false positives. Word boundaries
// (\b) are used so substrings inside larger words don't match (e.g. "child" in
// "childhood" is fine — only standalone or compound usages trip the filter).

export type BlocklistCategory = 'csam' | 'self_harm' | 'sexual_violence';

type BlocklistEntry = {
  category: BlocklistCategory;
  pattern: RegExp;
};

const MINOR = '(?:child|children|kid|kids|minor|minors|underage|preteen|toddler|infant|baby|babies|loli|shota)';
const SEXUAL =
  '(?:porn|pornographic|nude|naked|sex|sexual|sexy|erotic|nsfw|xxx|fucking|undressed)';

const ENTRIES: BlocklistEntry[] = [
  // CSAM — minor + sexual content in either order, plus a few unambiguous standalone tokens.
  { category: 'csam', pattern: new RegExp(`\\b${MINOR}\\b[^\\n]{0,40}?\\b${SEXUAL}\\b`, 'i') },
  { category: 'csam', pattern: new RegExp(`\\b${SEXUAL}\\b[^\\n]{0,40}?\\b${MINOR}\\b`, 'i') },
  { category: 'csam', pattern: /\b(child\s*porn|kiddie\s*porn|cp\s*(?:image|photo|pic|art))\b/i },
  { category: 'csam', pattern: /\b(loli|shota)(?:con)?\b/i },

  // Self-harm methods — explicit how-to / instructional phrasing only. Mentions of
  // suicide as a topic are left to the OpenAI moderator.
  { category: 'self_harm', pattern: /\b(how\s+to\s+(?:kill\s+myself|commit\s+suicide|hang\s+myself))\b/i },
  { category: 'self_harm', pattern: /\b(suicide\s+methods?|ways?\s+to\s+(?:kill\s+myself|die\s+painlessly))\b/i },

  // Real-world sexual violence depictions of identifiable victim types.
  { category: 'sexual_violence', pattern: new RegExp(`\\b(rape|raping|raped)\\b[^\\n]{0,40}?\\b${MINOR}\\b`, 'i') },
  { category: 'sexual_violence', pattern: new RegExp(`\\b${MINOR}\\b[^\\n]{0,40}?\\b(rape|raping|raped)\\b`, 'i') },
];

export type BlocklistMatch = {
  categories: BlocklistCategory[];
};

export function checkBlocklist(prompt: string): BlocklistMatch | null {
  const categories = new Set<BlocklistCategory>();
  for (const entry of ENTRIES) {
    if (entry.pattern.test(prompt)) {
      categories.add(entry.category);
    }
  }
  if (categories.size === 0) return null;
  return { categories: Array.from(categories) };
}
