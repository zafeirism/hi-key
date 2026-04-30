export const IMAGE_STYLES = [
  'Watercolor',
  'Oil painting',
  'Pastel',
  'Charcoal',
  'Comic book',
  'Manga',
  'Graphic novel',
  'Pixar style',
  'Ghibli style',
  'Disney style',
  'Anime',
  'Impressionist',
  'Surrealist',
  'Expressionist',
  'Pop art',
  'Cyberpunk',
  'Steampunk',
  'Photorealistic',
  'Cinematic',
  'Documentary',
  'Analog film',
  'Retro poster',
  'Minimalism',
  'Low poly',
  'Pixel art',
  'Sketch',
  'Baroque',
  'Cubism',
  'Noir style',
  'Fantasy illustration',
  'Isometric',
  'Line art',
  'Chiaroscuro',
  'Graffiti',
  'Stencil',
];

export function pickStylesRandomly(count: number): string[] {
  const result: string[] = [];
  while (result.length < count) {
    const style = IMAGE_STYLES[Math.floor(Math.random() * IMAGE_STYLES.length)]!;
    if (!result.includes(style)) {
      result.push(style);
    }
  }
  return result;
}
