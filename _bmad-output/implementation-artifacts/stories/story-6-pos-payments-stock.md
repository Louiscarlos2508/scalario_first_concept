# Story 6: Enhanced Checkout & Payments

**Goal:** Support multiple payment methods and ensure real-time inventory deduction upon sale.

## Context
The POS must handle different ways of getting paid (Cash, Mobile Money) and immediately reflect stock changes so the cashier knows what's still available.

## Requirements

### 1. Payment Methods
- [x] **Model Update**: Add `paymentMethod` and `sessionId` to `Order` (both local and backend).
- [x] **UI**: Integrated selector in `CartPanel` (Cash, Mobile Money, Card).
- [x] **State**: `CartState` carries the selected payment method.

### 2. Inventory Management (Local)
- [x] **Decrement Logic**: `ProductRepository` should have a `decrementStock` method.
- [x] **Trigger**: Call stock deduction immediately upon successful `saveOrder` in `CheckoutController`.

### 3. Verification & Sync
- [ ] Verify orders in Supabase have the correct `payment_method` and `session_id`.
- [ ] Verify local Isar product stock reflects the deduction.

## Acceptance Criteria
- [ ] Cashier can select "Mobile Money" for a sale.
- [ ] Stock count decreases *immediately* after the "Sale Successful" snackbar appears.
- [ ] Order data synced to server contains the payment metadata.
