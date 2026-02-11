# Story 8: Receipts & Barcode Scanning

**Goal:** Professionalize the POS with physical output and fast data entry.

## Context
A POS is only as fast as its data entry. Barcode scanning ensures accuracy. Receipts are mandatory for customer trust and tax purposes.

## Requirements

### 1. Barcode Scanning
- [ ] **Library**: Add `mobile_scanner` or similar (for mobile/tablet) and hardware keyboard listener (for desktop/USB scanners).
- [ ] **Logic**: When a 13-digit code is detected, auto-lookup product and add to cart.
- [ ] **UI**: Visual indicator/button to toggle camera scanner.

### 2. Receipt Generation
- [ ] **Generator**: Create a PDF/Text template for the ticket (Logo, Tenant Name, Items, Total, Payment Method, Date).
- [ ] **Bluetooth/Thermal**: Integrate `blue_thermal_printer` or generic print library.
- [ ] **Workflow**: Auto-prompt "Print Receipt?" after successful checkout.

## Acceptance Criteria
- Scanning a barcode adds the correct product to the cart without manual clicking.
- Clicking "Print" generates a formatted receipt (as a PDF or to a connected printer).
- Receipt contains all session and order metadata (Order #, Date, Tenant Name).
