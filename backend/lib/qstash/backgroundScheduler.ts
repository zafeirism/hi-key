import { Client } from '@upstash/qstash';

const qstash = new Client({
  token: process.env.QSTASH_TOKEN!,
});

export async function continueOnBackground(generationIds: string[]) {
  console.log(`Will continue on background for generation IDs: ${generationIds}`);
  await qstash.publishJSON({
    url: `${process.env.NEXT_PUBLIC_APP_URL}/api/worker`,
    body: {
      generationIds,
    },
  });
}
