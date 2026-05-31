# Schémas de Composants BDUI Scalario

Généré depuis `lib/engine/canvas_registry/component_schemas.dart`.

## Types de Propriétés

| Type | Description |
|------|-------------|
| `string` | Texte |
| `number` | Valeur numérique |
| `bool` | Booléen |
| `list` | Liste/tableau |
| `object` | Map/objet JSON |
| `path` | Chemin de source de données (ex: `_data.user.name`) |
| `action` | Action BDUI (navigation, etc.) |
| `dynamic` | Type indéterministe |

## Scaffold

Page scaffolding with optional AppBar, sidebar, bottom nav and drawer.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `appBar` | `object` | no | AppBar child config |
| `body` | `object` | no | Body child config |
| `bottomNav` | `object` | no | Bottom navigation child config |
| `sidebar` | `object` | no | Sidebar child config (desktop) |
| `drawer` | `object` | no | Drawer child config (mobile) |

## AppBar

Top application bar with title and optional action buttons.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `title` | `string` | yes | AppBar title text |
| `actions` | `list` | no | List of action widget configs |

## Sidebar

Vertical navigation sidebar for desktop layouts.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `items` | `list` | yes | List of {label, icon} navigation items |
| `currentIndex` | `number` | no | Index of the active navigation item |

## BottomNav

Bottom navigation bar for mobile layouts.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `items` | `list` | yes | List of {icon, label} navigation items |
| `currentIndex` | `number` | no | Index of the active tab |

## Grid

Responsive grid layout with configurable columns and gap.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `gap` | `number` | no | Spacing between grid items |
| `columns` | `number` | no | Number of columns |
| `responsive` | `object` | no | Responsive breakpoint overrides {mobile, tablet, desktop → {columns}} |

## Row

Horizontal row layout.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `gap` | `number` | no | Spacing between children |

## Column

Vertical column layout.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `gap` | `number` | no | Spacing between children |

## Card

Material card with optional header, body and footer slots.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `header` | `object` | no | Header child config |
| `footer` | `object` | no | Footer child config |
| `body` | `object` | no | Body child config |

## Text

Styled text display.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `text` | `string` | no | Text content (alias for label) |
| `label` | `string` | no | Text content |
| `style` | `string` | no | Typography style key (body, h1, h2, caption, kpi, kpiLabel) |

## Slots

Named slot container with main, aside, and banner positions.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `slots` | `object` | yes | Named slots map {main, aside, banner} |

## Stack

Stacked layout for overlapping children.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `position` | `string` | no | Stack alignment (topLeft, center, bottomRight, etc.) |
| `padding` | `number` | no | Padding around children |
| `margin` | `number` | no | Margin around children |

## Accordion

Collapsible accordion panel.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `expanded` | `bool` | no | Whether the accordion is initially expanded |
| `title` | `string` | no | Accordion header title |
| `text` | `string` | no | Accordion header text |
| `icon` | `string` | no | Icon name for the header |

## Tabs

Tabbed container with selectable tabs.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `current` | `number` | no | Index of the active tab |
| `tabs` | `list` | yes | List of {label, icon} tab definitions |

## StateWrapper

State-driven wrapper that renders loading, empty, error or default child based on data state.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `states` | `object` | yes | Named child configs for each state: {loading, empty, error} |
| `_source_data` | `path` | no | Data source path for state resolution |
| `_loading` | `bool` | no | When true renders the loading state |
| `_error` | `string` | no | Error message — when non-null renders the error state |

## PullToRefresh

Pull-to-refresh wrapper — no props, delegates entirely to child.

_Aucune propriété._

## Pagination

Pagination wrapper — renders children and manages page state.

_Aucune propriété._

## Semantics

Accessibility semantics wrapper.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `label` | `string` | no | Accessibility label |
| `hint` | `string` | no | Accessibility hint |
| `button` | `bool` | no | Whether this is a button |
| `header` | `bool` | no | Whether this is a header |
| `exclude_semantics` | `bool` | no | Exclude from accessibility |

## Gesture

Gesture detector wrapper for swipe and long-press.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `gestures` | `object` | no | Gesture action map {swipe_left, swipe_right, long_press → action} |

## SheetDialog

Bottom sheet or dialog wrapper triggered by gestures or actions.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `title` | `string` | no | Dialog title |
| `message` | `string` | no | Dialog message body |

## Transition

Animated transition wrapper with slide, fade, or scale effects.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `transition` | `string` | no | Transition animation type |

## Print

Offline keyboard/print wrapper with stale data badge and sync support.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `show_stale_badge` | `bool` | no | Show stale data indicator |
| `disable_actions` | `bool` | no | Disable all interactive actions |
| `keyboard` | `string` | no | Keyboard visibility hint |
| `sync_action` | `action` | no | Action triggered on sync request |

## KPICard

Key Performance Indicator card with value, delta, icon and optional action.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `label` | `string` | no | KPI label text |
| `value` | `string` | no | Primary value |
| `unit` | `string` | no | Unit suffix (FCFA, %, etc.) |
| `delta` | `number` | no | Change indicator value |
| `delta_positive` | `bool` | no | Whether delta direction is positive |
| `status` | `string` | no | Visual status variant |
| `icon` | `string` | no | Icon name |
| `variant` | `string` | no | Visual variant key |
| `text` | `string` | no | Descriptive text |
| `action` | `action` | no | Tap action |

## DataTable

Data table with configurable columns and dynamic row data.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `columns` | `list` | yes | Column definitions with header, width, alignment |
| `rows` | `list` | yes | Row data — list of data path references or inline values |

## ChartBar

Bar chart component.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `title` | `string` | no | Chart title |
| `data` | `list` | no | Bar data points |
| `unit` | `string` | no | Unit label |
| `period` | `string` | no | Time period label |

