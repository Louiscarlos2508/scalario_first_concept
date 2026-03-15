-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "kernel";

-- CreateTable: kernel.tenants with new fields (defaults applied)
CREATE TABLE "kernel"."tenants" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'XOF',
    "timezone" TEXT NOT NULL DEFAULT 'Africa/Abidjan',
    "fiscal_jurisdiction" TEXT,
    "status" TEXT NOT NULL DEFAULT 'active',
    "session_timeout_minutes" INTEGER NOT NULL DEFAULT 480,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tenants_pkey" PRIMARY KEY ("id")
);

-- CreateTable: kernel.organization_members
CREATE TABLE "kernel"."organization_members" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organization_members_pkey" PRIMARY KEY ("id")
);

-- Migrate data: copy existing tenants to kernel schema, populate defaults
INSERT INTO "kernel"."tenants" ("id", "name", "currency", "timezone", "status", "session_timeout_minutes", "created_at")
SELECT "id", "name", 'XOF', 'Africa/Abidjan', 'active', 480, "created_at"
FROM "public"."tenants"
ON CONFLICT ("id") DO NOTHING;

-- Migrate data: copy existing organization_members to kernel schema
INSERT INTO "kernel"."organization_members" ("id", "organization_id", "user_id", "role", "created_at")
SELECT "id", "organization_id", "user_id", "role", "created_at"
FROM "public"."organization_members"
ON CONFLICT ("id") DO NOTHING;

-- CreateIndex
CREATE UNIQUE INDEX "organization_members_organization_id_user_id_key"
    ON "kernel"."organization_members"("organization_id", "user_id");

-- AddForeignKey: kernel.organization_members → kernel.tenants
ALTER TABLE "kernel"."organization_members"
    ADD CONSTRAINT "organization_members_organization_id_fkey"
    FOREIGN KEY ("organization_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- DropForeignKey: public tables → public.tenants (must drop before dropping public.tenants)
ALTER TABLE "public"."organization_members" DROP CONSTRAINT IF EXISTS "organization_members_organization_id_fkey";
ALTER TABLE "public"."categories" DROP CONSTRAINT IF EXISTS "categories_tenant_id_fkey";
ALTER TABLE "public"."products" DROP CONSTRAINT IF EXISTS "products_tenant_id_fkey";
ALTER TABLE "public"."orders" DROP CONSTRAINT IF EXISTS "orders_tenant_id_fkey";
ALTER TABLE "public"."pos_sessions" DROP CONSTRAINT IF EXISTS "pos_sessions_tenant_id_fkey";
ALTER TABLE "public"."stock_movements" DROP CONSTRAINT IF EXISTS "stock_movements_tenant_id_fkey";
ALTER TABLE "public"."customers" DROP CONSTRAINT IF EXISTS "customers_tenant_id_fkey";
ALTER TABLE "public"."terminal_statuses" DROP CONSTRAINT IF EXISTS "terminal_statuses_tenant_id_fkey";

-- DropTable: public.organization_members and public.tenants
DROP TABLE "public"."organization_members";
DROP TABLE "public"."tenants";

-- AddForeignKey: public domain tables → kernel.tenants (cross-schema)
ALTER TABLE "public"."categories"
    ADD CONSTRAINT "categories_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "public"."products"
    ADD CONSTRAINT "products_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "public"."orders"
    ADD CONSTRAINT "orders_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "public"."pos_sessions"
    ADD CONSTRAINT "pos_sessions_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "public"."customers"
    ADD CONSTRAINT "customers_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "public"."terminal_statuses"
    ADD CONSTRAINT "terminal_statuses_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Enable Row Level Security on kernel tables
ALTER TABLE "kernel"."tenants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "kernel"."organization_members" ENABLE ROW LEVEL SECURITY;

-- RLS policy: only select/modify your own tenant row
-- Uses current_setting with TRUE (missing_ok) to avoid errors when not set
CREATE POLICY "tenant_self_access" ON "kernel"."tenants"
    FOR ALL
    USING (id::text = current_setting('app.current_tenant_id', TRUE));
