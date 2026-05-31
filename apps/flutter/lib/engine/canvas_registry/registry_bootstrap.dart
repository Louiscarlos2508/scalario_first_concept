import '../../components/actions/scalario_button.dart';
import '../../components/actions/scalario_fab.dart';
import '../../components/data_display/chart_bar.dart';
import '../../components/data_display/chart_pie.dart';
import '../../components/data_display/document_preview.dart';
import '../../components/data_display/kpi_card.dart';
import '../../components/data_display/scalario_data_table.dart';
import '../../components/data_display/stat_card.dart';
import '../../components/feedback/alert_banner.dart';
import '../../components/inputs/form_section.dart';
import '../../components/lists/scalario_list_tile.dart';
import '../../features/sync/sync_status_bar.dart';
import '../canvas/layouts/canvas_grid.dart';
import '../canvas/layouts/canvas_row.dart';
import '../canvas/layouts/canvas_column.dart';
import '../canvas/layouts/canvas_slots.dart';
import '../canvas/layouts/canvas_stack.dart';
import '../canvas/structs/canvas_accordion.dart';
import '../canvas/structs/canvas_badge.dart';
import '../canvas/structs/canvas_card.dart';
import '../canvas/structs/canvas_checkbox.dart';
import '../canvas/structs/canvas_dropdown.dart';
import '../canvas/structs/canvas_gauge.dart';
import '../canvas/structs/canvas_heading.dart';
import '../canvas/structs/canvas_input.dart';
import '../canvas/structs/canvas_media.dart';
import '../canvas/structs/canvas_slider.dart';
import '../canvas/structs/canvas_tabs.dart';
import '../canvas/structs/canvas_text.dart';
import '../canvas/structs/canvas_toggle.dart';
import '../canvas/structs/canvas_scaffold.dart';
import '../canvas/structs/canvas_app_bar.dart';
import '../canvas/structs/canvas_sidebar.dart';
import '../canvas/structs/canvas_bottom_nav.dart';
import '../canvas/state/canvas_state_wrapper.dart';
import '../canvas/wrappers/pull_to_refresh.dart';
import '../canvas/wrappers/canvas_pagination.dart';
import '../canvas/wrappers/canvas_semantics.dart';
import '../canvas/wrappers/canvas_gesture.dart';
import '../canvas/wrappers/canvas_sheet_dialog.dart';
import '../canvas/wrappers/canvas_transition.dart';
import '../canvas/wrappers/canvas_offline_keyboard_print.dart';
import 'component_schemas.dart';
import 'scalario_canvas_registry.dart';

