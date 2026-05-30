import { z } from 'zod';
import { ROLE_NAME_REGEX, isSystemRole } from '../../core/security/constants';

/**
 * STORY-039 — DomainTemplate Zod schema.
 *
 * Represents the structural envelope of `catalog/domains/<id>.json`:
 * metadata, roles (with full RBAC matrix), modules referenced, navigation
 * per role, dashboard layouts per role. Module bodies (entities, screens,
 * actions) are generated dynamically via A2UI.
 */

const RoleId = z
  .string()
  .min(1)
  .max(32)
  .regex(ROLE_NAME_REGEX, 'role id must match ^[A-Z][A-Z0-9_]{0,31}$')
  .refine((r) => !isSystemRole(r), {
    message: 'system roles cannot be declared in a template (e.g. SUPER_ADMIN)',
  });

const ModuleId = z.string().regex(/^module_[a-z][a-z0-9_]*$/, {
  message: 'module_id must match module_<snake_case>',
});

const Permission = z
  .string()
  .regex(/^module_[a-z][a-z0-9_]*\.(read|write|validate|close)\.(all|own)$/, {
    message: 'permission must be module_<id>.<action>.<scope>',
  });

export const TenantDefaultsSchema = z.object({
  currency: z.string().length(3),
  locale: z.string().regex(/^[a-z]{2}(-[A-Z]{2})?$/),
  timezone: z.string().min(1),
  fiscal_year_start: z.string().regex(/^\d{2}-\d{2}$/, { message: 'MM-DD' }),
  tax_mode: z.enum(['configurable', 'inclusive', 'exclusive', 'none']),
  payment_methods_enabled: z.array(z.string()).min(1),
});

export const RoleDeclarationSchema = z.object({
  id: RoleId,
  name: z.string().min(1),
  i18n_key: z.string().min(1),
  description: z.string().min(1),
  dashboard_module_id: ModuleId,
  permissions: z.array(Permission).min(1),
  nav_modules: z.array(ModuleId).min(1),
});

export const ModuleReferenceSchema = z.object({
  module_id: ModuleId,
  i18n_key: z.string().min(1),
  version: z.string().regex(/^\d+\.\d+\.\d+$/),
  enabled: z.boolean(),
  phase: z.number().int().positive(),
});

export const NavigationEntrySchema = z.object({
  landing_screen_id: z.string().min(1),
  bottom_nav: z.array(ModuleId).min(1).max(5),
});

export const DashboardLayoutEntrySchema = z.object({
  role: RoleId,
  dashboard_module_id: ModuleId,
  dashboard_layout_id: z.string().min(1),
});

export const DomainTemplateSchema = z
  .object({
    schema_version: z.literal('1.0.0'),
    domain_id: z.string().regex(/^[a-z][a-z0-9_]*$/),
    name: z.string().min(1),
    i18n_key: z.string().min(1),
    sector: z.string().min(1),
    subsector: z.string().min(1).optional(),
    description: z.string().min(1),
    version: z.string().regex(/^\d+\.\d+\.\d+$/),
    min_users: z.number().int().positive(),
    max_users: z.number().int().positive(),
    tenant_defaults: TenantDefaultsSchema,
    roles_meta: z
      .object({
        scope_modifiers: z.record(z.string()),
        actions: z.array(z.string()).min(1),
        permission_format: z.string().min(1),
      })
      .optional(),
    roles: z.array(RoleDeclarationSchema).min(1),
    modules: z.array(ModuleReferenceSchema).min(1),
    navigation_per_role: z.record(NavigationEntrySchema),
    dashboard_layouts_per_role: z.array(DashboardLayoutEntrySchema).min(1),
  })
  .refine(
    (tpl) => {
      // Cross-check: every nav_module per role must appear in modules[]
      // OR be one of the "implicit" workflow-only modules (cloture_caisse
      // is referenced by workflows, not as a standalone module — per
      // STORY-039 edge case). Allow those as a documented exception.
      const declared = new Set(tpl.modules.map((m) => m.module_id));
      const implicitAllowed = new Set(['module_cloture_caisse']);
      for (const role of tpl.roles) {
        for (const nm of role.nav_modules) {
          if (!declared.has(nm) && !implicitAllowed.has(nm)) {
            return false;
          }
        }
        if (
          !declared.has(role.dashboard_module_id) &&
          !implicitAllowed.has(role.dashboard_module_id)
        ) {
          return false;
        }
      }
      return true;
    },
    { message: 'roles[].nav_modules and dashboard_module_id must reference declared modules[]' },
  )
  .refine(
    (tpl) => {
      // navigation_per_role keys must match role ids.
      const roleIds = new Set(tpl.roles.map((r) => r.id));
      for (const key of Object.keys(tpl.navigation_per_role)) {
        if (!roleIds.has(key)) return false;
      }
      for (const id of roleIds) {
        if (!(id in tpl.navigation_per_role)) return false;
      }
      return true;
    },
    { message: 'navigation_per_role keys must exactly match roles[].id' },
  )
  .refine(
    (tpl) => {
      // dashboard_layouts_per_role: one entry per role, role must exist.
      const roleIds = new Set(tpl.roles.map((r) => r.id));
      const seen = new Set<string>();
      for (const entry of tpl.dashboard_layouts_per_role) {
        if (!roleIds.has(entry.role)) return false;
        if (seen.has(entry.role)) return false;
        seen.add(entry.role);
      }
      return seen.size === roleIds.size;
    },
    { message: 'dashboard_layouts_per_role must have exactly one entry per role' },
  );

export type DomainTemplate = z.infer<typeof DomainTemplateSchema>;
export type RoleDeclaration = z.infer<typeof RoleDeclarationSchema>;
