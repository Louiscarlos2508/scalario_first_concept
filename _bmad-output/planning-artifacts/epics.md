---
stepsCompleted: ['step-01-validate-prerequisites']
inputDocuments:
  - docs/prd-scalario-retail-2026-04-06.md
  - docs/architecture-scalario-retail-2026-04-06.md
---

# Scalario Retail Phase 1 - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Scalario Retail Phase 1, decomposing the requirements from the PRD and Architecture into implementable stories. Phase 1 only — no references to future phases.

## Requirements Inventory

### Functional Requirements

FR-001: Create a retail sale — select products, adjust quantities, auto-calculate total, record transaction locally (offline)
FR-002: Select payment method — manual selection of Cash / Wave / Orange Money per transaction
FR-003: Sales history — view past sales with filters (date, seller, payment method), view sale detail
FR-004: Wholesale sale — sell by wholesale unit (carton, sac) at distinct wholesale price, correct stock deduction
FR-005: Wholesale unit conversion — configure wholesale unit + conversion factor per product (e.g. 1 carton = 12 units)
FR-006: Product catalog CRUD — create, read, update, delete products with name, category, retail price, wholesale price, base unit, optional image
FR-007: Product variants — add variants (size, weight, packaging) with distinct price and stock per variant
FR-008: Stock tracking — real-time quantity tracking with movement history (in, out, adjustment), auto-deduction on sale
FR-009: Low stock alerts — configurable threshold per product, visual alert, quick-access low stock list
FR-010: Stock entry via supply — record incoming supply (products, quantities, cost), optional supplier link, auto-increment stock
FR-011: Configure frotte rate — set loss percentage per perishable product (default 0%)
FR-012: Price calculation with frotte — system suggests selling price integrating frotte rate to preserve margin
FR-013: Bulk-to-sachet conversion rules — define source unit, derived unit, conversion factor (e.g. 5kg bag → 50x 100g sachets)
FR-014: Auto stock deduction for conversions — selling derived units decrements source stock proportionally
FR-015: Freshness visual indicator — color code (green/orange/red) on perishable products based on entry date and shelf life
FR-016: Priority sale alert — list of products near expiration, suggestion to prioritize in POS, counter on dashboard
FR-017: Open cash register — declare opening cash amount, timestamp, associate to user, one active session at a time
FR-018: Close cash register and reconciliation — declare counted amount, auto-calculate discrepancy vs theoretical, summary by payment method
FR-019: Record expenses — amount, category (predefined + custom), description, date, appears in financial reports
FR-020: Create internal order — select products and quantities, optional supplier, status "Pending", creator can cancel before approval
FR-021: Order validation workflow — manager approves → owner validates, mandatory reason on rejection, status history
FR-022: Order pending notification — in-app notification to owner, badge counter on dashboard, tap opens order
FR-023: Daily push summary — evening push to owner with day's revenue, sales count, stock alerts, losses
FR-024: Daily revenue report — total revenue, breakdown by payment method, by seller, comparison graph, period filter
FR-025: Stock status report — product list with current quantity and value, recent movements, category filter, export/share (PDF/image)
FR-026: Loss report — losses by frotte, expired products, total loss amount, weekly trend
FR-027: Supplier CRUD — name, phone, address, notes, link suppliers to products
FR-028: Purchase history by supplier — filtered supply list, total purchased per period, supply detail
FR-029: User authentication — register with email/password, login with session persistence, logout, password reset by email
FR-030: Roles and permissions — 3 hardcoded roles (Owner, Manager, Seller) with toggleable permissions per user
FR-031: Complete offline operation — all operations work without Internet, no feature blocked by network absence, connection status indicator
FR-032: Automatic sync — auto-sync on connectivity return, conflict handling, progress indicator, auto-retry, zero data loss

### NonFunctional Requirements

NFR-001: Offline performance — all operations < 500ms offline (sale < 500ms, product search < 300ms, screen navigation < 200ms)
NFR-002: Mid-range device support — smooth on 2GB RAM Android, memory < 150MB, APK < 50MB
NFR-003: Zero data loss — 100% offline transactions recovered after sync, retry on failure
NFR-004: Sync conflict resolution — automatic per entity type (LWW for master data, additive merge for movements), no user intervention
NFR-005: Backend availability — 99% uptime (Supabase + Railway), app fully functional offline during outages
NFR-006: Secure authentication — JWT via Supabase Auth, access token 1h, refresh token 7d, secure storage
NFR-007: Local data encryption — SQLite encrypted via SQLCipher (AES-256), key in flutter_secure_storage
NFR-008: Permission isolation — sellers cannot access financial reports, modify prices, or manage users; enforced client + server + RLS
NFR-009: Accessible interface — minimum 48x48dp touch targets, 2-tap max navigation, icons with text labels, no complex gestures for critical actions
NFR-010: French language — all UI text, error messages, notifications in French; FCFA currency; French number formatting
NFR-011: Fast onboarding — shop setup + first product in < 5 minutes, 4-step guided wizard
NFR-012: Multi-platform — Android 8.0+, iOS 13+, Desktop Windows 10+ / macOS 11+ via Flutter
NFR-013: Standard REST API — NestJS with versioned endpoints (/api/v1/), JSON responses, auto-generated Swagger/OpenAPI docs
NFR-014: Test coverage — > 70% on critical business logic (pricing, stock, cash, sync)
NFR-015: Responsive interface — 3 breakpoints (mobile < 600dp, tablet 600-1024dp, desktop > 1024dp), adaptive navigation

### Additional Requirements

**From Architecture:**
- Drift (SQLite) as local database with DAOs, type-safe queries, versioned migrations
- SQLCipher for local encryption
- Riverpod for state management with providers per domain
- Sync Engine with persistent operation queue (SyncOperation table), push/pull pattern, conflict resolution per entity type
- NestJS modular monolith with 12 business modules (Auth, Shop, Product, Stock, Sale, Cash, Expense, Order, Report, Supplier, Notification, Sync)
- Prisma ORM for PostgreSQL access
- Supabase Auth for JWT management + Row Level Security
- Firebase Cloud Messaging (FCM) for push notifications
- UUID primary keys everywhere (sync-compatible)
- shopId on every table for data isolation
- Repository pattern abstracting local + remote data sources
- CI/CD: GitHub Actions → flutter analyze + test + build, backend test + deploy to Railway
- Firebase App Distribution for tester APK delivery
- Sentry for crash reporting (Flutter + NestJS)

### FR Coverage Map

{{requirements_coverage_map}}

## Epic List

{{epics_list}}
