-- CreateTable kernel.modules
CREATE TABLE "kernel"."modules" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "code" VARCHAR(100) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "dependencies" TEXT[] NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "modules_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: unique module code
CREATE UNIQUE INDEX "modules_code_key" ON "kernel"."modules"("code");

-- CreateTable kernel.tenant_modules
CREATE TABLE "kernel"."tenant_modules" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "module_id" UUID NOT NULL,
    "status" VARCHAR(50) NOT NULL DEFAULT 'inactive',
    "activated_at" TIMESTAMPTZ(6),

    CONSTRAINT "tenant_modules_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: unique (tenant_id, module_id) pair
CREATE UNIQUE INDEX "tenant_modules_tenant_id_module_id_key"
    ON "kernel"."tenant_modules"("tenant_id", "module_id");

-- AddForeignKey: tenant_modules → tenants
ALTER TABLE "kernel"."tenant_modules"
    ADD CONSTRAINT "tenant_modules_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: tenant_modules → modules
ALTER TABLE "kernel"."tenant_modules"
    ADD CONSTRAINT "tenant_modules_module_id_fkey"
    FOREIGN KEY ("module_id") REFERENCES "kernel"."modules"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- AlterTable kernel.tenants — add org_mode
-- Safe strategy: add with DEFAULT so existing rows are backfilled automatically
ALTER TABLE "kernel"."tenants"
    ADD COLUMN "org_mode" VARCHAR(50) NOT NULL DEFAULT 'standalone';
