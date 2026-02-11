# Story 7: Advanced POS Features (Park/Resume & Discounts)

**Goal:** Increase cashier efficiency by allowing them to handle multiple customers at once and apply promotional prices.

## Context
In a busy retail environment, a customer might forget an item. The cashier needs to "park" the current cart and serve the next person without losing the previous cart's data.

## Requirements

### 1. Hold/Resume Cart (Parking)
- [ ] **State**: Add `parkedCarts` to `CartNotifier` state (List of CartStates).
- [ ] **UI**: "Hold" button on CartPanel.
- [ ] **UI**: "Resume" button (or list) to see and reload parked carts.
- [ ] **Persistence**: Ensure parked carts are saved to Isar so they survive an app restart.

### 2. Discounts
- [ ] **Model**: Add `discountAmount` and `discountType` (Percentage/Fixed) to `CartItem`.
- [ ] **UI**: "Add Discount" button on each cart row.
- [ ] **Logic**: Update Total calculation to subtract discounts.

## Acceptance Criteria
- Cashier can add 3 items, press "Hold", clear the screen, and later "Resume" the same 3 items.
- Applying a 10% discount on a $100 item correctly shows a $90 subtotal.
- Parked carts are visible in a sidebar or separate list.
