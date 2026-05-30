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
import '../canvas/structs/canvas_bottom_nav.dart';
import '../canvas/state/canvas_state_wrapper.dart';
import '../canvas/wrappers/pull_to_refresh.dart';
import '../canvas/wrappers/canvas_pagination.dart';
import '../canvas/wrappers/canvas_semantics.dart';
import '../canvas/wrappers/canvas_gesture.dart';
import '../canvas/wrappers/canvas_sheet_dialog.dart';
import '../canvas/wrappers/canvas_transition.dart';
import '../canvas/wrappers/canvas_offline_keyboard_print.dart';
import 'scalario_canvas_registry.dart';

abstract final class RegistryBootstrap {
  static void registerPhase1(ScalarioCanvasRegistry r) {
    // Layout containers
    r.register('Scaffold', (c, ctx) => CanvasScaffold.fromConfig(c, ctx));
    r.register('AppBar', (c, ctx) => CanvasAppBar.fromConfig(c, ctx));
    r.register('BottomNav', (c, ctx) => CanvasBottomNav.fromConfig(c, ctx));
    r.register('Grid', (c, ctx) => CanvasGrid.fromConfig(c, ctx));
    r.register('Row', (c, ctx) => CanvasRow.fromConfig(c, ctx));
    r.register('Column', (c, ctx) => CanvasColumn.fromConfig(c, ctx));
    r.register('Card', (c, ctx) => CanvasCard.fromConfig(c, ctx));
    r.register('Text', (c, ctx) => CanvasText.fromConfig(c, ctx));
    r.register('Slots', (c, ctx) => CanvasSlots.fromConfig(c, ctx));
    r.register('Stack', (c, ctx) => CanvasStack.fromConfig(c, ctx));
    r.register('Accordion', (c, ctx) => CanvasAccordion.fromConfig(c, ctx));
    r.register('Tabs', (c, ctx) => CanvasTabs.fromConfig(c, ctx));
    r.register('StateWrapper', (c, ctx) => CanvasStateWrapper.fromConfig(c, ctx));
    r.register('PullToRefresh', (c, ctx) => CanvasPullToRefresh.fromConfig(c, ctx));
    r.register('Pagination', (c, ctx) => CanvasPagination.fromConfig(c, ctx));
    r.register('Semantics', (c, ctx) => CanvasSemantics.fromConfig(c, ctx));
    r.register('Gesture', (c, ctx) => CanvasGesture.fromConfig(c, ctx));
    r.register('SheetDialog', (c, ctx) => CanvasSheetDialog.fromConfig(c, ctx));
    r.register('Transition', (c, ctx) => CanvasTransition.fromConfig(c, ctx));
    r.register('Print', (c, ctx) => CanvasPrint.fromConfig(c, ctx));

    // Data Display
    r.register('KPICard', (c, ctx) => KPICard.fromConfig(c, ctx));
    r.register('DataTable', (c, ctx) => ScalarioDataTable.fromConfig(c, ctx));
    r.register('ChartWidget', (c, ctx) => ChartBar.fromConfig(c, ctx));
    r.register('ChartBar', (c, ctx) => ChartBar.fromConfig(c, ctx));
    r.register('ChartPie', (c, ctx) => ChartPie.fromConfig(c, ctx));
    r.register('StatCard', (c, ctx) => StatCard.fromConfig(c, ctx));
    r.register('Gauge', (c, ctx) => CanvasGauge.fromConfig(c, ctx));
    r.register('Heading', (c, ctx) => CanvasHeading.fromConfig(c, ctx));
    r.register('Media', (c, ctx) => CanvasMedia.fromConfig(c, ctx));
    r.register('Badge', (c, ctx) => CanvasBadge.fromConfig(c, ctx));

    // Feedback
    r.register('AlertBanner', (c, ctx) => AlertBanner.fromConfig(c, ctx));
    r.register('SyncStatusBar', (c, ctx) => SyncStatusBar.fromConfig(c, ctx));

    // Actions
    r.register('ScalarioButton', (c, ctx) => ScalarioButton.fromConfig(c, ctx));
    r.register('Button', (c, ctx) => ScalarioButton.fromConfig(c, ctx));
    r.register('ActionButton', (c, ctx) => ScalarioFAB.fromConfig(c, ctx));
    r.register('FAB', (c, ctx) => ScalarioFAB.fromConfig(c, ctx));

    // Inputs
    r.register('FormWidget', (c, ctx) => FormSection.fromConfig(c, ctx));
    r.register('FormSection', (c, ctx) => FormSection.fromConfig(c, ctx));
    r.register('Input', (c, ctx) => CanvasInput.fromConfig(c, ctx));
    r.register('TextInput', (c, ctx) => CanvasInput.fromConfig(c, ctx));
    r.register('NumberInput', (c, ctx) => CanvasInput.fromConfig(c, ctx));
    r.register('Dropdown', (c, ctx) => CanvasDropdown.fromConfig(c, ctx));
    r.register('Select', (c, ctx) => CanvasDropdown.fromConfig(c, ctx));
    r.register('Checkbox', (c, ctx) => CanvasCheckbox.fromConfig(c, ctx));
    r.register('Toggle', (c, ctx) => CanvasToggle.fromConfig(c, ctx));
    r.register('Switch', (c, ctx) => CanvasToggle.fromConfig(c, ctx));
    r.register('Slider', (c, ctx) => CanvasSlider.fromConfig(c, ctx));

    // Lists
    r.register('MouvementItem', (c, ctx) => ScalarioListTile.fromConfig(c, ctx));
    r.register('TicketPreview', (c, ctx) => ScalarioListTile.fromConfig(c, ctx));
    r.register('DocumentPreview', (c, ctx) => DocumentPreview.fromConfig(c, ctx));
  }
}
