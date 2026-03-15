-- Phase 3 DB Anticipation Fields (Story 1.6)
-- Pure additive migration: only ADD COLUMN statements.
-- All new fields are nullable or have safe defaults — zero breaking change for existing rows.
--
-- kernel.tenants: Phase 2b/3 fields for Programme Ambassadeurs, Connect, Enterprise
-- kernel.organization_members: Phase 3 department membership (Enterprise)
-- kernel.tenant_modules: Phase 3 department-scoped activation (Enterprise)

-- AlterTable: kernel.tenants (Phase 2b — Programme Ambassadeurs)
ALTER TABLE "kernel"."tenants" ADD COLUMN "referred_by" UUID;

-- AlterTable: kernel.tenants (Phase 3 — Scalario Connect)
ALTER TABLE "kernel"."tenants" ADD COLUMN "network_visible" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable: kernel.tenants (Phase 3 — Scalario Enterprise)
ALTER TABLE "kernel"."tenants" ADD COLUMN "parent_tenant_id" UUID;

-- AlterTable: kernel.organization_members (Phase 3 — Scalario Enterprise)
ALTER TABLE "kernel"."organization_members" ADD COLUMN "department_ids" UUID[] NOT NULL DEFAULT ARRAY[]::UUID[];

-- AlterTable: kernel.tenant_modules (Phase 3 — Scalario Enterprise)
ALTER TABLE "kernel"."tenant_modules" ADD COLUMN "department_id" UUID;
