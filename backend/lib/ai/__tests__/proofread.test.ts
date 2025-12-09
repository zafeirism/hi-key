import { describe, it, expect } from 'vitest';
import { proofread } from '../proofread';

const shouldRunTests = !!process.env.OPENAI_API_KEY;

describe.skipIf(!shouldRunTests)('Proofreading tests', () => {
  it('should run in under 1.5 seconds', async () => {
    const measurements: number[] = [];
    const prompts = [
      'A big dragon floting over towns while fires bursting all wrong. gilbi style',
      'Robot tryes fixing itself with tools that dont even working proper (like cinema image).',
      'The knight running fastly though forest but nothing looking quite right.',
      'A magic portal opens badly and sucking everything in weird ways.',
      'Girl dropping her lantern while creatures watchs from bushes very closly.',
      'Airship wobling hard cause engines not running like they supposed.',
      'Strange shadows follows traveler across desert making steps feel real unstable.',
      'Cat wearing armor bits chases beetle but keeps tripping constantly.',
      'Scientist mixxing liquids that explodes sudenly without any clear reason given.',
      'Old wizard shouting spell words wrong causing lights flashing everywhere chaotically.',
      'A big knight standed in front the castle gates while dragons flying all arounds him, and he holding some sorta glowing sword that dont seems working right, with villagers shouting things in background but nothing making much sense cause the scene too chaotic happening all at once.',
      'Tha old robot was tryin fix itself using broken tools laying around the dusty room, but wires are sparking everywhere and the floor wobblin like it gonna collapse soon, while strange shadows moving behind the walls making everything feel more confusing then it should probably be normally.',
      'In the deep forrest where fog always coming in too thickly, a young explorer girl tripped over roots and fall into glowing pond that dont look natural, and creatures are watching her from trees but they not deciding if help or scare her more, everything feeling odd.',
      'A huge city full of lights flickering wrong becaus power lines messed up again, and people runnings around trying find shelter from storm clouds that forming inside streets instead of sky, creating weird reflections everywhere which makes whole place feels like not real, almost dreamlike but kinda broken.',
      'There was a scientist guy mixing bottles that bubbling up way faster then should, and the whole lab shaking because some machine humming too loud, while notes scattered across desk with scribbles nobody can reads, and smoke coming out vents signaling something very not good happening soon.',
      'A cat wearing small armor pieces tries chasing giant beetle across temple ruins, but stones crumbling under them and dust flying everywhere and its making hard for either of them to run straight, plus weird chanting coming from tunnels makin situation feel much more stranger then usual.',
      'The airship crew was shouting orders badly coordinated while ship tilts sideways from heavy winds not supposed to be there, and tools falling off shelves hitting floor loud, and map keeps sliding off table cause nothing staying still long enough for them to understand where they even are.',
      'Two kids exploring an abandoned fairgrounds but rides keep moving even though power gone years ago, and sounds echo weirdly like they coming from wrong directions, making both confused, and cotton candy machines suddenly spinning for no reason which scare them more as they try figuring what happening.',
      'A mage tries summoning creature from old book but words printed crookedly and candles melting too fast, dripping wax onto circle lines messing everything up, while wind blow indoors for some reason, causing pages flapping arounds and spell going wrong almost immediately but he still keeps trying anyway.',
      'On a beach where sun barely rising cause clouds blocking light strange, a traveler searching for lost relic but waves crashing unpredictably and sand shifting underfoot like alive, plus birds circling above making loud screech noises that throw him off, creating scene thats messy and confusing overall.',
    ];

    for (const prompt of prompts) {
      const startTime = Date.now();
      const r = await proofread(prompt);
      const duration = Date.now() - startTime;
      console.log(`\n${prompt} \n${r.improved_prompt} \nDuration: ${duration}ms\n`);
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
