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
import '../canvas/structs/canvas_scaffold.dart';
import '../canvas/structs/canvas_app_bar.dart';
import '../canvas/structs/canvas_bottom_nav.dart';
import '../canvas/state/canvas_state_wrapper.dart';
import '../canvas/wrappers/pull_to_refresh.dart';
import '../canvas/wrappers/canvas_pagination.dart';
import '../canvas/wrappers/canvas_semantics.dart';
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
    r.register('Slots', (c, ctx) => CanvasSlots.fromConfig(c, ctx));
    r.register('Stack', (c, ctx) => CanvasStack.fromConfig(c, ctx));
    r.register('StateWrapper', (c, ctx) => CanvasStateWrapper.fromConfig(c, ctx));
    r.register('PullToRefresh', (c, ctx) => CanvasPullToRefresh.fromConfig(c, ctx));
    r.register('Pagination', (c, ctx) => CanvasPagination.fromConfig(c, ctx));
    r.register('Semantics', (c, ctx) => CanvasSemantics.fromConfig(c, ctx));

    // Data Display
    r.register('KPICard', (c, ctx) => KPICard.fromConfig(c, ctx));
    r.register('DataTable', (c, ctx) => ScalarioDataTable.fromConfig(c, ctx));
    r.register('ChartWidget', (c, ctx) => ChartBar.fromConfig(c, ctx));
    r.register('ChartBar', (c, ctx) => ChartBar.fromConfig(c, ctx));
    r.register('ChartPie', (c, ctx) => ChartPie.fromConfig(c, ctx));
    r.register('StatCard', (c, ctx) => StatCard.fromConfig(c, ctx));

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

    // Lists
    r.register('MouvementItem', (c, ctx) => ScalarioListTile.fromConfig(c, ctx));
    r.register('TicketPreview', (c, ctx) => ScalarioListTile.fromConfig(c, ctx));
    r.register('DocumentPreview', (c, ctx) => DocumentPreview.fromConfig(c, ctx));
  }
}
