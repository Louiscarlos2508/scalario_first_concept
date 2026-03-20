-- AlterTable: add optional variantId to purchase_order_lines
ALTER TABLE "shared"."purchase_order_lines" ADD COLUMN "variant_id" UUID;
