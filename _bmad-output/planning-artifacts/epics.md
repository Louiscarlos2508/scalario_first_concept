---
stepsCompleted: [step-01-validate-prerequisites]
inputDocuments: [PRD.md, ARCHITECTURE.md, product_brief.md]
---

# scalario - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for scalario, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: POS Sales Entry - Ability to search products via barcode scan or text search.
FR2: Cart Operations - Support for adding items, modifying quantities, applying line discounts, and parking/resuming sales.
FR3: Multi-Method Checkout - Support for Cash, Mobile Money, Card, and Split Payments.
FR4: Receipt Generation - Automated generation of professional receipts (Thermal/PDF).
FR5: POS Session Management - Workflow for opening sessions (float declaration) and closing sessions (Z-Report, reconciliation).
FR6: Real-time Stock Management - Automatic local deduction of stock upon sale and stock lookup across branches.
FR7: Administrative Dashboard - Web-based interface for owners to view aggregated sales data across branches.
FR8: Inventory Management - CRUD interface in the dashboard for managing products, categories, and stock levels.
FR9: Multi-Tenancy Foundations - Robust tenant isolation using Global IDs and RLS.
FR10: RBAC - Role-Based Access Control specifying permissions for Super Admin, Tenant Admin, Manager, and Cashier.

### NonFunctional Requirements

NFR1: Offline-First baseline - Core system must function 100% offline for sales and essential lookups.
NFR2: Background Sync Engine - Efficient delta-based synchronization of local changes to the cloud.
NFR3: Security & Isolation - Strict data isolation via Row Level Security and JWT-protected API.
NFR4: Cross-Platform Support - Unified codebase targeting Android, Windows, and Web.
NFR5: Efficient Data Usage - Sync mechanism must be optimized for bandwidth-constrained environments.

### Additional Requirements

- **Backend Architecture**: NestJS Modular Monolith approach.
- **Frontend Architecture**: Flutter Layered Architecture.
- **Conflict Resolution**: Logic to handle "Server Authority" or "Last Write Wins" during sync.
- **Supabase Integration**: Utilization of Supabase for Auth, Postgres, and Realtime notifications.

### FR Coverage Map

FR1: Epic 3 - Barcode Scanning & Sales Entry
FR2: Epic 2 - Cart Operations & Parked Sales
FR3: Epic 3 - Multi-Method Payments
FR4: Epic 3 - Receipt Generation
FR5: Epic 2 - POS Session Management
FR6: Epic 5 - Offline Stock Management & Sync
FR7: Epic 4 - Administrative Dashboard Shell
FR8: Epic 4 - Inventory CRUD & Stock Control
FR9: Epic 1 - Multi-Tenancy Foundations
FR10: Epic 1 - Authentication & RBAC

## Epic List

### Epic 1: Multi-Tenant Foundations & Authentication
Establish the secure baseline for the platform, ensuring users can log in, access their specific tenant, and have permissions based on their roles.
**FRs covered:** FR9, FR10

### Epic 2: POS Retail Workflow (Flux Caisse)
Enable cashiers to manage carts, park sales for later resumption, and handle shift-based session management.
**FRs covered:** FR2, FR5

### Epic 3: Advanced Checkout & Rapid Entry
Optimize the checkout process with support for various payment methods, barcode scanning for speed, and professional receipt printing.
**FRs covered:** FR1, FR3, FR4

### Epic 4: Management Dashboard & Inventory Control
Provide business owners with a centralized web interface to manage products, monitor global inventory, and navigate administrative features.
**FRs covered:** FR7, FR8

### Epic 5: Synchronization & Real-time Persistence
Ensure all local operations are securely synchronized to the cloud with background delta updates and stock consistency.
**FRs covered:** FR6

## Epic 1: Multi-Tenant Foundations & Authentication

[Epic goal statement - Secure multi-tenant access]

## Epic 2: POS Retail Workflow (Flux Caisse)

[Epic goal statement - Manage daily retail operations]

## Epic 3: Advanced Checkout & Rapid Entry

[Epic goal statement - Speed up checkout and generate tickets]

## Epic 4: Management Dashboard & Inventory Control

Centralize administration and product management through a web-based interface for owners and managers.

### Story 4.1: Dashboard Shell & Sidebar Navigation

As a Tenant Admin,
I want a unified dashboard interface with sidebar navigation,
So that I can easily switch between sales overview, inventory, and branch management.

**Acceptance Criteria:**

**Given** I am logged in as an Admin
**When** I access the Dashboard route
**Then** I see a sidebar with links for 'Overview', 'Inventory', 'Reports', and 'Settings'
**And** clicking a link navigates to the respective sub-screen without full page reload
**And** an "Open POS" button is available for quick switching

### Story 4.2: Inventory Management (Product List)

As an Admin,
I want to view a paginated list of all products in my store,
So that I can monitor stock levels and prices at a glance.

**Acceptance Criteria:**

**Given** I am on the Inventory screen
**When** the screen loads
**Then** I see a table displaying Name, Category, Price, Stock, and Barcode for all products
**And** I can filter the list by product name or barcode search
**And** the list supports pagination for high product counts

### Story 4.3: Product CRUD (Create/Edit)

As an Admin,
I want to add new products or update existing ones directly from the dashboard,
So that my store content remains accurate.

**Acceptance Criteria:**

**Given** I am on the Inventory screen
**When** I click "Add Product" or "Edit" on an existing item
**Then** a form appears allowing me to modify Name, Price, Category, and Barcode
**And** saving updates the remote database (Supabase) via the NestJS API
**And** the changes are reflected in the POS product grid upon next sync

### Story 4.4: Stock Adjustments & Manual Control

As a Store Manager,
I want to manually adjust stock levels for specific items,
So that I can account for damaged goods or stock replenishment.

**Acceptance Criteria:**

**Given** I am viewing a specific product's details
**When** I enter a stock adjustment amount and reason
**Then** the `stockQuantity` is updated in the database
**And** the adjustment is logged in the system (audit trail)

### Story 4.5: Sales Performance Overview (Charts)

As an Owner,
I want to see basic charts of daily and weekly sales totals,
So that I can track business performance trends.

**Acceptance Criteria:**

**Given** I am on the Dashboard Overview
**When** I select a date range
**Then** I see a chart showing revenue trends over that period
**And** summary cards display "Total Revenue", "Order Count", and "Average Ticket Size"

## Epic 5: Synchronization & Real-time Persistence

[Epic goal statement - Reliable data sync and stock deduction]
