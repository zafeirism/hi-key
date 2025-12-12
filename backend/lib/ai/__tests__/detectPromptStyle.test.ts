import { describe, it, expect } from 'vitest';
import { hasStyle } from '../detectPromptStyle';

const shouldRunTests = !!process.env.OPENAI_API_KEY;

const testCases = [
  {
    prompt: 'A big dragon floting over towns while fires bursting all wrong. gilbi style',
    hasStyle: true,
  },
  {
    prompt:
      'Robot tryes fixing itself with tools that dont even working proper (like cinema image).',
    hasStyle: true,
  },
  {
    prompt: 'The knight running fastly though forest but nothing looking quite right.',
    hasStyle: false,
  },
  {
    prompt: 'Anime, a magic portal opens badly and sucking everything in weird ways.',
    hasStyle: true,
  },
  {
    prompt:
      'Girl like cartoon, dropping her lantern while creatures watchs from bushes very closly.',
    hasStyle: true,
  },
  {
    prompt:
      'Airship wobling hard cause engines not running like they supposed, like a painting from 1600',
    hasStyle: true,
  },
  {
    prompt:
      'Strange shadows follows traveler across desert making steps feel real unstable, as impressionist artist',
    hasStyle: true,
  },
  {
    prompt: 'Cat wearing armor bits chases beetle but keeps tripping constantly.',
    hasStyle: false,
  },
  {
    prompt: 'Noir, scientist mixxing liquids that explodes sudenly without any clear reason given.',
    hasStyle: true,
  },
  {
    prompt:
      'A graffiti, old wizard shouting spell words wrong causing lights flashing everywhere chaotically.',
    hasStyle: true,
  },
  {
    prompt:
      'A big knight standed in front the castle gates while dragons flying all arounds him, and he holding some sorta glowing sword that dont seems working right, with villagers shouting things in background but nothing making much sense cause the scene too chaotic happening all at once.',
    hasStyle: false,
  },
  {
    prompt:
      'Tha old robot was tryin fix itself using broken tools laying around the dusty room, but wires are sparking everywhere and the floor wobblin like it gonna collapse soon, while strange shadows moving behind the walls making everything feel more confusing then it should probably be normally.',
    hasStyle: false,
  },
  {
    prompt:
      'In the deep forrest where fog always coming in too thickly, a young explorer girl tripped over roots and fall into glowing pond that dont look natural, and creatures are watching her from trees but they not deciding if help or scare her more, everything feeling odd.',
    hasStyle: false,
  },
  {
    prompt:
      'Cyberpunk: A huge city full of lights flickering wrong becaus power lines messed up again, and people runnings around trying find shelter from storm clouds that forming inside streets instead of sky, creating weird reflections everywhere which makes whole place feels like not real, almost dreamlike but kinda broken.',
    hasStyle: true,
  },
  {
    prompt:
      'There was a scientist guy mixing bottles that bubbling up way faster then should, and the whole lab shaking because some machine humming too loud, while notes scattered across desk with scribbles nobody can reads, and smoke coming out vents signaling something very not good happening soon. Comic book style',
    hasStyle: true,
  },
  {
    prompt:
      'A cat wearing small armor pieces tries chasing giant beetle across temple ruins, but stones crumbling under them and dust flying everywhere and its making hard for either of them to run straight, plus weird chanting coming from tunnels makin situation feel much more stranger then usual, as retro poster',
    hasStyle: true,
  },
  {
    prompt:
      'The airship crew was shouting orders badly coordinated while ship tilts sideways from heavy winds not supposed to be there, and tools falling off shelves hitting floor loud, and map keeps sliding off table cause nothing staying still long enough for them to understand where they even are.',
    hasStyle: false,
  },
  {
    prompt:
      'Two kids exploring an abandoned fairgrounds but rides keep moving even though power gone years ago, and sounds echo weirdly like they coming from wrong directions, making both confused, and cotton candy machines suddenly spinning for no reason which scare them more as they try figuring what happening.',
    hasStyle: false,
  },
  {
    prompt:
      'A mage tries summoning creature from old book but words printed crookedly and candles melting too fast, dripping wax onto circle lines messing everything up, while wind blow indoors for some reason, causing pages flapping arounds and spell going wrong almost immediately but he still keeps trying anyway.',
    hasStyle: false,
  },
  {
    prompt:
      'On a beach where sun barely rising cause clouds blocking light strange (as a retro poster), a traveler searching for lost relic but waves crashing unpredictably and sand shifting underfoot like alive, plus birds circling above making loud screech noises that throw him off, creating scene thats messy and confusing overall.',
    hasStyle: true,
  },
];

describe.skipIf(!shouldRunTests)('Detect Prompt Style tests', () => {
  it('should detect style correctly', async () => {
    for (const testCase of testCases) {
      const r = await hasStyle(testCase.prompt);
      expect(r.has_style, testCase.prompt).toBe(testCase.hasStyle);
    }
  }, 30000);

  it('should run in under 1.5 seconds', async () => {
    const measurements: number[] = [];

    for (const { prompt } of testCases) {
      const startTime = Date.now();
      const r = await hasStyle(prompt);
      const duration = Date.now() - startTime;
      console.log(`\n${prompt} \n${r.has_style} \nDuration: ${duration}ms\n`);
      measurements.push(duration);
    }

    const avgTime = measurements.reduce((a, b) => a + b, 0) / measurements.length;
    const medianTime = measurements.sort((a, b) => a - b)[Math.floor(measurements.length / 2)];
    console.log(`Average time: ${avgTime.toFixed(2)}ms`);
    console.log(`Median time: ${medianTime!.toFixed(2)}ms`);
    console.log(`Min: ${Math.min(...measurements).toFixed(2)}ms`);
    console.log(`Max: ${Math.max(...measurements).toFixed(2)}ms`);

    expect(medianTime).toBeLessThan(1500);
  }, 30000);
});
