# Story 15.4 — UI French Labels — Backoffice

## Metadata
- **Epic:** Epic 15 — SDUI Dashboard & UI Polish
- **Story ID:** 15-4-ui-french-labels-backoffice
- **Status:** review
- **Priority:** High
- **Depends on:** aucun (parallélisable avec 15-3)

---

## Story

**As an** owner or manager using Scalario backoffice,
**I want** all dashboard, inventory, customers, categories, and reports screens to be in French with FCFA currency and AppTheme colors,
**So that** the entire backoffice is consistent with the design system (Français d'abord, zéro couleur hardcodée).

---

## Acceptance Criteria

1. **Dashboard Overview (`dashboard_screen.dart` — `OverviewScreen`)** labels translated:
   - "Dashboard Overview" → **"Tableau de bord"**
   - "Welcome back!" → **"Bienvenue !"**
   - "Total Revenue" → **"Chiffre d'affaires"**
   - "Order Count" → **"Transactions"**
   - "Avg. Ticket" → **"Ticket moyen"**
   - "Revenue Trends (Last 7 Days)" → **"Ventes des 7 derniers jours"**
   - "Active Terminals" → **"Caisses actives"**
   - "Last 7 Days" (date picker button) → **"7 derniers jours"**
   - "No terminals active yet" → **"Aucune caisse active"**
   - "Start a POS terminal to see it here" → **"Ouvrez une session caisse pour l'afficher ici"**
   - "Last seen:" → **"Vu à :"**
   - "ONLINE" / "OFFLINE" → **"EN LIGNE"** / **"HORS LIGNE"**

2. **AppTheme color tokens — `dashboard_screen.dart`** — all hardcoded colors replaced:
   - `Colors.green` (stat card icon, terminal online) → `AppColors.success`
   - `Colors.blue` (stat card icon) → `AppColors.primary`
   - `Colors.purple` (stat card icon) → `AppColors.primary` (or nearest semantic token)
   - `Colors.teal` (chart line color) → `AppColors.primary`
   - `Colors.teal.withOpacity(0.1)` (chart fill) → `AppColors.primary.withOpacity(0.1)`
   - `Colors.grey.*` (borders, text) → `AppColors.border` / `AppColors.textSecondary`
   - `Colors.white` (container background) → `AppColors.surface`
   - `Colors.green.shade50/.shade100` → `AppColors.success.withOpacity(0.1)`

3. **Currency** — All `\$` and `USD` in dashboard/backoffice screens replaced by **`FCFA`**. Use `NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)`.

4. **Inventory screen (`inventory_screen.dart`)** labels:
   - "Inventory" → **"Inventaire"**
   - "Add Product" → **"Ajouter un produit"**
   - "Search..." → **"Rechercher..."**
   - "Stock:" → **"Stock :"**
   - "Edit" → **"Modifier"**
   - "Delete" → **"Supprimer"**
   - "Low stock" → **"Stock faible"**
   - "Out of stock" → **"Rupture"**

5. **Categories screen (`categories_screen.dart`)** labels:
   - "Categories" → **"Catégories"**
   - "Add Category" → **"Nouvelle catégorie"**
   - "Category name" → **"Nom de la catégorie"**

6. **Customers screen (`customers_screen.dart`)** labels:
   - "Customers" → **"Clients"**
   - "Add Customer" → **"Nouveau client"**
   - "Name", "Phone" → **"Nom"**, **"Téléphone"**
   - "Balance:" → **"Solde :"**
   - "Credit limit" → **"Limite de crédit"**

7. **Reports screen (`reports_screen.dart`)** labels:
   - "Reports" → **"Rapports"**
   - "Daily Report" → **"Rapport journalier"**
   - "Session Report" → **"Rapport de caisse"**
   - "Export" → **"Exporter"**

8. **Settings placeholder** — "Settings" → **"Paramètres"**, "System Settings Coming Soon" → **"Paramètres à venir"**.

9. **No regression** — All existing tests pass.

---

## Tasks/Subtasks

- [x] **Task 1: Translate `dashboard_screen.dart` — labels + AppTheme tokens**
  - [x] All AC1 labels
  - [x] All AC2 color replacements (requires `AppColors` import)
  - [x] Currency format AC3

- [x] **Task 2: Translate `inventory_screen.dart`**
  - [x] All AC4 labels + FCFA

- [x] **Task 3: Translate `categories_screen.dart`**
  - [x] All AC5 labels

- [x] **Task 4: Translate `customers_screen.dart`**
  - [x] All AC6 labels + FCFA

- [x] **Task 5: Translate `reports_screen.dart`**
  - [x] All AC7 labels

- [x] **Task 6: Translate settings placeholder in `dashboard_screen.dart`** per AC8

- [x] **Task 7: Run `flutter test` — zero errors/regressions**

---

## Dev Notes

### File Inventory (all files to modify)

```
apps/frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart
apps/frontend/lib/features/dashboard/presentation/screens/inventory_screen.dart
apps/frontend/lib/features/dashboard/presentation/screens/categories_screen.dart
apps/frontend/lib/features/dashboard/presentation/screens/customers_screen.dart
apps/frontend/lib/features/dashboard/presentation/screens/reports_screen.dart
apps/frontend/lib/features/dashboard/presentation/screens/stock_history_screen.dart
```

### AppColors Token Mapping

Before starting, read `lib/core/theme/app_theme.dart` to confirm exact token names. Expected mapping based on `docs/design-system.md`:

| Hardcoded | Token |
|-----------|-------|
| `Colors.green` / `Colors.green.shade*` | `AppColors.success` (`#2E7D32`) |
| `Colors.blue` | `AppColors.primary` (`#1565C0`) |
| `Colors.teal` | `AppColors.primary` |
| `Colors.purple` | `AppColors.primary` |
| `Colors.grey.shade200` (borders) | `AppColors.border` |
| `Colors.grey.shade600` (text) | `AppColors.textSecondary` |
| `Colors.white` (surface) | `AppColors.surface` |
| `Colors.red` | `AppColors.error` (`#C62828`) |

### Note on Story 15-1/15-2 interaction

If Story 15-1 and 15-2 are merged before 15-4, `OverviewScreen` body will already be `SduiRenderer` — the AC1 label changes apply only to `AppBar` title and date picker button label. The `_buildStatCard`, `_buildSalesChart`, `TerminalsStatusWidget` section translations will have been moved into the SDUI widgets (Story 15-2). Coordinate with 15-2 dev to avoid duplicate work.

---

## File List

| Action | Path |
|--------|------|
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/inventory_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/categories_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/customers_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/reports_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/stock_history_screen.dart` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story created — French labels, FCFA, and AppTheme tokens for all backoffice screens |
| 2026-03-15 | Implementation complete — 6 backoffice screens translated to French + FCFA + AppTheme tokens, `stock_history_screen.dart` also translated, 63/63 tests green |
