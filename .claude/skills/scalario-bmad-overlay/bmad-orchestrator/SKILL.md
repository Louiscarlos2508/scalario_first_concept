---
name: scalario-bmad-overlay
description: >
  Scalario project overlay for the BMAD Method. Scalario is a multi-vertical ERP platform
  that starts with retail/boutique management and will expand to pharmacies, schools,
  multi-department enterprises, and more. This skill enriches every BMAD agent and workflow
  with Scalario-specific context: multi-tenant multi-vertical architecture, offline-first POS,
  Flutter + NestJS + Supabase stack, and domain knowledge for the retail vertical.
  Trigger this skill alongside any BMAD command (/prd, /architecture, /sprint-planning,
  /dev-story, etc.) when working on Scalario. Also trigger when the user mentions "Scalario",
  "POS", "ERP", "module", "tenant", "vertical", "métier", "boutique", "stock", "caisse",
  "offline", "sync", "reorganize", "refactor", "new vertical", or discusses any aspect of
  the Scalario product. This overlay does NOT replace BMAD — it adds project-specific
  guardrails, conventions, and domain knowledge on top of it.
---

# Scalario BMAD Overlay

This skill works **on top of** the installed BMAD Method. Read this file first, then
proceed with the standard BMAD workflow. Reference files in `references/` when you
need detailed guidance.

## What is Scalario

Scalario is a **multi-vertical ERP platform** for African and emerging market businesses.
The platform provides a shared core (auth, tenants, users, stock, sales, cash management)
with **vertical adapters** that customize behavior per business type.

### The Big Picture

```
SCALARIO PLATFORM
┌─────────────────────────────────────────────────────────┐
│  @scalario/kernel (shared across ALL verticals)         │
│  ├── auth, tenant, org, user, roles & permissions       │
│  ├── plugin-registry (which vertical + modules active)  │
│  ├── event-bus (cross-module communication)             │
│  └── sync engine (offline-first infrastructure)         │
├─────────────────────────────────────────────────────────┤
│  SHARED BUSINESS MODULES (used by multiple verticals)   │
│  ├── @scalario/stock       → inventory, movements       │
│  ├── @scalario/sales       → POS, invoicing, receipts   │
│  ├── @scalario/cash        → cash register, closing     │
│  ├── @scalario/purchasing  → supplier orders, receiving  │
│  ├── @scalario/reporting   → dashboards, notifications  │
│  └── @scalario/contacts    → customers, suppliers       │
├─────────────────────────────────────────────────────────┤
│  VERTICAL ADAPTERS (business-type-specific logic)       │
│  ├── @scalario/vertical-retail     ← CURRENT FOCUS      │
│  │   ├── grocery (épicerie — Blandine)                  │
│  │   ├── cosmetics (cosmétique/beauté)                  │
│  │   └── beverages (boissons et divers)                 │
│  ├── @scalario/vertical-pharmacy   ← FUTURE             │
│  ├── @scalario/vertical-school     ← FUTURE             │
│  └── @scalario/vertical-enterprise ← FUTURE             │
└─────────────────────────────────────────────────────────┘
```

### Key Insight: Vertical Adapters, Not Separate Apps

A vertical adapter does NOT duplicate shared modules. It:
1. **Configures** shared modules (e.g., stock module gets "shrinkage rate" config for grocery)
2. **Extends** with domain-specific entities (e.g., bulk-to-sachet conversion for spices)
3. **Customizes** workflows (e.g., quality notes on receiving for perishables)
4. **Defines** roles and permissions specific to the business type

Example: The stock module handles inventory for ALL verticals. But the grocery vertical
adapter adds: freshness color codes (green/orange/red), shrinkage tolerance coefficients,
and bulk-to-unit conversion logic. The cosmetics vertical doesn't need any of that.

## Current State & Clients

### Active Clients (Retail Vertical)
1. **Blandine** — Épicerie fine (fruits, légumes, épices)
   - Needs: bulk→sachet conversion, shrinkage rates, freshness tracking, quality notes
   - Roles: Propriétaire, Gestionnaire (magasin), Commerciaux (rayons)
   - Key flow: Fournisseur → Magasin → Rayon → Vente → Clôture caisse

2. **Client 2** — Cosmétique et beauté
   - Needs: product variants (sizes, colors), expiry dates, margin tracking
   - Roles: TBD

