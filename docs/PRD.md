# Product Requirements Document (PRD): Scalario Core + POS MVP

**Version:** 1.0
**Status:** Draft
**Author:** Product Manager Agent (BMAD)

## 1. Scope Overview
This PRD covers the MVP release of Scalario, comprising the **Scalario Core** (shared foundations) and the **POS Module** (first functional vertical).

## 2. Scalario Core (Shared Services)
The Core provides services required by *all* future modules.
- **Multi-Tenancy:**
    - **Global ID:** Unique identifier for every Tenant (Business).
    - **Isolation:** Strict Row Level Security (RLS) to ensure tenants see only their data.
- **Auth & Identity:**
    - User Authentication (Supabase Auth).
    - Role-Based Access Control (RBAC): Super Admin, Tenant Admin, Manager, Cashier.
- **Organization Management:**
    - Multi-branch support (Headquarters + Outlets).
- **Synchronization Engine:**
    - "Sync Vitals": A mechanism to push offline changes and pull updates.
    - Conflict resolution strategy: "Last Write Wins" or "Server Authority" based on entity type.

## 3. POS Module (MVP Features)
### 3.1 User Roles
- **Cashier:** fast sales entry, end-of-day count, no access to sensitive settings.
- **Store Manager:** void items, manage stock adjustments, view local reports.
- **Owner/Admin:** full access to all data across branches (via Dashboard).

### 3.2 Cashing Flow (Flux Caisse)
- **Open Session:** Cashier starts day, declares floating cash (fond de caisse).
- **Cart Operation:**
    - Search products (Barcode scan / Text search).
    - Add to cart, modify quantity, apply line discounts (permission based).
    - Hold/Resume cart (Park sale).
- **Checkout:**
    - Multiple payment methods: Cash, Mobile Money, Card, Credit/Later.
    - Split payments.
    - Receipt generation (Thermal printer / Digital PDF).
- **Close Session:** Blind count of cash, system variance report, Z-Report generation.

### 3.3 Inventory & Stock
- **Real-time Deduction:** Stock decrements locally immediately upon sale.
- **Stock Lookup:** Check stock levels at other branches.

### 3.4 Offline/Online Strategy
- **Local Database (Isar/Sqlite):** The "source of truth" for the POS UI.
- **Background Sync:** A generic queue system sends `CREATED_ORDER`, `UPDATED_STOCK` events to the cloud when online.

## 4. Technical Constraints
- **Platform:** Flutter (Mobile/Tablet/Desktop/Web).
- **Backend:** NestJS (Business Logic).
- **Database:** Supabase (Postgres).
- **Connectivity:** Must function 100% offline for sales and essential lookups.
