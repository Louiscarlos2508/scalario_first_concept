# Scalario SDUI JSON Schema

**Version:** 1
**Status:** Canonical contract — backend serves, Flutter client renders.

Server-Driven UI (SDUI) allows Scalario to adapt screen layouts per `business_type`
without a client app release. The backend returns a layout descriptor; the Flutter
renderer builds the widget tree from it.

---

## Top-Level Envelope

Every layout response is a single JSON object with this shape:

```json
{
  "version": "1",
  "business_type": "retail",
  "screen": "pos",
  "layout": { ... }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | `string` | ✅ | Schema version. Currently `"1"`. |
| `business_type` | `string` | ✅ | Vertical identifier. Values: `"retail"`, `"pharmacy"` (future), `"school"` (future). |
| `screen` | `string` | ✅ | Screen identifier within the vertical. Values: `"pos"`, `"dashboard"`, `"inventory"`. |
| `layout` | `Layout` | ✅ | Root layout descriptor (see below). |

---

## Layout Object

The `layout` object describes how the screen is structured. It always has a `type`
that determines which widget to render.

```json
{
  "type": "split_view",
  "breakpoints": { ... },
  "panels": { ... }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `string` | ✅ | Layout type. See **Layout Types** below. |
| `breakpoints` | `BreakpointMap` | optional | Per-breakpoint overrides when `type` is `"split_view"`. |
| `panels` | `PanelMap` | optional | Named panel descriptors for split-view layouts. |

---

## Layout Types

| `type` | Description | Used on |
|--------|-------------|---------|
| `split_view` | Root adaptive layout. Delegates to `breakpoints` for sub-layout per screen size. | POS, Dashboard |
| `stacked_with_fab_cart` | **Compact only.** Product grid fills screen; FAB badge shows cart item count; tapping FAB opens cart as full-screen modal. | POS compact |
| `horizontal_split` | **Tablet/Desktop.** Two panels side-by-side. `left_flex` / `right_flex` set relative widths. | POS medium/expanded |
| `dashboard_scroll` | **Dashboard.** Vertical scrollable column of widget sections. | Dashboard |

### `split_view` Breakpoints

```json
"breakpoints": {
  "compact":  { "type": "stacked_with_fab_cart" },
  "medium":   { "type": "horizontal_split", "left_flex": 2, "right_flex": 1 },
  "expanded": { "type": "horizontal_split", "left_flex": 3, "right_flex": 1 }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `compact` | `SubLayout` | Applied when `width < 600px`. |
| `medium` | `SubLayout` | Applied when `600px ≤ width < 1024px`. |
| `expanded` | `SubLayout` | Applied when `width ≥ 1024px`. |

Breakpoint thresholds match `app_breakpoints.dart`: `kCompact = 600`, `kMedium = 1024`.

---

## Panel Types

Panels are the building blocks placed inside `panels` (for split-view) or `sections`
(for dashboard-scroll). Each panel has a `type` and type-specific configuration.

### `product_grid`

Filterable product grid with category chip strip above.

```json
{
  "type": "product_grid",
  "columns": { "compact": 2, "medium": 3, "expanded": 5 },
  "show_categories": true,
  "show_search": true
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | `"product_grid"` | — | Panel type identifier. |
| `columns` | `BreakpointInt` | `{compact:2,medium:3,expanded:5}` | Grid column count per breakpoint. |
| `show_categories` | `boolean` | `true` | Show horizontal category chip strip above grid. |
| `show_search` | `boolean` | `true` | Show product search field. |

### `cart_panel`

Cart item list with running total and a primary checkout action.

```json
{
  "type": "cart_panel",
  "primary_action": {
    "type": "filled_button",
    "label": "ENCAISSER",
    "action": "checkout",
    "min_height": 56
  },
  "payment_methods": ["CASH", "MOBILE_MONEY", "CARD", "CREDIT", "SPLIT"]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | `"cart_panel"` | Panel type identifier. |
| `primary_action` | `ButtonDescriptor` | The main CTA button (see below). |
| `payment_methods` | `string[]` | Ordered list of available payment methods. Values: `CASH`, `MOBILE_MONEY`, `CARD`, `CREDIT`, `SPLIT`. |

#### `ButtonDescriptor`

| Field | Type | Description |
|-------|------|-------------|
| `type` | `"filled_button"` \| `"elevated_button"` \| `"text_button"` | Material 3 button variant. |
| `label` | `string` | Button label text. |
| `action` | `string` | Action identifier dispatched on tap (e.g. `"checkout"`). |
| `min_height` | `number` | Minimum height in dp. Fitts law: primary CTA ≥ 56dp. |

### `kpi_card_grid`

Grid of key-performance-indicator cards. Miller's law: max 6 cards.

```json
{
  "type": "kpi_card_grid",
  "cards": [
    {
      "icon": "attach_money",
      "label": "Ventes du jour",
      "value_provider": "daily_revenue"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | `"kpi_card_grid"` | Panel type identifier. |
| `cards` | `KpiCard[]` | Array of card descriptors. Max 6 (Miller's law). |

#### `KpiCard`

| Field | Type | Description |
|-------|------|-------------|
| `icon` | `string` | Material icon name (e.g. `"attach_money"`, `"inventory_2"`). |
| `label` | `string` | Card title text. |
| `value_provider` | `string` | Data key the renderer resolves to a live value. See **Value Providers** below. |

### `line_chart`

Time-series line chart for trend visualization.

```json
{
  "type": "line_chart",
  "title": "Ventes des 7 derniers jours",
  "data_provider": "weekly_sales_series"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | `"line_chart"` | Panel type identifier. |
| `title` | `string` | Chart title. |
| `data_provider` | `string` | Data key the renderer resolves to `List<{x, y}>`. |

### `terminal_status_list`

List of POS terminals with their last-sync status.

```json
{
  "type": "terminal_status_list",
  "title": "État des caisses"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | `"terminal_status_list"` | Panel type identifier. |
| `title` | `string` | Section header. |

---

## Value Providers

Value providers are string keys that the Flutter renderer resolves to live data
via repository/provider calls. They decouple the layout contract from the data layer.

| Key | Type | Description |
|-----|------|-------------|
| `daily_revenue` | `double` | Today's total sales amount. |
| `daily_transactions` | `int` | Today's transaction count. |
| `active_customers` | `int` | Customers with active credit. |
| `low_stock_count` | `int` | Products below reorder threshold. |
| `weekly_sales_series` | `List<{x:date, y:double}>` | 7-day sales trend data. |
| `terminal_sessions` | `List<TerminalStatus>` | POS terminal sync states. |

---

## SduiPlaceholder — Unknown Type Fallback

**Rule:** The Flutter renderer MUST NEVER crash on an unknown panel type.

When the renderer encounters a `type` not in its registry, it renders `SduiPlaceholder`:

```
┌─────────────────────────────┐
│  [?]  Unknown widget        │
│       type: "xyz_widget"    │
└─────────────────────────────┘
```

This is a grey rounded-corner box showing the unknown `type` value for debugging.
It allows the backend to ship new panel types before the client app is updated,
without causing crashes (graceful degradation).

**Implementation contract (for Story 10-4):**

```dart
// In the Flutter renderer widget registry:
Widget buildPanel(Map<String, dynamic> panel) {
  return switch (panel['type']) {
    'product_grid' => ProductGridPanel(panel),
    'cart_panel'   => CartPanelWidget(panel),
    'kpi_card_grid'        => KpiCardGrid(panel),
    'line_chart'           => LineChartPanel(panel),
    'terminal_status_list' => TerminalStatusList(panel),
    _              => SduiPlaceholder(type: panel['type']),  // never crashes
  };
}
```

---

## Complete Layout Examples

### `retail.pos` layout

See: `apps/backend/src/sdui/layouts/retail.pos.json`

### `retail.dashboard` layout

See: `apps/backend/src/sdui/layouts/retail.dashboard.json`

---

## Versioning

- `version: "1"` — initial schema, stable for Epics 10-12.
- On breaking changes, bump to `"2"` and maintain backward-compat for 1 release cycle.
- Non-breaking additions (new optional fields, new panel types) do NOT require version bump.
