# Story 3: POS UI & State Management

**Goal:** Build the functional Point of Sale interface and connect it to the offline-first data layer.

## Context
We have the Repositories (`ProductRepository`, `OrderRepository`) and Models. Now we need the UI for Cashiers to actually process sales.

## Requirements

### 1. State Management (Riverpod)
- [ ] Create `CartState` (List of CartItems, Total calculation).
- [ ] Create `CartNotifier` to handle `addProduct`, `removeProduct`, `clearCart`.
- [ ] Create `PosController` to handle `checkout()` logic (calls `OrderRepository`).

### 2. POS Screen UI
- [ ] **Product Grid**: Display products fetched from `productRepositoryProvider`.
    - [ ] Handle loading/error states.
    - [ ] Tap to add to cart.
- [ ] **Cart Sidebar/Panel**:
    - [ ] List selected items with quantity.
    - [ ] Show Total Amount.
    - [ ] "Pay" Button.

### 3. Checkout Flow
- [ ] "Pay" Button -> Creates `Order` object -> Calls `OrderRepository.saveOrder()`.
- [ ] On success: Clear Cart, Show Success Snackbar/Dialog.
- [ ] On failure: Show Error.

## Acceptance Criteria
- User sees products from Isar (or Mock if empty).
- User can add items to cart and see total update.
- User can complete a "Sale", which saves an `Order` to Isar with `sync_status=pending` (verified via logs or inspection).
