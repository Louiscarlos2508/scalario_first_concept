import 'component_schema.dart';

/// Tous les schémas de composants BDUI Scalario.
///
/// Chaque schéma décrit les propriétés exactes extraites du widget
/// correspondant dans [build()] / [fromConfig()].
abstract final class ComponentSchemas {
  static final Map<String, ComponentSchema> all = {
    for (final s in _all) s.type: s,
  };

  static final List<ComponentSchema> _all = [
    // ── Layouts ──────────────────────────────────────────────────────
    scaffold,
    appBar,
    sidebar,
    bottomNav,
    grid,
    row,
    column,
    card,
    text,
    slots,
    stack,

    // ── Structure ────────────────────────────────────────────────────
    accordion,
    tabs,
    stateWrapper,
    pullToRefresh,
    pagination,
    semantics,
    gesture,
    sheetDialog,
    transition,
    print_,

    // ── Data Display ─────────────────────────────────────────────────
    kpiCard,
    dataTable,
    chartBar,
    chartPie,
    statCard,
    gauge,
    heading,
    media,
    badge,
    documentPreview,

    // ── Feedback ─────────────────────────────────────────────────────
    alertBanner,
    syncStatusBar,

    // ── Actions ──────────────────────────────────────────────────────
    scalarioButton,
    scalarioFab,

    // ── Inputs ───────────────────────────────────────────────────────
    formSection,
    input,
    dropdown,
    checkbox,
    toggle,
    slider,

    // ── Lists ────────────────────────────────────────────────────────
    listTile,
  ];

  // ═══════════════════════════════════════════════════════════════════
  // Layouts
  // ═══════════════════════════════════════════════════════════════════

  static const scaffold = ComponentSchema(
    type: 'Scaffold',
    props: [
      PropDefinition(name: 'appBar', type: PropType.object, description: 'AppBar child config'),
      PropDefinition(name: 'body', type: PropType.object, description: 'Body child config'),
      PropDefinition(name: 'bottomNav', type: PropType.object, description: 'Bottom navigation child config'),
      PropDefinition(name: 'sidebar', type: PropType.object, description: 'Sidebar child config (desktop)'),
      PropDefinition(name: 'drawer', type: PropType.object, description: 'Drawer child config (mobile)'),
    ],
    description: 'Page scaffolding with optional AppBar, sidebar, bottom nav and drawer',
  );

