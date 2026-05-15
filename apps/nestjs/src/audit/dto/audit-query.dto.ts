import { z } from 'zod';

/**
 * STORY-020 — GET /tenants/:slug/audit-logs query schema.
 *
 * Cursor pagination: the `cursor` is the base64 of
 * `{ created_at: ISO, id: UUID }` of the LAST item of the previous page.
 * It uniquely orders rows even across created_at collisions.
 */
export const AuditQuerySchema = z
  .object({
    from: z.string().datetime({ offset: true }).optional().or(z.string().datetime().optional()),
    to: z.string().datetime({ offset: true }).optional().or(z.string().datetime().optional()),
    user_id: z.string().uuid().optional(),
    action: z
      .string()
      .min(1)
      .max(64)
      .regex(/^[A-Z][A-Z0-9_]*$/, 'action must be UPPER_SNAKE_CASE')
      .optional(),
    module_id: z.string().min(1).max(64).optional(),
    cursor: z.string().min(1).max(512).optional(),
    limit: z.coerce.number().int().min(1).max(500).default(100),
  })
  .strict();

export type AuditQueryDto = z.infer<typeof AuditQuerySchema>;

export interface CursorPayload {
  created_at: string;
  id: string;
}

export function encodeCursor(payload: CursorPayload): string {
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

export function decodeCursor(input: string): CursorPayload | null {
  try {
    const raw = Buffer.from(input, 'base64url').toString('utf8');
    const obj = JSON.parse(raw) as Partial<CursorPayload>;
    if (
      typeof obj.created_at !== 'string' ||
      typeof obj.id !== 'string' ||
      Number.isNaN(Date.parse(obj.created_at))
    ) {
      return null;
    }
    return { created_at: obj.created_at, id: obj.id };
  } catch {
    return null;
  }
}