3. **Client 3** — Boissons et divers
   - Needs: batch tracking, deposit/consignment management, volume discounts
   - Roles: TBD

### What ALL retail clients share
- Stock management (in/out/transfer/loss)
- Point of sale (cash register)
- Daily cash closing and reconciliation
- Supplier ordering and receiving
- Role-based access (owner, manager, salespeople)
- Offline-first operation
- Owner dashboard with daily summary

## Architecture Principles

Read `references/erp-architecture.md` for the full technical design.

1. **Kernel + Shared Modules + Vertical Adapters:** Three-layer architecture.
   Kernel provides infrastructure. Shared modules provide business logic common
   to multiple verticals. Vertical adapters customize for specific business types.

2. **Multi-Tenant + Multi-Vertical:** Each tenant has a `tenant_id` AND a
   `vertical_type` (e.g., 'retail-grocery', 'retail-cosmetics'). The vertical
   determines which adapter loads and how shared modules behave.

3. **Configuration over Code:** Differences between boutique types should be
   handled by configuration when possible, not by separate code paths.
   Example: "Has shrinkage rate?" is a stock module config flag, not an if/else.

4. **Module Communication via Events:** Modules never import each other.
   `stock.level.critical` → triggers alert. `sales.order.completed` → triggers
   stock decrement and cash entry.

5. **Offline-First for Field Operations:** POS and stock operations must work
   offline. Reporting and admin can be online-only.

6. **Simplicity for End Users:** Users like Blandine's team are not tech-savvy.
   Every screen must be usable with minimal training. Big buttons, clear labels,
   confirmation before destructive actions.

## BMAD Agent Enrichment

When any BMAD agent runs on Scalario, apply these context injections:

### For Business Analyst (/product-brief)
- Identify which **vertical** and **sub-type** the feature targets
- Map to existing shared modules — does this need a new module or extend one?
- Check: is this feature vertical-specific or shared across verticals?
- Identify real user personas (Propriétaire, Gestionnaire, Commercial, etc.)
- Consider the tech literacy of end users

### For Product Manager (/prd)
- Requirements must specify: which module + which vertical adapter (if any)
- User flows must cover: online path, offline path, sync-back path
- Include role-based access for each action
- Reference `references/scalario-conventions.md` for templates

### For Architect (/architecture)
- Follow the Kernel → Shared Module → Vertical Adapter pattern
- New features go in shared modules when 2+ verticals need them
- Vertical-specific logic goes in the adapter, NEVER in shared modules
- Design Event Bus contracts for cross-module effects
- Reference `references/erp-architecture.md`

### For Scrum Master (/sprint-planning, /create-story)
- Stories specify their target: kernel, shared module, or vertical adapter
- Story ordering: kernel → shared module → vertical adapter → frontend
- Reference `references/scalario-conventions.md` for story templates

### For Developer (/dev-story)
- Follow file structure conventions strictly
- Every entity: `tenant_id` + `created_by` + `sync_version` + soft delete
- Every endpoint: JWT + TenantGuard + ModuleActiveGuard + DTO validation
- Frontend: Repository pattern, local-first writes, offline indicators

## Scalario Solutioning Gate (Extended)

Before any feature moves to implementation, verify:

1. [ ] Feature is assigned to correct layer (kernel / shared module / vertical adapter)
2. [ ] If shared module: works for ALL current verticals, not just one
3. [ ] If vertical adapter: does NOT modify shared module internals
4. [ ] Cross-module communication uses events, not direct imports
5. [ ] New tables have `tenant_id`, RLS policy, `sync_version`
6. [ ] Offline behavior defined (or explicitly marked "online-only" with justification)
7. [ ] Sync conflict resolution specified for offline entities
8. [ ] Role-based access defined for every action (who can do what)
9. [ ] UI is simple enough for non-tech users (big targets, clear labels, confirmations)
10. [ ] Adding a new vertical later would NOT require changes to this feature
11. [ ] No cross-module database joins (use events or kernel shared data)
12. [ ] Daily summary / notifications are considered (owner wants evening reports)

## File References

| File | When to read |
|------|-------------|
| `references/erp-architecture.md` | Designing modules, restructuring, new verticals |
| `references/scalario-conventions.md` | Writing stories, implementing code, naming |
| `references/design-system.md` | UI/UX, components, platform adaptations |
| `references/retail-vertical.md` | Working on the retail/boutique vertical specifically |
