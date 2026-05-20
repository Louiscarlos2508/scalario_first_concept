import { z } from 'zod';

export const GetBulkLayoutsQuerySchema = z.object({
  screens: z
    .string()
    .min(1)
    .transform((v) =>
      v
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean),
    ),
});

export const BULK_MAX_SCREENS = 10;

export function parseBulkScreens(raw: string): string[] {
  const screens = raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  if (screens.length === 0) {
    throw new Error('At least one screen is required');
  }
  if (screens.length > BULK_MAX_SCREENS) {
    throw new Error('Maximum 10 screens per bulk request');
  }
  return screens;
}
