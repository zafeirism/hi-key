import { NextResponse } from 'next/server';
import { withAuth } from '@/lib/auth/jwt';
import { autoComplete } from '@/lib/ai/autocomplete';

export const POST = withAuth(async (request) => {
  const body = await request.json();
  const { prompt, warmup } = body;

  if (warmup || !prompt) {
    return NextResponse.json({ success: true, completion: '' });
  }

  const startTime = Date.now();
  const result = await autoComplete(prompt);
  const duration = Date.now() - startTime;

  return NextResponse.json({
    success: true,
    completion: result.completion,
    duration,
  });
});
