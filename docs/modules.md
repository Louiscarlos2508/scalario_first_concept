# System Boundaries: Core vs Modules

**Version:** 1.0
**Author:** Solution Architect Agent (BMAD)

This document defines the separation of concerns between `Scalario Core` and the `POS Module`.

## 1. Concept
-   **Core:** Infrastructure-level concerns and domain entities that are universally applicable to *any* business using the ERP (e.g., "Who are you?", "Which company?", "Did you pay us?").
-   **Module (POS):** Vertical business logic specific to the retail/selling process.

## 2. Module Boundaries

| Entity / Feature | Module | Responsibility |
| :--- | :--- | :--- |
| **Auth & Identity** | 🔵 **CORE** | Sign-up, Sign-in, Password Reset, MFA. |
| **Tenancy** | 🔵 **CORE** | Organization creation, Branch management, Subscription status. |
| **User Management** | 🔵 **CORE** | User creation, Global Roles (Admin, Staff), Permissions. |
| **Billing** | 🔵 **CORE** | SaaS subscription management, Invoicing the tenant. |
| **Sync Engine** | 🔵 **CORE** | Generic mechanisms for Delta Sync and Conflict Resolution. |
| **Audit Logs** | 🔵 **CORE** | "Who did what when" (Global). |
| | | |
| **Catalog** | 🟠 **POS** | Products, Variants, Categories, Barcodes, Prices. |
| **Inventory** | 🟠 **POS** | Stock levels, Stock movements, Warehouses (Local). |
| **Sales** | 🟠 **POS** | Carts, Orders, Discounts, Taxes. |
| **Payments** | 🟠 **POS** | Payment methods (Cash, Card), Split payments, Refunds. |
| **Hardware** | 🟠 **POS** | Printer integration, Scanner handling, Cash drawer. |
| **Offline Cache** | 🟠 **POS** | Local copies of Catalog and pending Sales. |

## 3. Dependency Rule
-   **Core** knows NOTHING about **POS**.
-   **POS** depends on **Core** for Auth, User context, and Tenant context.
