# Story 10.2 — SDUI JSON Schema Definition

## Metadata
- **Epic:** Epic 10 — SDUI Foundation & Engine
- **Story ID:** 10-2-sdui-json-schema-definition
- **Status:** done
- **Priority:** High
- **Depends on:** 10-1-design-system-theme-tokens (done)

---

## Story

**As a** developer,
**I want** a documented JSON schema for describing screen layouts per `business_type`,
**So that** backend and frontend have a shared contract before building either side.

---

## Acceptance Criteria

1. **Schema doc** — `docs/sdui-schema.md` documents the top-level schema with fields:
   `version`, `business_type`, `screen`, `layout` (with `type`, `breakpoints`, `panels`).

2. **POS layout JSON** — `apps/backend/src/sdui/layouts/retail.pos.json` is the first real layout
   encoding the retail POS screen per the design system (split view, product grid, cart panel).

3. **Dashboard layout JSON** — `apps/backend/src/sdui/layouts/retail.dashboard.json` covers
   `kpi_cards` (array with icon, label, value_provider), `line_chart` (data_provider, title),
   `terminal_status_list`.

4. **SduiPlaceholder** — schema documents that an unknown `"type"` renders a `SduiPlaceholder`
   and never crashes.

5. **No code** — this story delivers documentation and JSON config files only. No NestJS module,
   no Flutter renderer (those are stories 10-3 and 10-4).

---

## Tasks/Subtasks

- [x] **Task 1: Create `docs/sdui-schema.md`**
  - [x] Document top-level envelope fields (version, business_type, screen, layout)
  - [x] Document layout.type values (split_view, stacked_with_fab_cart, horizontal_split)
  - [x] Document breakpoints (compact/medium/expanded) with type + flex ratios
  - [x] Document panel types: product_grid, cart_panel, kpi_cards, line_chart, terminal_status_list
  - [x] Document SduiPlaceholder fallback for unknown types
  - [x] Include field-level documentation table for each object type

- [x] **Task 2: Create `apps/backend/src/sdui/layouts/retail.pos.json`**
  - [x] Encode split_view with compact/medium/expanded breakpoints
  - [x] Encode product_grid panel (columns per breakpoint, show_categories, show_search)
  - [x] Encode cart_panel with ENCAISSER FilledButton (min_height 56) and payment_methods

- [x] **Task 3: Create `apps/backend/src/sdui/layouts/retail.dashboard.json`**
  - [x] Encode kpi_cards array (icon, label, value_provider per card)
  - [x] Encode line_chart (data_provider, title)
  - [x] Encode terminal_status_list

- [x] **Task 4: Validate JSON files are well-formed**
  - [x] `node -e "JSON.parse(...)"` — both files parse cleanly

---

## Dev Notes

### Context

This story is **documentation + JSON config only**. No TypeScript/Dart code changes.

The SDUI schema defines a server-driven contract: the backend sends a JSON layout
descriptor to the Flutter client, which renders the appropriate widgets. The Flutter
renderer (Story 10-4) will consume these exact JSON files.

### Design Constraints (from design-system.md)

- Breakpoints: compact < 600px, medium 600-1024px, expanded > 1024px
- FilledButton primary CTA: min_height 56 (Fitts law)
- Product grid columns: 2 (compact), 3 (medium), 5 (expanded)
- Payment methods: CASH, MOBILE_MONEY, CARD, CREDIT, SPLIT
- Dashboard KPIs: max 6 cards (Miller's law)

### Panel type registry

| type | Description |
|------|-------------|
| `split_view` | Root layout with breakpoint-adaptive sub-layouts |
| `stacked_with_fab_cart` | Compact: product grid full-screen, FAB badge shows cart count |
| `horizontal_split` | Tablet/Desktop: side-by-side panels with flex ratios |
| `product_grid` | Filterable product grid with category chips |
| `cart_panel` | Cart items list + total + primary CTA |
| `kpi_card_grid` | Grid of metric cards |
| `line_chart` | Time-series chart |
| `terminal_status_list` | List of POS terminal sync statuses |
| `SduiPlaceholder` | Fallback for any unknown type — renders grey box, never crashes |

---

## Dev Agent Record

### Debug Log

Documentation-only story. No TypeScript/Dart code. dashboard layout uses `"sections"` array (not `"panels"`) matching the `dashboard_scroll` layout type — consistent with the schema definition.

### Completion Notes

- `docs/sdui-schema.md` — full schema with field tables for all 8 panel types + SduiPlaceholder + versioning policy
- `retail.pos.json` — complete POS layout (split_view → breakpoints → product_grid + cart_panel)
- `retail.dashboard.json` — complete dashboard layout (dashboard_scroll → 4 KPI cards + line_chart + terminal_status_list)
- Both JSON files validated with `node JSON.parse()` — no syntax errors
- No Flutter or NestJS code modified

---

## File List

| Action | Path |
|--------|------|
| Created | `docs/sdui-schema.md` |
| Created | `apps/backend/src/sdui/layouts/retail.pos.json` |
| Created | `apps/backend/src/sdui/layouts/retail.dashboard.json` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story implemented — SDUI schema doc + retail.pos.json + retail.dashboard.json |
