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
import 'scalario_canvas_registry.dart';

abstract final class RegistryBootstrap {
  static void registerPhase1(ScalarioCanvasRegistry r) {
    r.register('KPICard', (c, ctx) => KPICard.fromConfig(c, ctx));
    r.register('DataTable', (c, ctx) => ScalarioDataTable.fromConfig(c, ctx));
    r.register('ChartWidget', (c, ctx) => ChartBar.fromConfig(c, ctx));
    r.register('ChartBar', (c, ctx) => ChartBar.fromConfig(c, ctx));
    r.register('ChartPie', (c, ctx) => ChartPie.fromConfig(c, ctx));

    r.register('AlertBanner', (c, ctx) => AlertBanner.fromConfig(c, ctx));

    r.register('ScalarioButton', (c, ctx) => ScalarioButton.fromConfig(c, ctx));
    r.register('Button', (c, ctx) => ScalarioButton.fromConfig(c, ctx));
    r.register('ActionButton', (c, ctx) => ScalarioFAB.fromConfig(c, ctx));
    r.register('FAB', (c, ctx) => ScalarioFAB.fromConfig(c, ctx));

    r.register('FormWidget', (c, ctx) => FormSection.fromConfig(c, ctx));
    r.register('FormSection', (c, ctx) => FormSection.fromConfig(c, ctx));

    r.register('MouvementItem', (c, ctx) => ScalarioListTile.fromConfig(c, ctx));
    r.register('TicketPreview', (c, ctx) => ScalarioListTile.fromConfig(c, ctx));

    r.register('StatCard', (c, ctx) => StatCard.fromConfig(c, ctx));
    r.register('SyncStatusBar', (c, ctx) => SyncStatusBar.fromConfig(c, ctx));
    r.register('DocumentPreview', (c, ctx) => DocumentPreview.fromConfig(c, ctx));
  }
}
