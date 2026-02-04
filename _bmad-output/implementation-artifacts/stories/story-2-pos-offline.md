# Story 2: POS Offline Foundations

**Goal:** Implement the "Offline-First" architecture for the Point of Sale module.

## Context
The POS must work 100% offline. We need a local database (Isar) to store Products and Sales, and a Sync Engine to push/pull data when online.

## Requirements

### 1. Local Database (Isar)
- [ ] Add `isar` dependency to `apps/frontend`.
- [ ] Define Isar Collections: `Product`, `CartItem`, `Order`.
- [ ] Create `DatabaseService` to manage local DB connection.

### 2. Product Sync (Downstream)
- [ ] Create `ProductRepository` with `getProducts()` method.
- [ ] Logic: Fetch from Isar first. If online, fetch from API in background and update Isar.

### 3. Order Sync (Upstream)
- [ ] Create `OrderRepository` with `saveOrder()` method.
- [ ] Logic: Save to Isar with `sync_status = pending`.
- [ ] Create `SyncService`: Periodically check for `pending` orders and push to NestJS API.

## Acceptance Criteria
- App starts offline and can read dummy products from Isar.
- Creating an order offline saves it locally.
- Restoring connectivity automatically pushes the pending order to the backend (mocked backend endpoint is fine).
