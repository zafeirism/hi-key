import { NextResponse } from 'next/server';
import { warmupQstash } from '@/lib/qstash/backgroundScheduler';
import { supabaseAdmin } from '@/lib/supabase/server';

export async function POST() {
  await warmupAutocomplete();
  await warmupGenerate();
  await warmupDatabase();
  await warmupWebhooks();
  await warmupRevenueCatWebhook();
  await warmupWorker();

  return NextResponse.json({ success: true });
}

async function warmupAutocomplete() {
  await fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/autocomplete`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ***REMOVED***`,
    },
    body: JSON.stringify({ warmup: true }),
  });
}

async function warmupGenerate() {
  await fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/generate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ***REMOVED***`,
    },
    body: JSON.stringify({ warmup: true }),
  });
}

async function warmupDatabase() {
  await supabaseAdmin.from('generations').select('*').limit(1);
}

async function warmupWebhooks() {
  await fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/webhooks/replicate?id=warmup`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
  });
}

async function warmupRevenueCatWebhook() {
  await fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/webhooks/revenuecat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ warmup: true }),
  });
}

async function warmupWorker() {
  await warmupQstash();
}
