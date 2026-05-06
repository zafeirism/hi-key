import { NextResponse } from 'next/server';
import { verifySignatureAppRouter } from '@upstash/qstash/nextjs';
import { cleanupOldGenerations } from '@/lib/cleanup/cleanup';

export const POST = verifySignatureAppRouter(async () => {
  const startedAt = Date.now();
  try {
    const result = await cleanupOldGenerations();
    console.log(
      `${new Date().toISOString()} Cleanup completed in ${Date.now() - startedAt}ms - rowsCleared: ${result.rowsCleared}, r2KeysDeleted: ${result.r2KeysDeleted}`
    );
    return NextResponse.json({ success: true, ...result });
  } catch (err) {
    console.error(
      `${new Date().toISOString()} Cleanup failed: ${err instanceof Error ? err.message : JSON.stringify(err)}`
    );
    return NextResponse.json({ error: 'cleanup_failed' }, { status: 500 });
  }
});
