import { Client } from '@upstash/qstash';

const qstash = new Client({
  token: process.env.QSTASH_TOKEN!,
});

export async function continueOnBackground(generationIds: string[]) {
  await qstash.publishJSON({
    url: `${process.env.NEXT_PUBLIC_APP_URL}/api/worker`,
    body: {
      generationIds,
    },
  });
}

export async function warmupQstash() {
  await qstash.publishJSON({
    url: `${process.env.NEXT_PUBLIC_APP_URL}/api/worker`,
    body: {
      warmup: true,
    },
  });
}