## ChartPie

Pie / donut chart component.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `title` | `string` | no | Chart title |

## StatCard

Simple stat card with value and optional delta.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `label` | `string` | no | Stat label |
| `value` | `string` | no | Stat value |
| `delta` | `number` | no | Change indicator |
| `delta_positive` | `bool` | no | Whether delta is positive |

## Gauge

Radial or linear gauge with value range.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `label` | `string` | no | Gauge label |
| `text` | `string` | no | Display text inside gauge |
| `value` | `number` | yes | Current value |
| `min` | `number` | no | Minimum value |
| `max` | `number` | no | Maximum value |
| `suffix` | `string` | no | Value suffix |
| `variant` | `string` | no | Color variant |
| `color` | `string` | no | Specific color override |
| `height` | `number` | no | Gauge height |

## Heading

Section heading with title, optional subtitle, icon and divider.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `title` | `string` | no | Heading title text |
| `text` | `string` | no | Subtitle or secondary text |
| `subtitle` | `string` | no | Subtitle text |
| `icon` | `string` | no | Leading icon name |
| `divider` | `bool` | no | Show divider below heading |
| `level` | `number` | no | Heading level (1-3) |

## Media

Media display (icon, avatar, image placeholder).

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `type` | `string` | no | Media type hint (image, avatar, icon, placeholder) |
| `icon` | `string` | no | Icon name |
| `label` | `string` | no | Label / alt text |
| `size` | `number` | no | Media size |
| `color` | `string` | no | Color override |

## Badge

Status badge with color and variant support.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `label` | `string` | no | Badge label content |
| `text` | `string` | no | Badge text |
| `color` | `string` | no | Background color |
| `variant` | `string` | no | Visual variant (filled, outline, subtle) |

## DocumentPreview

Document preview card with title and metadata.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `title` | `string` | no | Document title |

## AlertBanner

Contextual alert banner with severity type, message and optional action.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `type` | `string` | yes | Alert severity type |
| `message` | `string` | yes | Alert message text |
| `action_label` | `string` | no | Call-to-action button label |
| `auto_dismiss_ms` | `number` | no | Auto-dismiss after milliseconds |
| `on_dismiss` | `action` | no | Action triggered on dismiss |

## SyncStatusBar

Sync status indicator bar (syncing / online / offline / error).

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `variant` | `string` | no | Status variant (syncing, online, offline, error) |

## Button

Action button with variant, icon, loading and action support.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `label` | `string` | no | Button label text |
| `text` | `string` | no | Button text (alias for label) |
| `variant` | `string` | no | Button variant |
| `icon` | `string` | no | Leading icon name |
| `action` | `action` | no | Tap action |
| `enabled` | `bool` | no | Whether the button is interactive |
| `loading` | `bool` | no | Show loading spinner |

## FAB

Floating action button with optional extended label and hero animation.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `icon` | `string` | no | FAB icon name |
| `label` | `string` | no | Extended FAB label |
| `action` | `action` | no | Tap action |
| `loading` | `bool` | no | Show loading state |
| `hero_tag` | `string` | no | Hero animation tag for page transitions |

## FormSection

Form section wrapper with title, hint, errors and loading state.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `title` | `string` | no | Form section title |
| `hint` | `string` | no | Form section hint text |
| `errors` | `list` | no | List of validation error strings |
| `loading` | `bool` | no | Show loading state |

## Input

Text / password / number / money input field with label and validation.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `value` | `string` | no | Current input value |
| `label` | `string` | no | Input label text |
| `text` | `string` | no | Input text (alias for label) |
| `hint` | `string` | no | Placeholder hint text |
| `type` | `string` | no | Input type variant |
| `required` | `bool` | no | Mark as required with asterisk |
| `prefix` | `string` | no | Prefix text |
| `suffix` | `string` | no | Suffix text |
| `readonly` | `bool` | no | Read-only mode |

## Dropdown

Dropdown / select input with labeled options.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `value` | `string` | no | Selected value |
| `label` | `string` | no | Dropdown label text |
| `text` | `string` | no | Dropdown text (alias for label) |
| `hint` | `string` | no | Placeholder hint |
| `options` | `list` | yes | List of {value, label} option objects |

## Checkbox

Checkbox input with label.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `checked` | `bool` | no | Whether the checkbox is checked |
| `label` | `string` | no | Checkbox label text |
| `text` | `string` | no | Checkbox text (alias for label) |

## Toggle

Toggle / switch input with label.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `active` | `bool` | no | Whether the toggle is active |
| `label` | `string` | no | Toggle label text |
| `text` | `string` | no | Toggle text (alias for label) |

## Slider

Range slider with optional discrete divisions and value display.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `value` | `number` | no | Current slider value |
| `label` | `string` | no | Slider label text |
| `text` | `string` | no | Slider text (alias for label) |
| `min` | `number` | no | Minimum value |
| `max` | `number` | no | Maximum value |
| `divisions` | `number` | no | Number of discrete divisions |
| `showValue` | `bool` | no | Display current value next to slider |
| `suffix` | `string` | no | Value suffix text |

## ListTile

List tile with leading content, title, subtitle, trailing content and optional action.

| Propriété | Type | Requis | Description |
|-----------|------|--------|-------------|
| `leading` | `object` | no | Leading widget config (icon, avatar, etc.) |
| `title` | `string` | no | Primary title text |
| `subtitle` | `string` | no | Secondary subtitle text |
| `trailing` | `object` | no | Trailing widget config (badge, icon, etc.) |
| `on_tap` | `action` | no | Tap action |
| `enabled` | `bool` | no | Whether the tile is interactive |
| `status` | `string` | no | Status indicator (success, warning, danger, info) |

---
Généré automatiquement par `tool/generate_component_docs.dart`.
