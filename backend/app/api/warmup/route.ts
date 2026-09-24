import { NextResponse } from 'next/server';
import { warmupQstash } from '@/lib/qstash/backgroundScheduler';
import { supabaseAdmin } from '@/lib/supabase/server';
import { WARMUP_TOKEN } from '@/lib/auth/jwt';

// Unauthenticated (the keyboard calls this before it has a fresh token), so throttle the
// fan-out per instance: a warm instance that just warmed everything returns immediately.
// This bounds the cost of anyone hammering the endpoint to one cheap invocation per call.
const WARMUP_THROTTLE_MS = 60_000;
let lastWarmupAt = 0;

export async function POST() {
  if (Date.now() - lastWarmupAt < WARMUP_THROTTLE_MS) {
    return NextResponse.json({ success: true, throttled: true });
  }
  lastWarmupAt = Date.now();

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
