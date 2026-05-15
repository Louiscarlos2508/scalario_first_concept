import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { RolesListSchema } from '../tenants/dto/update-roles.dto';

/**
 * Reads `catalog/domains/<template>.json` and extracts the role list. The
 * catalog directory is repo-rooted (resolved from `CATALOG_DIR` env or the
 * default `<cwd>/catalog`). STORY-021 will replace this with a richer
 * registry; for STORY-015 we only need the `roles` array.
 */
export function loadTemplateRoles(template: string): string[] {
  const root = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
  // Walk up one level if NestJS was started from apps/nestjs.
  const candidates = [
    resolve(root, 'domains', `${template}.json`),
    resolve(root, '..', 'catalog', 'domains', `${template}.json`),
    resolve(root, '..', '..', 'catalog', 'domains', `${template}.json`),
    resolve(root, '..', '..', '..', 'catalog', 'domains', `${template}.json`),
  ];

  let raw: string | null = null;
  for (const p of candidates) {
    try {
      raw = readFileSync(p, 'utf8');
      break;
    } catch {
      /* try next */
    }
  }
  if (raw === null) {
    throw new Error(`Template not found: ${template}`);
  }

  const parsed = JSON.parse(raw) as { roles?: unknown };
  const validated = RolesListSchema.safeParse(parsed.roles);
  if (!validated.success) {
    throw new Error(
      `Template ${template} has invalid roles: ${validated.error.issues.map((i) => i.message).join('; ')}`,
    );
  }
  return validated.data;
}
