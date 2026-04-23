import { NextRequest, NextResponse } from 'next/server';
import { timingSafeEqual } from 'crypto';
import { handleRevenueCatEvent, type RevenueCatEvent } from '@/lib/credits/webhook';

function verifyAuth(header: string | null): boolean {
  const expected = process.env.REVENUECAT_WEBHOOK_TOKEN;
  if (!expected || !header) return false;
  const expectedBuf = Buffer.from(`Bearer ${expected}`);
  const headerBuf = Buffer.from(header);
  if (expectedBuf.length !== headerBuf.length) return false;
  return timingSafeEqual(expectedBuf, headerBuf);
}

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null);

  if (body && body.warmup === true) {
    return NextResponse.json({ success: true });
  }

  if (!verifyAuth(request.headers.get('authorization'))) {
    console.error(`${new Date().toISOString()} RevenueCat webhook: invalid auth`);
    return NextResponse.json({ detail: 'unauthorized' }, { status: 401 });
  }

  const event = (body?.event ?? null) as RevenueCatEvent | null;
  if (!event || !event.type || !event.id) {
    console.error(
      `${new Date().toISOString()} RevenueCat webhook: malformed body: ${JSON.stringify(body)}`
    );
    return NextResponse.json({ detail: 'malformed event' }, { status: 200 });
  }

  try {
    const outcome = await handleRevenueCatEvent(event);
    console.log(
      `${new Date().toISOString()} RevenueCat ${event.type} (${event.id}): ${outcome.summary}`
    );
    return NextResponse.json({ success: true, handled: outcome.handled });
  } catch (err) {
    console.error(
      `${new Date().toISOString()} RevenueCat ${event.type} (${event.id}) failed: ${JSON.stringify(err)}`
    );
    // Return 200 so RC doesn't retry a handler error forever; we have logs to investigate.
    return NextResponse.json({ detail: 'handler error' }, { status: 200 });
  }
}