abstract final class RegistryBootstrap {
  static void registerPhase1(ScalarioCanvasRegistry r) {
    // Layout containers
    r.register('Scaffold', (c, ctx) => CanvasScaffold.fromConfig(c, ctx), schema: ComponentSchemas.scaffold);
    r.register('AppBar', (c, ctx) => CanvasAppBar.fromConfig(c, ctx), schema: ComponentSchemas.appBar);
    r.register('Sidebar', (c, ctx) => CanvasSidebar.fromConfig(c, ctx), schema: ComponentSchemas.sidebar);
    r.register('BottomNav', (c, ctx) => CanvasBottomNav.fromConfig(c, ctx), schema: ComponentSchemas.bottomNav);
    r.register('Grid', (c, ctx) => CanvasGrid.fromConfig(c, ctx), schema: ComponentSchemas.grid);
    r.register('Row', (c, ctx) => CanvasRow.fromConfig(c, ctx), schema: ComponentSchemas.row);
    r.register('Column', (c, ctx) => CanvasColumn.fromConfig(c, ctx), schema: ComponentSchemas.column);
    r.register('Card', (c, ctx) => CanvasCard.fromConfig(c, ctx), schema: ComponentSchemas.card);
    r.register('Text', (c, ctx) => CanvasText.fromConfig(c, ctx), schema: ComponentSchemas.text);
    r.register('Slots', (c, ctx) => CanvasSlots.fromConfig(c, ctx), schema: ComponentSchemas.slots);
    r.register('Stack', (c, ctx) => CanvasStack.fromConfig(c, ctx), schema: ComponentSchemas.stack);
    r.register('Accordion', (c, ctx) => CanvasAccordion.fromConfig(c, ctx), schema: ComponentSchemas.accordion);
    r.register('Tabs', (c, ctx) => CanvasTabs.fromConfig(c, ctx), schema: ComponentSchemas.tabs);
    r.register('StateWrapper', (c, ctx) => CanvasStateWrapper.fromConfig(c, ctx), schema: ComponentSchemas.stateWrapper);
    r.register('PullToRefresh', (c, ctx) => CanvasPullToRefresh.fromConfig(c, ctx), schema: ComponentSchemas.pullToRefresh);
    r.register('Pagination', (c, ctx) => CanvasPagination.fromConfig(c, ctx), schema: ComponentSchemas.pagination);
    r.register('Semantics', (c, ctx) => CanvasSemantics.fromConfig(c, ctx), schema: ComponentSchemas.semantics);
    r.register('Gesture', (c, ctx) => CanvasGesture.fromConfig(c, ctx), schema: ComponentSchemas.gesture);
    r.register('SheetDialog', (c, ctx) => CanvasSheetDialog.fromConfig(c, ctx), schema: ComponentSchemas.sheetDialog);
    r.register('Transition', (c, ctx) => CanvasTransition.fromConfig(c, ctx), schema: ComponentSchemas.transition);
    r.register('Print', (c, ctx) => CanvasPrint.fromConfig(c, ctx), schema: ComponentSchemas.print_);

    // Data Display
    r.register('KPICard', (c, ctx) => KPICard.fromConfig(c, ctx), schema: ComponentSchemas.kpiCard);
    r.register('DataTable', (c, ctx) => ScalarioDataTable.fromConfig(c, ctx), schema: ComponentSchemas.dataTable);
    r.register('ChartWidget', (c, ctx) => ChartBar.fromConfig(c, ctx));
    r.register('ChartBar', (c, ctx) => ChartBar.fromConfig(c, ctx), schema: ComponentSchemas.chartBar);
    r.register('ChartPie', (c, ctx) => ChartPie.fromConfig(c, ctx), schema: ComponentSchemas.chartPie);
    r.register('StatCard', (c, ctx) => StatCard.fromConfig(c, ctx), schema: ComponentSchemas.statCard);
    r.register('Gauge', (c, ctx) => CanvasGauge.fromConfig(c, ctx), schema: ComponentSchemas.gauge);
    r.register('Heading', (c, ctx) => CanvasHeading.fromConfig(c, ctx), schema: ComponentSchemas.heading);
    r.register('Media', (c, ctx) => CanvasMedia.fromConfig(c, ctx), schema: ComponentSchemas.media);
    r.register('Badge', (c, ctx) => CanvasBadge.fromConfig(c, ctx), schema: ComponentSchemas.badge);

    // Feedback
    r.register('AlertBanner', (c, ctx) => AlertBanner.fromConfig(c, ctx), schema: ComponentSchemas.alertBanner);
    r.register('SyncStatusBar', (c, ctx) => SyncStatusBar.fromConfig(c, ctx), schema: ComponentSchemas.syncStatusBar);

    // Actions
    r.register('ScalarioButton', (c, ctx) => ScalarioButton.fromConfig(c, ctx), schema: ComponentSchemas.scalarioButton);
    r.register('Button', (c, ctx) => ScalarioButton.fromConfig(c, ctx));
    r.register('ActionButton', (c, ctx) => ScalarioFAB.fromConfig(c, ctx));
    r.register('FAB', (c, ctx) => ScalarioFAB.fromConfig(c, ctx), schema: ComponentSchemas.scalarioFab);

    // Inputs
    r.register('FormWidget', (c, ctx) => FormSection.fromConfig(c, ctx));
    r.register('FormSection', (c, ctx) => FormSection.fromConfig(c, ctx), schema: ComponentSchemas.formSection);
    r.register('Input', (c, ctx) => CanvasInput.fromConfig(c, ctx), schema: ComponentSchemas.input);
    r.register('TextInput', (c, ctx) => CanvasInput.fromConfig(c, ctx));
    r.register('NumberInput', (c, ctx) => CanvasInput.fromConfig(c, ctx));
    r.register('Dropdown', (c, ctx) => CanvasDropdown.fromConfig(c, ctx), schema: ComponentSchemas.dropdown);
    r.register('Select', (c, ctx) => CanvasDropdown.fromConfig(c, ctx));
    r.register('Checkbox', (c, ctx) => CanvasCheckbox.fromConfig(c, ctx), schema: ComponentSchemas.checkbox);
    r.register('Toggle', (c, ctx) => CanvasToggle.fromConfig(c, ctx), schema: ComponentSchemas.toggle);
    r.register('Switch', (c, ctx) => CanvasToggle.fromConfig(c, ctx));
    r.register('Slider', (c, ctx) => CanvasSlider.fromConfig(c, ctx), schema: ComponentSchemas.slider);

    // Lists
    r.register('MouvementItem', (c, ctx) => ScalarioListTile.fromConfig(c, ctx));
    r.register('TicketPreview', (c, ctx) => ScalarioListTile.fromConfig(c, ctx));
    r.register('DocumentPreview', (c, ctx) => DocumentPreview.fromConfig(c, ctx), schema: ComponentSchemas.documentPreview);
  }

