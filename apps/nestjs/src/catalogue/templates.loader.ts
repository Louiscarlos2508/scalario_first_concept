import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { RolesListSchema } from '../tenants/dto/update-roles.dto';
import { DomainTemplateSchema, type DomainTemplate } from './dto/domain-template.dto';

/**
 * Resolves `catalog/domains/<template>.json` walking up from the
 * working directory. The catalog directory is repo-rooted (resolved
 * from `CATALOG_DIR` env or `<cwd>/catalog`, with parent-dir fallbacks).
 */
function readTemplateFile(template: string): string {
  const root = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
  const candidates = [
    resolve(root, 'domains', `${template}.json`),
    resolve(root, '..', 'catalog', 'domains', `${template}.json`),
    resolve(root, '..', '..', 'catalog', 'domains', `${template}.json`),
    resolve(root, '..', '..', '..', 'catalog', 'domains', `${template}.json`),
  ];
  for (const p of candidates) {
    try {
      return readFileSync(p, 'utf8');
    } catch {
      /* try next */
    }
  }
  throw new Error(`Template not found: ${template}`);
}

/**
 * STORY-039 — Loads a domain template and validates it against the
 * full `DomainTemplateSchema` (3 roles, modules, navigation, dashboards).
 * Throws with the formatted Zod issues on validation failure.
 */
export function loadDomainTemplate(template: string): DomainTemplate {
  const raw = readTemplateFile(template);
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    throw new Error(`Template ${template} is not valid JSON: ${(err as Error).message}`);
  }
  const validated = DomainTemplateSchema.safeParse(parsed);
  if (!validated.success) {
    throw new Error(
      `Template ${template} failed schema validation: ${validated.error.issues
        .map((i) => `[${i.path.join('.')}] ${i.message}`)
        .join('; ')}`,
    );
  }
  return validated.data;
}

/**
 * STORY-015 legacy compat: provision flow needs only the role names as
 * strings. Now derived from the validated `DomainTemplate.roles[].id`.
 * Old shape (top-level `roles: string[]`) still accepted as fallback so
 * minimal stub templates keep working.
 */
export function loadTemplateRoles(template: string): string[] {
  const raw = readTemplateFile(template);
  const parsed = JSON.parse(raw) as { roles?: unknown };

  // New shape: roles = array of objects with .id (STORY-039)
  if (
    Array.isArray(parsed.roles) &&
    parsed.roles.every((r) => typeof r === 'object' && r !== null && 'id' in r)
  ) {
    const ids = parsed.roles.map((r) => (r as { id: string }).id);
    const validated = RolesListSchema.safeParse(ids);
    if (!validated.success) {
      throw new Error(
        `Template ${template} has invalid role ids: ${validated.error.issues.map((i) => i.message).join('; ')}`,
      );
    }
    return validated.data;
  }

  // Legacy shape: roles = string[]
  const validated = RolesListSchema.safeParse(parsed.roles);
  if (!validated.success) {
    throw new Error(
      `Template ${template} has invalid roles: ${validated.error.issues.map((i) => i.message).join('; ')}`,
    );
  }
  return validated.data;
}