  static const appBar = ComponentSchema(
    type: 'AppBar',
    props: [
      PropDefinition(name: 'title', type: PropType.string, required: true, description: 'AppBar title text'),
      PropDefinition(name: 'actions', type: PropType.list, description: 'List of action widget configs'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Top application bar with title and optional action buttons',
  );

  static const sidebar = ComponentSchema(
    type: 'Sidebar',
    props: [
      PropDefinition(name: 'items', type: PropType.list, required: true, description: 'List of {label, icon} navigation items'),
      PropDefinition(name: 'currentIndex', type: PropType.number, defaultValue: 0, description: 'Index of the active navigation item'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Vertical navigation sidebar for desktop layouts',
  );

  static const bottomNav = ComponentSchema(
    type: 'BottomNav',
    props: [
      PropDefinition(name: 'items', type: PropType.list, required: true, description: 'List of {icon, label} navigation items'),
      PropDefinition(name: 'currentIndex', type: PropType.number, defaultValue: 0, description: 'Index of the active tab'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Bottom navigation bar for mobile layouts',
  );

  static const grid = ComponentSchema(
    type: 'Grid',
    props: [
      PropDefinition(name: 'gap', type: PropType.number, defaultValue: 8, description: 'Spacing between grid items'),
      PropDefinition(name: 'columns', type: PropType.number, defaultValue: 2, description: 'Number of columns'),
      PropDefinition(name: 'responsive', type: PropType.object, description: 'Responsive breakpoint overrides {mobile, tablet, desktop → {columns}}'),
    ],
    description: 'Responsive grid layout with configurable columns and gap',
  );

  static const row = ComponentSchema(
    type: 'Row',
    props: [
      PropDefinition(name: 'gap', type: PropType.number, defaultValue: 8, description: 'Spacing between children'),
    ],
    description: 'Horizontal row layout',
  );

  static const column = ComponentSchema(
    type: 'Column',
    props: [
      PropDefinition(name: 'gap', type: PropType.number, defaultValue: 8, description: 'Spacing between children'),
    ],
    description: 'Vertical column layout',
  );

  static const card = ComponentSchema(
    type: 'Card',
    props: [
      PropDefinition(name: 'header', type: PropType.object, description: 'Header child config'),
      PropDefinition(name: 'footer', type: PropType.object, description: 'Footer child config'),
      PropDefinition(name: 'body', type: PropType.object, description: 'Body child config'),
    ],
    description: 'Material card with optional header, body and footer slots',
  );

  static const text = ComponentSchema(
    type: 'Text',
    props: [
      PropDefinition(name: 'text', type: PropType.string, description: 'Text content (alias for label)'),
      PropDefinition(name: 'label', type: PropType.string, description: 'Text content'),
      PropDefinition(name: 'style', type: PropType.string, description: 'Typography style key (body, h1, h2, caption, kpi, kpiLabel)'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Styled text display',
  );

  static const slots = ComponentSchema(
    type: 'Slots',
    props: [
      PropDefinition(name: 'slots', type: PropType.object, required: true, description: 'Named slots map {main, aside, banner}'),
    ],
    description: 'Named slot container with main, aside, and banner positions',
  );

  static const stack = ComponentSchema(
    type: 'Stack',
    props: [
      PropDefinition(name: 'position', type: PropType.string, description: 'Stack alignment (topLeft, center, bottomRight, etc.)'),
      PropDefinition(name: 'padding', type: PropType.number, description: 'Padding around children'),
      PropDefinition(name: 'margin', type: PropType.number, description: 'Margin around children'),
    ],
    description: 'Stacked layout for overlapping children',
  );

  // ═══════════════════════════════════════════════════════════════════
  // Structure
  // ═══════════════════════════════════════════════════════════════════

  static const accordion = ComponentSchema(
    type: 'Accordion',
    props: [
      PropDefinition(name: 'expanded', type: PropType.bool, defaultValue: false, description: 'Whether the accordion is initially expanded'),
      PropDefinition(name: 'title', type: PropType.string, description: 'Accordion header title'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Accordion header text'),
      PropDefinition(name: 'icon', type: PropType.string, description: 'Icon name for the header'),
    ],
    description: 'Collapsible accordion panel',
  );

  static const tabs = ComponentSchema(
    type: 'Tabs',
    props: [
      PropDefinition(name: 'current', type: PropType.number, defaultValue: 0, description: 'Index of the active tab'),
      PropDefinition(name: 'tabs', type: PropType.list, required: true, description: 'List of {label, icon} tab definitions'),
    ],
    description: 'Tabbed container with selectable tabs',
  );

  static const stateWrapper = ComponentSchema(
    type: 'StateWrapper',
    props: [
      PropDefinition(name: 'states', type: PropType.object, required: true, description: 'Named child configs for each state: {loading, empty, error}'),
      PropDefinition(name: '_source_data', type: PropType.path, description: 'Data source path for state resolution'),
      PropDefinition(name: '_loading', type: PropType.bool, defaultValue: false, description: 'When true renders the loading state'),
      PropDefinition(name: '_error', type: PropType.string, description: 'Error message — when non-null renders the error state'),
    ],
    description: 'State-driven wrapper that renders loading, empty, error or default child based on data state',
  );

  static const pullToRefresh = ComponentSchema(
    type: 'PullToRefresh',
    props: [],
    description: 'Pull-to-refresh wrapper — no props, delegates entirely to child',
  );

  static const pagination = ComponentSchema(
    type: 'Pagination',
    props: [],
    description: 'Pagination wrapper — renders children and manages page state',
  );

  static const semantics = ComponentSchema(
    type: 'Semantics',
    props: [
      PropDefinition(name: 'label', type: PropType.string, description: 'Accessibility label'),
      PropDefinition(name: 'hint', type: PropType.string, description: 'Accessibility hint'),
      PropDefinition(name: 'button', type: PropType.bool, defaultValue: false, description: 'Whether this is a button'),
      PropDefinition(name: 'header', type: PropType.bool, defaultValue: false, description: 'Whether this is a header'),
      PropDefinition(name: 'exclude_semantics', type: PropType.bool, defaultValue: false, description: 'Exclude from accessibility'),
    ],
    description: 'Accessibility semantics wrapper',
  );

  static const gesture = ComponentSchema(
    type: 'Gesture',
    props: [
      PropDefinition(name: 'gestures', type: PropType.object, description: 'Gesture action map {swipe_left, swipe_right, long_press → action}'),
    ],
    description: 'Gesture detector wrapper for swipe and long-press',
  );

  static const sheetDialog = ComponentSchema(
    type: 'SheetDialog',
    props: [
      PropDefinition(name: 'title', type: PropType.string, description: 'Dialog title'),
      PropDefinition(name: 'message', type: PropType.string, description: 'Dialog message body'),
    ],
    description: 'Bottom sheet or dialog wrapper triggered by gestures or actions',
  );

  static const transition = ComponentSchema(
    type: 'Transition',
    props: [
      PropDefinition(name: 'transition', type: PropType.string, defaultValue: 'fade', allowedValues: ['slide', 'fade', 'scale'], description: 'Transition animation type'),
    ],
    description: 'Animated transition wrapper with slide, fade, or scale effects',
  );

  static const print_ = ComponentSchema(
    type: 'Print',
    props: [
      PropDefinition(name: 'show_stale_badge', type: PropType.bool, defaultValue: false, description: 'Show stale data indicator'),
      PropDefinition(name: 'disable_actions', type: PropType.bool, defaultValue: false, description: 'Disable all interactive actions'),
      PropDefinition(name: 'keyboard', type: PropType.string, description: 'Keyboard visibility hint'),
      PropDefinition(name: 'sync_action', type: PropType.action, description: 'Action triggered on sync request'),
    ],
    description: 'Offline keyboard/print wrapper with stale data badge and sync support',
  );

  // ═══════════════════════════════════════════════════════════════════
  // Data Display
  // ═══════════════════════════════════════════════════════════════════

  static const kpiCard = ComponentSchema(
    type: 'KPICard',
    props: [
      PropDefinition(name: 'label', type: PropType.string, description: 'KPI label text'),
      PropDefinition(name: 'value', type: PropType.string, description: 'Primary value'),
      PropDefinition(name: 'unit', type: PropType.string, description: 'Unit suffix (FCFA, %, etc.)'),
      PropDefinition(name: 'delta', type: PropType.number, description: 'Change indicator value'),
      PropDefinition(name: 'delta_positive', type: PropType.bool, description: 'Whether delta direction is positive'),
      PropDefinition(name: 'status', type: PropType.string, allowedValues: ['nominal', 'warning', 'critical'], description: 'Visual status variant'),
      PropDefinition(name: 'icon', type: PropType.string, description: 'Icon name'),
      PropDefinition(name: 'variant', type: PropType.string, description: 'Visual variant key'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Descriptive text'),
      PropDefinition(name: 'action', type: PropType.action, description: 'Tap action'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Key Performance Indicator card with value, delta, icon and optional action',
  );

  static const dataTable = ComponentSchema(
    type: 'DataTable',
    props: [
      PropDefinition(name: 'columns', type: PropType.list, required: true, description: 'Column definitions with header, width, alignment'),
      PropDefinition(name: 'rows', type: PropType.list, required: true, description: 'Row data — list of data path references or inline values'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Data table with configurable columns and dynamic row data',
  );

  static const chartBar = ComponentSchema(
    type: 'ChartBar',
    props: [
      PropDefinition(name: 'title', type: PropType.string, description: 'Chart title'),
      PropDefinition(name: 'data', type: PropType.list, description: 'Bar data points'),
      PropDefinition(name: 'unit', type: PropType.string, description: 'Unit label'),
      PropDefinition(name: 'period', type: PropType.string, description: 'Time period label'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Bar chart component',
  );

  static const chartPie = ComponentSchema(
    type: 'ChartPie',
    props: [
      PropDefinition(name: 'title', type: PropType.string, description: 'Chart title'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Pie / donut chart component',
  );

  static const statCard = ComponentSchema(
    type: 'StatCard',
    props: [
      PropDefinition(name: 'label', type: PropType.string, description: 'Stat label'),
      PropDefinition(name: 'value', type: PropType.string, description: 'Stat value'),
      PropDefinition(name: 'delta', type: PropType.number, description: 'Change indicator'),
      PropDefinition(name: 'delta_positive', type: PropType.bool, description: 'Whether delta is positive'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Simple stat card with value and optional delta',
  );

  static const gauge = ComponentSchema(
    type: 'Gauge',
    props: [
      PropDefinition(name: 'label', type: PropType.string, description: 'Gauge label'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Display text inside gauge'),
      PropDefinition(name: 'value', type: PropType.number, required: true, description: 'Current value'),
      PropDefinition(name: 'min', type: PropType.number, defaultValue: 0, description: 'Minimum value'),
      PropDefinition(name: 'max', type: PropType.number, defaultValue: 100, description: 'Maximum value'),
      PropDefinition(name: 'suffix', type: PropType.string, description: 'Value suffix'),
      PropDefinition(name: 'variant', type: PropType.string, description: 'Color variant'),
      PropDefinition(name: 'color', type: PropType.string, description: 'Specific color override'),
      PropDefinition(name: 'height', type: PropType.number, description: 'Gauge height'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Radial or linear gauge with value range',
  );

  static const heading = ComponentSchema(
    type: 'Heading',
    props: [
      PropDefinition(name: 'title', type: PropType.string, description: 'Heading title text'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Subtitle or secondary text'),
      PropDefinition(name: 'subtitle', type: PropType.string, description: 'Subtitle text'),
      PropDefinition(name: 'icon', type: PropType.string, description: 'Leading icon name'),
      PropDefinition(name: 'divider', type: PropType.bool, defaultValue: false, description: 'Show divider below heading'),
      PropDefinition(name: 'level', type: PropType.number, defaultValue: 1, description: 'Heading level (1-3)'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Section heading with title, optional subtitle, icon and divider',
  );

  static const media = ComponentSchema(
    type: 'Media',
    props: [
      PropDefinition(name: 'type', type: PropType.string, description: 'Media type hint (image, avatar, icon, placeholder)'),
      PropDefinition(name: 'icon', type: PropType.string, description: 'Icon name'),
      PropDefinition(name: 'label', type: PropType.string, description: 'Label / alt text'),
      PropDefinition(name: 'size', type: PropType.number, description: 'Media size'),
      PropDefinition(name: 'color', type: PropType.string, description: 'Color override'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Media display (icon, avatar, image placeholder)',
  );

  static const badge = ComponentSchema(
    type: 'Badge',
    props: [
      PropDefinition(name: 'label', type: PropType.string, description: 'Badge label content'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Badge text'),
      PropDefinition(name: 'color', type: PropType.string, description: 'Background color'),
      PropDefinition(name: 'variant', type: PropType.string, description: 'Visual variant (filled, outline, subtle)'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Status badge with color and variant support',
  );

  static const documentPreview = ComponentSchema(
    type: 'DocumentPreview',
    props: [
      PropDefinition(name: 'title', type: PropType.string, description: 'Document title'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Document preview card with title and metadata',
  );

  // ═══════════════════════════════════════════════════════════════════
  // Feedback
  // ═══════════════════════════════════════════════════════════════════

  static const alertBanner = ComponentSchema(
    type: 'AlertBanner',
    props: [
      PropDefinition(name: 'type', type: PropType.string, required: true, allowedValues: ['success', 'warning', 'danger', 'info'], description: 'Alert severity type'),
      PropDefinition(name: 'message', type: PropType.string, required: true, description: 'Alert message text'),
      PropDefinition(name: 'action_label', type: PropType.string, description: 'Call-to-action button label'),
      PropDefinition(name: 'auto_dismiss_ms', type: PropType.number, description: 'Auto-dismiss after milliseconds'),
      PropDefinition(name: 'on_dismiss', type: PropType.action, description: 'Action triggered on dismiss'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Contextual alert banner with severity type, message and optional action',
  );

  static const syncStatusBar = ComponentSchema(
    type: 'SyncStatusBar',
    props: [
      PropDefinition(name: 'variant', type: PropType.string, description: 'Status variant (syncing, online, offline, error)'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Sync status indicator bar (syncing / online / offline / error)',
  );

  // ═══════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════

  static const scalarioButton = ComponentSchema(
    type: 'Button',
    props: [
      PropDefinition(name: 'label', type: PropType.string, description: 'Button label text'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Button text (alias for label)'),
      PropDefinition(name: 'variant', type: PropType.string, defaultValue: 'primary', allowedValues: ['primary', 'secondary', 'danger', 'ghost', 'icon-only'], description: 'Button variant'),
      PropDefinition(name: 'icon', type: PropType.string, description: 'Leading icon name'),
      PropDefinition(name: 'action', type: PropType.action, description: 'Tap action'),
      PropDefinition(name: 'enabled', type: PropType.bool, defaultValue: true, description: 'Whether the button is interactive'),
      PropDefinition(name: 'loading', type: PropType.bool, defaultValue: false, description: 'Show loading spinner'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Action button with variant, icon, loading and action support',
  );

  static const scalarioFab = ComponentSchema(
    type: 'FAB',
    props: [
      PropDefinition(name: 'icon', type: PropType.string, description: 'FAB icon name'),
      PropDefinition(name: 'label', type: PropType.string, description: 'Extended FAB label'),
      PropDefinition(name: 'action', type: PropType.action, description: 'Tap action'),
      PropDefinition(name: 'loading', type: PropType.bool, defaultValue: false, description: 'Show loading state'),
      PropDefinition(name: 'hero_tag', type: PropType.string, description: 'Hero animation tag for page transitions'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Floating action button with optional extended label and hero animation',
  );

  // ═══════════════════════════════════════════════════════════════════
  // Inputs
  // ═══════════════════════════════════════════════════════════════════

  static const formSection = ComponentSchema(
    type: 'FormSection',
    props: [
      PropDefinition(name: 'title', type: PropType.string, description: 'Form section title'),
      PropDefinition(name: 'hint', type: PropType.string, description: 'Form section hint text'),
      PropDefinition(name: 'errors', type: PropType.list, description: 'List of validation error strings'),
      PropDefinition(name: 'loading', type: PropType.bool, defaultValue: false, description: 'Show loading state'),
    ],
    description: 'Form section wrapper with title, hint, errors and loading state',
  );

  static const input = ComponentSchema(
    type: 'Input',
    props: [
      PropDefinition(name: 'value', type: PropType.string, description: 'Current input value'),
      PropDefinition(name: 'label', type: PropType.string, description: 'Input label text'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Input text (alias for label)'),
      PropDefinition(name: 'hint', type: PropType.string, description: 'Placeholder hint text'),
      PropDefinition(name: 'type', type: PropType.string, defaultValue: 'text', allowedValues: ['text', 'password', 'number', 'numeric', 'money'], description: 'Input type variant'),
      PropDefinition(name: 'required', type: PropType.bool, defaultValue: false, description: 'Mark as required with asterisk'),
      PropDefinition(name: 'prefix', type: PropType.string, description: 'Prefix text'),
      PropDefinition(name: 'suffix', type: PropType.string, description: 'Suffix text'),
      PropDefinition(name: 'readonly', type: PropType.bool, defaultValue: false, description: 'Read-only mode'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Text / password / number / money input field with label and validation',
  );

  static const dropdown = ComponentSchema(
    type: 'Dropdown',
    props: [
      PropDefinition(name: 'value', type: PropType.string, description: 'Selected value'),
      PropDefinition(name: 'label', type: PropType.string, description: 'Dropdown label text'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Dropdown text (alias for label)'),
      PropDefinition(name: 'hint', type: PropType.string, description: 'Placeholder hint'),
      PropDefinition(name: 'options', type: PropType.list, required: true, description: 'List of {value, label} option objects'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Dropdown / select input with labeled options',
  );

  static const checkbox = ComponentSchema(
    type: 'Checkbox',
    props: [
      PropDefinition(name: 'checked', type: PropType.bool, defaultValue: false, description: 'Whether the checkbox is checked'),
      PropDefinition(name: 'label', type: PropType.string, description: 'Checkbox label text'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Checkbox text (alias for label)'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Checkbox input with label',
  );

  static const toggle = ComponentSchema(
    type: 'Toggle',
    props: [
      PropDefinition(name: 'active', type: PropType.bool, defaultValue: false, description: 'Whether the toggle is active'),
      PropDefinition(name: 'label', type: PropType.string, description: 'Toggle label text'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Toggle text (alias for label)'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Toggle / switch input with label',
  );

  static const slider = ComponentSchema(
    type: 'Slider',
    props: [
      PropDefinition(name: 'value', type: PropType.number, defaultValue: 0, description: 'Current slider value'),
      PropDefinition(name: 'label', type: PropType.string, description: 'Slider label text'),
      PropDefinition(name: 'text', type: PropType.string, description: 'Slider text (alias for label)'),
      PropDefinition(name: 'min', type: PropType.number, defaultValue: 0, description: 'Minimum value'),
      PropDefinition(name: 'max', type: PropType.number, defaultValue: 100, description: 'Maximum value'),
      PropDefinition(name: 'divisions', type: PropType.number, description: 'Number of discrete divisions'),
      PropDefinition(name: 'showValue', type: PropType.bool, defaultValue: false, description: 'Display current value next to slider'),
      PropDefinition(name: 'suffix', type: PropType.string, description: 'Value suffix text'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'Range slider with optional discrete divisions and value display',
  );

  // ═══════════════════════════════════════════════════════════════════
  // Lists
  // ═══════════════════════════════════════════════════════════════════

  static const listTile = ComponentSchema(
    type: 'ListTile',
    props: [
      PropDefinition(name: 'leading', type: PropType.object, description: 'Leading widget config (icon, avatar, etc.)'),
      PropDefinition(name: 'title', type: PropType.string, description: 'Primary title text'),
      PropDefinition(name: 'subtitle', type: PropType.string, description: 'Secondary subtitle text'),
      PropDefinition(name: 'trailing', type: PropType.object, description: 'Trailing widget config (badge, icon, etc.)'),
      PropDefinition(name: 'on_tap', type: PropType.action, description: 'Tap action'),
      PropDefinition(name: 'enabled', type: PropType.bool, defaultValue: true, description: 'Whether the tile is interactive'),
      PropDefinition(name: 'status', type: PropType.string, description: 'Status indicator (success, warning, danger, info)'),
    ],
    minChildren: 0,
    maxChildren: 0,
    description: 'List tile with leading content, title, subtitle, trailing content and optional action',
  );
}
