-- CreateTable kernel.audit_log
CREATE TABLE "kernel"."audit_log" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "user_id" UUID,
    "action" VARCHAR(20) NOT NULL,
    "entity" VARCHAR(100) NOT NULL,
    "entity_id" UUID NOT NULL,
    "before" JSONB,
    "after" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: (tenant_id, created_at) — for per-tenant chronological queries
CREATE INDEX "audit_log_tenant_id_created_at_idx"
    ON "kernel"."audit_log"("tenant_id", "created_at");

-- CreateIndex: entity_id — for per-entity history queries
CREATE INDEX "audit_log_entity_id_idx"
    ON "kernel"."audit_log"("entity_id");

-- AddForeignKey: audit_log → tenants
ALTER TABLE "kernel"."audit_log"
    ADD CONSTRAINT "audit_log_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Immutability: prevent UPDATE and DELETE on audit_log rows at the DB level
CREATE OR REPLACE FUNCTION kernel.prevent_audit_log_mutation()
RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'audit_log is immutable — updates and deletes are not permitted';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "audit_log_immutability"
    BEFORE UPDATE OR DELETE ON "kernel"."audit_log"
    FOR EACH ROW
    EXECUTE FUNCTION kernel.prevent_audit_log_mutation();
