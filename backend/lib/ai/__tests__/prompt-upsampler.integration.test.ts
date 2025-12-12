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

  it('should upsample a simple prompt with multiple prompts', async () => {
    const result = await upsamplePrompt('cat in space', 3);
    const resultText =
      result.improved_prompt +
      '||' +
      result.additional_prompts.join('|') +
      '|||' +
      result.user_phrases.join('|');

    expect(result.additional_prompts.length).toBe(2);
    expect(new Set(result.additional_prompts.concat(result.improved_prompt)).size).toBe(3);
    result.additional_prompts.forEach((prompt) => {
      expect(prompt).toBeTruthy();
      expect(prompt.length > 20, resultText).toBe(true);
    });
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

  it('should extract text from prompt and include it all improved prompts', async () => {
    const result = await upsamplePrompt('sign that says "HELLO WORLD"', 2);
    const resultText =
      result.improved_prompt +
      '||' +
      result.additional_prompts.join('|') +
      '|||' +
      result.user_phrases.join('|');

    expect(result.additional_prompts.length).toBe(1);
    result.additional_prompts.forEach((prompt) => {
      expect(prompt).toBeTruthy();
      expect(prompt.includes('HELLO WORLD'), resultText).toBe(true);
    });
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

  it('should handle complext user_phrases in all improved prompts', async () => {
    const result = await upsamplePrompt(
      'sunset over mountains with a banner made of clouds that says "HELLO WORLD" and a cat sitting on a cloud with a speech bubble that says "Καληνύχτα Σμπ1"',
      3
    );
    const resultText =
      result.improved_prompt +
      '||' +
      result.additional_prompts.join('|') +
      '|||' +
      result.user_phrases.join('|');

    expect(result.additional_prompts.length).toBe(2);
    result.additional_prompts.forEach((prompt) => {
      expect(prompt).toBeTruthy();
      expect(prompt.includes('HELLO WORLD'), resultText).toBe(true);
      expect(prompt.includes('Καληνύχτα Σμπ1'), resultText).toBe(true);
    });
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

  it("should keep user's intent in all improved prompts", async () => {
    const result = await upsamplePrompt(
      'A bookstore at night, Studio Ghibli style; a black cat sits by the window. A neon sign above the door says "Open Late. Stories Never Sleep."',
      4
    );
    const resultText =
      result.improved_prompt +
      '||' +
      result.additional_prompts.join('|') +
      '|||' +
      result.user_phrases.join('|');

    expect(result.additional_prompts.length).toBe(3);
    result.additional_prompts.forEach((prompt) => {
      expect(prompt).toBeTruthy();
      expect(prompt.toLowerCase().includes('bookstore'), resultText).toBe(true);
      expect(prompt.toLowerCase().includes('ghibli'), resultText).toBe(true);
      expect(prompt.toLowerCase().includes('cat'), resultText).toBe(true);
      expect(prompt.toLowerCase().includes('window'), resultText).toBe(true);
      expect(prompt.toLowerCase().includes('neon'), resultText).toBe(true);
      expect(prompt.includes('Open Late. Stories Never Sleep.'), resultText).toBe(true);
    });
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

  it('should be in English in all improved prompts', async () => {
    const result = await upsamplePrompt(
      'Ένα ζεστό, φιλόξενο βιβλιοπωλείο τη νύτα σε υδατογραφία, φωτιζόμενο θερμά από μέσα. Μία μαύρη γάτα κάθεται στο παράθυρο. Μία χειρόγραφη νέον ταμπέλα πάνω από την πόρτα γράφει "Οι ιστορίες δεν κοιμούνται ποτέ."',
      3
    );
    const resultText =
      result.improved_prompt +
      '||' +
      result.additional_prompts.join('|') +
      '|||' +
      result.user_phrases.join('|');

    expect(result.additional_prompts.length).toBe(2);
    result.additional_prompts.forEach((prompt) => {
      expect(prompt).toBeTruthy();
      expect(prompt.toLowerCase().includes('bookstore'), resultText).toBe(true);
      expect(prompt.toLowerCase().includes('watercolor'), resultText).toBe(true);
      expect(prompt.toLowerCase().includes('cat'), resultText).toBe(true);
      expect(prompt.toLowerCase().includes('window'), resultText).toBe(true);
      expect(prompt.toLowerCase().includes('neon'), resultText).toBe(true);
      expect(prompt.includes('Οι ιστορίες δεν κοιμούνται ποτέ.'), resultText).toBe(true);
    });
  }, 5000);

  it('should complete within reasonable time', async () => {
    const measurements: number[] = [];
    const prompts = [
      'A man',
      'A three-year-old girl',
      'A living room',
      'A colleague says hi',
      'A white car',
      'duck walking in a circle',
      'dog chasing a ball',
      'fish swimming in a fountain',
      'squirell riding a unicorn',
      'hog riding a horse',
      'A big dragon floting over towns while fires bursting all wrong, gilbi style',
      'Robot tryes fixing itself with tools that dont even working proper (like cinema image)',
      'The knight running fastly though forest but nothing looking quite right',
      'Anime, a magic portal opens badly and sucking everything in weird ways',
      'Girl like cartoon, dropping her lantern while creatures watchs from bushes very closly',
      'A cat wearing small armor pieces tries chasing giant beetle across temple ruins, but stones crumbling under them and dust flying everywhere and its making hard for either of them to run straight, plus weird chanting coming from tunnels makin situation feel much more stranger then usual, as retro poster',
      'The airship crew was shouting orders badly coordinated while ship tilts sideways from heavy winds not supposed to be there, and tools falling off shelves hitting floor loud, and map keeps sliding off table cause nothing staying still long enough for them to understand where they even are',
      'Two kids exploring an abandoned fairgrounds but rides keep moving even though power gone years ago, and sounds echo weirdly like they coming from wrong directions, making both confused, and cotton candy machines suddenly spinning for no reason which scare them more as they try figuring what happening',
      'A mage tries summoning creature from old book but words printed crookedly and candles melting too fast, dripping wax onto circle lines messing everything up, while wind blow indoors for some reason, causing pages flapping arounds and spell going wrong almost immediately but he still keeps trying anyway',
      'On a beach where sun barely rising cause clouds blocking light strange (as a retro poster), a traveler searching for lost relic but waves crashing unpredictably and sand shifting underfoot like alive, plus birds circling above making loud screech noises that throw him off, creating scene thats messy and confusing overall',
    ];

    for (const prompt of prompts) {
      const startTime = Date.now();
      await upsamplePrompt(prompt);
      const duration = Date.now() - startTime;
      console.log(`Duration: ${duration}ms`);
      measurements.push(duration);
    }

    const avgTime = measurements.reduce((a, b) => a + b, 0) / measurements.length;
    const medianTime = measurements.sort((a, b) => a - b)[Math.floor(measurements.length / 2)];
    console.log(`Average time: ${avgTime.toFixed(2)}ms`);
    console.log(`Median time: ${medianTime!.toFixed(2)}ms`);
    console.log(`Min: ${Math.min(...measurements).toFixed(2)}ms`);
    console.log(`Max: ${Math.max(...measurements).toFixed(2)}ms`);

    expect(avgTime).toBeLessThan(3000); // Average should be under 3 seconds
  }, 60000); // Longer timeout for multiple runs

  it('should run same as fast even with additional prompts', async () => {
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
      await upsamplePrompt(prompt, 3);
      const duration = Date.now() - startTime;
      measurements.push(duration);
    }

    const avgTime = measurements.reduce((a, b) => a + b, 0) / measurements.length;
    console.log(`Average time+ (with additional prompts): ${avgTime.toFixed(2)}ms`);
    console.log(`Min+: ${Math.min(...measurements).toFixed(2)}ms`);
    console.log(`Max+: ${Math.max(...measurements).toFixed(2)}ms`);

    expect(avgTime).toBeLessThan(3000); // Average should be under 3 seconds
  }, 20000); // Longer timeout for multiple runs
});
