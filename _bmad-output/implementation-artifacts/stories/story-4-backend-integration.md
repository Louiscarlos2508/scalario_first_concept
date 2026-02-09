# Story 4: Real Backend Integration

**Goal:** Connect the POS Offline module to a real Backend and Database, replacing mocks with actual persistence.

## Context
Currently, `SyncService` (Frontend) simulates network calls, and `PosController` (Backend) returns static mock data. Accessing `127.0.0.1` works for `mock` data, but we need real persistence.

## Requirements

### 1. Database Schema (Supabase/Postgres)
- [ ] Define `products` table (uuid, name, price, category, stock_quantity, tenant_id).
- [ ] Define `orders` table (uuid, total_amount, items_json, tenant_id, created_at).
- [ ] Run Migrations (or create tables via SQL).

### 2. Backend Logic (NestJS)
- [ ] **Prisma/TypeORM Setup**: Connect NestJS to Supabase Postgres.
- [ ] `ProductsService`:
    - `findAll()`: Fetch from DB.
- [ ] `OrdersService`:
    - `create()`: Insert into DB.
    - Transactional safety (optional for now, but good practice).
- [ ] Update `PosController` to use these services.

### 3. Frontend Logic (Flutter)
- [ ] Update `SyncService`:
    - `_pullProducts()`: GET `/pos/products` (Real API).
    - `_pushPendingOrders()`: POST `/pos/orders` (Real API).
- [ ] **Config**: Add `IntegrationConfig` or `Env` to point to real Backend URL (e.g. `http://localhost:3000`).

## Acceptance Criteria
- Starting Backend + Frontend (with local Supabase running).
- Creating a product in Supabase (SQL/Dashboard) -> Appears in POS Grid after Sync.
- Completing an Order in POS -> Appears in `orders` table in Supabase.
