-- Epic 30: Commandes Clients (FR107–FR110)
-- Story 30-1: ClientOrder + ClientOrderLine models

-- CreateTable client_orders
CREATE TABLE "shared"."client_orders" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "order_number" VARCHAR NOT NULL,
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "status" VARCHAR NOT NULL DEFAULT 'draft',
    "deposit_amount" DECIMAL(10,2),
    "deposit_paid_at" TIMESTAMPTZ(6),
    "notes" TEXT,
    "desired_delivery_date" DATE,
    "created_by" UUID NOT NULL,
    "prepared_by" UUID,
    "delivered_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "delivered_at" TIMESTAMPTZ(6),

    CONSTRAINT "client_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable client_order_lines
CREATE TABLE "shared"."client_order_lines" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "client_order_id" UUID NOT NULL,
    "catalog_item_id" UUID NOT NULL,
    "variant_id" UUID,
    "quantity" DECIMAL(10,3) NOT NULL,
    "unit_price" DECIMAL(10,2) NOT NULL,
    "delivered_qty" DECIMAL(10,3) NOT NULL DEFAULT 0,

    CONSTRAINT "client_order_lines_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "client_orders_order_number_key" ON "shared"."client_orders"("order_number");
CREATE INDEX "client_orders_tenant_id_status_idx" ON "shared"."client_orders"("tenant_id", "status");
CREATE INDEX "client_orders_customer_id_idx" ON "shared"."client_orders"("customer_id");
CREATE INDEX "client_order_lines_client_order_id_idx" ON "shared"."client_order_lines"("client_order_id");

-- AddForeignKey
ALTER TABLE "shared"."client_order_lines" ADD CONSTRAINT "client_order_lines_client_order_id_fkey"
    FOREIGN KEY ("client_order_id") REFERENCES "shared"."client_orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
