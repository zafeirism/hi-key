import { Client } from '@upstash/qstash';

const qstash = new Client({
  token: process.env.QSTASH_TOKEN!,
});

export async function continueOnBackground(generationIds: string[]) {
  console.log(`${new Date().toISOString()} Posting to QStash for generation IDs: ${generationIds}`);
  await qstash.publishJSON({
    url: `${process.env.NEXT_PUBLIC_APP_URL}/api/worker`,
    body: {
      generationIds,
    },
  });
  console.log(`${new Date().toISOString()} Posted to QStash for generation IDs: ${generationIds}`);
}
