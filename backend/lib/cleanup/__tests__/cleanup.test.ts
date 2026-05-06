import { describe, it, expect, vi, beforeEach } from 'vitest';

const deleteImagesMock = vi.fn();
const selectLimitMock = vi.fn();
const updateInMock = vi.fn();

vi.mock('@/lib/storage/r2', async () => {
  const actual = await vi.importActual<typeof import('@/lib/storage/r2')>('@/lib/storage/r2');
  return {
    ...actual,
    deleteImages: (...args: unknown[]) => deleteImagesMock(...args),
  };
});

vi.mock('@/lib/supabase/server', () => ({
  supabaseAdmin: {
    from: () => ({
      select: () => ({
        lt: () => ({
          not: () => ({
            limit: (n: number) => selectLimitMock(n),
          }),
        }),
      }),
      update: (patch: unknown) => ({
        in: (col: string, ids: string[]) => updateInMock(patch, col, ids),
      }),
    }),
  },
}));

import { cleanupOldGenerations } from '../cleanup';

beforeEach(() => {
  deleteImagesMock.mockReset().mockResolvedValue(undefined);
  selectLimitMock.mockReset();
  updateInMock.mockReset().mockResolvedValue({ error: null });
});

describe('cleanupOldGenerations', () => {
  it('returns zero counts when no rows are due', async () => {
    selectLimitMock.mockResolvedValue({ data: [], error: null });

    const result = await cleanupOldGenerations();

    expect(result).toEqual({ rowsCleared: 0, r2KeysDeleted: 0 });
    expect(deleteImagesMock).not.toHaveBeenCalled();
    expect(updateInMock).not.toHaveBeenCalled();
  });

  it('deletes R2 objects and nulls prompts for due rows', async () => {
    selectLimitMock.mockResolvedValue({
      data: [
        { id: 'g1', user_id: 'u1', file_extension: 'webp' },
        { id: 'g2', user_id: 'u1', file_extension: 'png' },
      ],
      error: null,
    });

    const result = await cleanupOldGenerations();

    expect(deleteImagesMock).toHaveBeenCalledWith([
      'users/u1/images/g1.webp',
      'users/u1/images/g2.png',
    ]);
    expect(updateInMock).toHaveBeenCalledWith(
      { user_prompt: null, improved_prompt: null },
      'id',
      ['g1', 'g2']
    );
    expect(result).toEqual({ rowsCleared: 2, r2KeysDeleted: 2 });
  });

  it('still nulls prompts for rows missing file_extension (e.g. blocked)', async () => {
    selectLimitMock.mockResolvedValue({
      data: [
        { id: 'g1', user_id: 'u1', file_extension: null },
        { id: 'g2', user_id: 'u1', file_extension: 'webp' },
      ],
      error: null,
    });

    const result = await cleanupOldGenerations();

    expect(deleteImagesMock).toHaveBeenCalledWith(['users/u1/images/g2.webp']);
    expect(updateInMock).toHaveBeenCalledWith(
      { user_prompt: null, improved_prompt: null },
      'id',
      ['g1', 'g2']
    );
    expect(result).toEqual({ rowsCleared: 2, r2KeysDeleted: 1 });
  });

  it('throws when the select fails', async () => {
    selectLimitMock.mockResolvedValue({ data: null, error: { message: 'boom' } });

    await expect(cleanupOldGenerations()).rejects.toThrow(/cleanup select failed: boom/);
    expect(deleteImagesMock).not.toHaveBeenCalled();
    expect(updateInMock).not.toHaveBeenCalled();
  });

  it('throws when the update fails', async () => {
    selectLimitMock.mockResolvedValue({
      data: [{ id: 'g1', user_id: 'u1', file_extension: 'webp' }],
      error: null,
    });
    updateInMock.mockResolvedValue({ error: { message: 'nope' } });

    await expect(cleanupOldGenerations()).rejects.toThrow(/cleanup update failed: nope/);
    expect(deleteImagesMock).toHaveBeenCalledOnce();
  });
});
