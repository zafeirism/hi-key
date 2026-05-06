import { supabaseAdmin } from '@/lib/supabase/server';
import { deleteImages, getKey } from '@/lib/storage/r2';

const DEFAULT_OLDER_THAN_MINUTES = 30;
const BATCH_SIZE = 500;

export type CleanupResult = {
  rowsCleared: number;
  r2KeysDeleted: number;
};

/**
 * Removes prompt PII and image objects for generations older than the cutoff.
 *
 * - NULLs `user_prompt` and `improved_prompt` on matching rows.
 * - Deletes the corresponding R2 objects in a single batch.
 *
 * Bounded by BATCH_SIZE per run; the next scheduled run picks up any remainder.
 * Idempotent: rows already cleared (user_prompt IS NULL) are skipped.
 */
export async function cleanupOldGenerations(
  olderThanMinutes: number = DEFAULT_OLDER_THAN_MINUTES
): Promise<CleanupResult> {
  const cutoff = new Date(Date.now() - olderThanMinutes * 60 * 1000).toISOString();

  const { data: rows, error: selectError } = await supabaseAdmin
    .from('generations')
    .select('id, user_id, file_extension')
    .lt('created_at', cutoff)
    .not('user_prompt', 'is', null)
    .limit(BATCH_SIZE);

  if (selectError) {
    throw new Error(`cleanup select failed: ${selectError.message}`);
  }
  if (!rows || rows.length === 0) {
    return { rowsCleared: 0, r2KeysDeleted: 0 };
  }

  const keys = rows
    .filter((r) => r.user_id && r.file_extension)
    .map((r) => getKey(r.user_id!, r.id, r.file_extension!));

  await deleteImages(keys);

  const ids = rows.map((r) => r.id);
  const { error: updateError } = await supabaseAdmin
    .from('generations')
    .update({ user_prompt: null, improved_prompt: null })
    .in('id', ids);

  if (updateError) {
    throw new Error(`cleanup update failed: ${updateError.message}`);
  }

  return { rowsCleared: ids.length, r2KeysDeleted: keys.length };
}