  /// Enregistre les alias A2UI pour la compatibilité ascendante.
  ///
  /// Mappe les noms A2UI (versionnés v0.8, v0.9, v1.0) vers les types
  /// Scalario correspondants.
  static void registerAliases(ScalarioCanvasRegistry r) {
    // v0.8 — A2UI names → Scalario types
    r.registerAlias('a2ui:heading_v0.8', 'Heading');
    r.registerAlias('a2ui:text_v0.8', 'Text');
    r.registerAlias('a2ui:card_v0.8', 'Card');
    r.registerAlias('a2ui:grid_v0.8', 'Grid');
    r.registerAlias('a2ui:row_v0.8', 'Row');
    r.registerAlias('a2ui:column_v0.8', 'Column');
    r.registerAlias('a2ui:button_v0.8', 'Button');
    r.registerAlias('a2ui:input_v0.8', 'Input');
    r.registerAlias('a2ui:slider_v0.8', 'Slider');
    r.registerAlias('a2ui:toggle_v0.8', 'Toggle');
    r.registerAlias('a2ui:checkbox_v0.8', 'Checkbox');
    r.registerAlias('a2ui:dropdown_v0.8', 'Dropdown');
    r.registerAlias('a2ui:tabs_v0.8', 'Tabs');
    r.registerAlias('a2ui:badge_v0.8', 'Badge');
    r.registerAlias('a2ui:media_v0.8', 'Media');
    r.registerAlias('a2ui:accordion_v0.8', 'Accordion');
    r.registerAlias('a2ui:stack_v0.8', 'Stack');
    r.registerAlias('a2ui:scaffold_v0.8', 'Scaffold');

    // v0.9 — names stabilisés
    r.registerAlias('a2ui:heading_v0.9', 'Heading');
    r.registerAlias('a2ui:text_v0.9', 'Text');
    r.registerAlias('a2ui:card_v0.9', 'Card');
    r.registerAlias('a2ui:grid_v0.9', 'Grid');
    r.registerAlias('a2ui:row_v0.9', 'Row');
    r.registerAlias('a2ui:column_v0.9', 'Column');
    r.registerAlias('a2ui:button_v0.9', 'Button');
    r.registerAlias('a2ui:input_v0.9', 'Input');
    r.registerAlias('a2ui:slider_v0.9', 'Slider');
    r.registerAlias('a2ui:toggle_v0.9', 'Toggle');
    r.registerAlias('a2ui:checkbox_v0.9', 'Checkbox');
    r.registerAlias('a2ui:dropdown_v0.9', 'Dropdown');
    r.registerAlias('a2ui:tabs_v0.9', 'Tabs');
    r.registerAlias('a2ui:badge_v0.9', 'Badge');
    r.registerAlias('a2ui:media_v0.9', 'Media');
    r.registerAlias('a2ui:accordion_v0.9', 'Accordion');
    r.registerAlias('a2ui:stack_v0.9', 'Stack');
    r.registerAlias('a2ui:scaffold_v0.9', 'Scaffold');

    // v1.0 — names courts sans préfixe
    r.registerAlias('a2ui:heading_v1.0', 'Heading');
    r.registerAlias('a2ui:text_v1.0', 'Text');
    r.registerAlias('a2ui:card_v1.0', 'Card');
    r.registerAlias('a2ui:grid_v1.0', 'Grid');
    r.registerAlias('a2ui:row_v1.0', 'Row');
    r.registerAlias('a2ui:column_v1.0', 'Column');
    r.registerAlias('a2ui:button_v1.0', 'Button');
    r.registerAlias('a2ui:input_v1.0', 'Input');
    r.registerAlias('a2ui:slider_v1.0', 'Slider');
    r.registerAlias('a2ui:toggle_v1.0', 'Toggle');
    r.registerAlias('a2ui:checkbox_v1.0', 'Checkbox');
    r.registerAlias('a2ui:dropdown_v1.0', 'Dropdown');
    r.registerAlias('a2ui:tabs_v1.0', 'Tabs');
    r.registerAlias('a2ui:badge_v1.0', 'Badge');
    r.registerAlias('a2ui:media_v1.0', 'Media');
    r.registerAlias('a2ui:accordion_v1.0', 'Accordion');
    r.registerAlias('a2ui:stack_v1.0', 'Stack');
    r.registerAlias('a2ui:scaffold_v1.0', 'Scaffold');
  }
}
