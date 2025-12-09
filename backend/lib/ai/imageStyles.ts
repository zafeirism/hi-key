export const IMAGE_STYLES = [
  'Watercolor',
  'Oil painting',
  'Pastel',
  'Charcoal',
  'Comic book',
  'Manga',
  'Graphic novel',
  'Pixar-like',
  'Ghibli-like',
  'Disney Renaissance',
  '90s anime',
  'Impressionist',
  'Surrealist',
  'Expressionist',
  'Pop art',
  'Vaporwave',
  'Synthwave',
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
  '3D render',
  'Realism',
  'Hyperrealism',
  'Baroque',
  'Rococo',
  'Art Nouveau',
  'Art Deco',
  'Cubism',
  'Fauvism',
  'Ukiyo-e',
  'Noir',
  'Film noir',
  'Neon noir',
  'Fantasy illustration',
  'Matte painting',
  'Isometric',
  'Line art',
  'Chiaroscuro',
  'Graffiti',
  'Street art',
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
