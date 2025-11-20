import { describe, it, expect, beforeAll } from 'vitest';
import { upsamplePrompt } from '../prompt-upsampler';

const shouldRunTests = !!process.env.OPENAI_API_KEY;

describe.skipIf(!shouldRunTests)('Prompt Upsampler', () => {
  beforeAll(async () => {
    console.log('Warming up Prompt Upsampler tests...');
    await upsamplePrompt('hakuna matata');
  });

  it('should upsample a simple prompt', async () => {
    const result = await upsamplePrompt('cat in space');
    const resultText = result.improved_prompt + '||' + result.user_phrases.join('|');

    expect(result.improved_prompt).toBeTruthy();
    expect(result.improved_prompt.length > 40, resultText).toBe(true);

    expect(Array.isArray(result.user_phrases)).toBe(true);
    expect(result.user_phrases.length, resultText).toBe(0);
  }, 5000);

  it('should extract text from prompt and include it in the improved prompts', async () => {
    const result = await upsamplePrompt('sign that says "HELLO WORLD"');
    const p = result.improved_prompt;
    const resultText = p + '||' + result.user_phrases.join('|');

    expect(p).toBeTruthy();
    expect(p.includes('HELLO WORLD'), resultText).toBe(true);

    expect(Array.isArray(result.user_phrases)).toBe(true);
    expect(result.user_phrases.length).toBe(1);
    expect(result.user_phrases[0], resultText).toBe('HELLO WORLD');
  }, 5000);

  it('should handle complext user_phrases', async () => {
    const result = await upsamplePrompt(
      'sunset over mountains with a banner made of clouds that says "HELLO WORLD" and a cat sitting on a cloud with a speech bubble that says "Καληνύχτα Σμπ1"'
    );
    const p = result.improved_prompt;
    const resultText = p + '||' + result.user_phrases.join('|');

    expect(p).toBeTruthy();
    expect(p.includes('HELLO WORLD'), resultText).toBe(true);
    expect(p.includes('Καληνύχτα Σμπ1'), resultText).toBe(true);

    expect(Array.isArray(result.user_phrases)).toBe(true);
    expect(result.user_phrases.length).toBe(2);
    expect(result.user_phrases, resultText).toContain('HELLO WORLD');
    expect(result.user_phrases, resultText).toContain('Καληνύχτα Σμπ1');
  }, 5000);

  it("should keep user's intent", async () => {
    const result = await upsamplePrompt(
      'A bookstore at night, Studio Ghibli style; a black cat sits by the window. A neon sign above the door says "Open Late. Stories Never Sleep."'
    );
    const p = result.improved_prompt;
    const resultText = p + '||' + result.user_phrases.join('|');

    expect(p).toBeTruthy();
    expect(p.toLowerCase().includes('bookstore'), resultText).toBe(true);
    expect(p.toLowerCase().includes('ghibli'), resultText).toBe(true);
    expect(p.toLowerCase().includes('cat'), resultText).toBe(true);
    expect(p.toLowerCase().includes('window'), resultText).toBe(true);
    expect(p.toLowerCase().includes('neon'), resultText).toBe(true);
    expect(p.includes('Open Late. Stories Never Sleep.'), resultText).toBe(true);

    expect(Array.isArray(result.user_phrases)).toBe(true);
    expect(result.user_phrases.length).toBe(1);
    expect(result.user_phrases[0], resultText).toBe('Open Late. Stories Never Sleep.');
  }, 5000);

  it('should be in English', async () => {
    const result = await upsamplePrompt(
      'Ένα ζεστό, φιλόξενο βιβλιοπωλείο τη νύτα σε υδατογραφία, φωτιζόμενο θερμά από μέσα. Μία μαύρη γάτα κάθεται στο παράθυρο. Μία χειρόγραφη νέον ταμπέλα πάνω από την πόρτα γράφει "Οι ιστορίες δεν κοιμούνται ποτέ."'
    );
    const p = result.improved_prompt;
    const resultText = p + '||' + result.user_phrases.join('|');

    expect(p).toBeTruthy();
    expect(p.toLowerCase().includes('bookstore'), resultText).toBe(true);
    expect(p.toLowerCase().includes('watercolor'), resultText).toBe(true);
    expect(p.toLowerCase().includes('cat'), resultText).toBe(true);
    expect(p.toLowerCase().includes('window'), resultText).toBe(true);
    expect(p.toLowerCase().includes('neon'), resultText).toBe(true);
    expect(p.includes('Οι ιστορίες δεν κοιμούνται ποτέ.'), resultText).toBe(true);

    expect(Array.isArray(result.user_phrases)).toBe(true);
    expect(result.user_phrases.length).toBe(1);
    expect(result.user_phrases[0], resultText).toBe('Οι ιστορίες δεν κοιμούνται ποτέ.');
  }, 5000);

  it('should complete within reasonable time', async () => {
    const measurements: number[] = [];
    const prompts = [
      'duck walking in a circle',
      'dog chasing a ball',
      'fish swimming in a fountain',
      'squirell riding a unicorn',
      'hog riding a horse',
    ];

    for (const prompt of prompts) {
      const startTime = Date.now();
      await upsamplePrompt(prompt);
      const duration = Date.now() - startTime;
      measurements.push(duration);
    }

    const avgTime = measurements.reduce((a, b) => a + b, 0) / measurements.length;
    console.log(`Average time: ${avgTime.toFixed(2)}ms`);
    console.log(`Min: ${Math.min(...measurements).toFixed(2)}ms`);
    console.log(`Max: ${Math.max(...measurements).toFixed(2)}ms`);

    expect(avgTime).toBeLessThan(3000); // Average should be under 3 seconds
  }, 20000); // Longer timeout for multiple runs
});
