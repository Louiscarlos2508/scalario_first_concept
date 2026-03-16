import 'package:frontend/core/sdui/sdui_widget_registry.dart';
import 'package:frontend/features/retail/reports/presentation/widgets/kpi_card_grid.dart';
import 'package:frontend/features/retail/reports/presentation/widgets/line_chart_widget.dart';
import 'package:frontend/features/retail/reports/presentation/widgets/terminal_status_list.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_panel.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/product_grid.dart';

/// Registers all known SDUI panel types at app startup.
///
/// Call this once in [main] before [runApp].
/// Tests that render SDUI widgets must call this (or register stubs) in setUp.
void setupSduiRegistry() {
  SduiWidgetRegistry.register('product_grid', (_) => const ProductGrid());
  SduiWidgetRegistry.register('cart_panel', (_) => const CartPanel());
  SduiWidgetRegistry.register('kpi_card_grid', (_) => const KpiCardGrid());
  SduiWidgetRegistry.register(
    'line_chart',
    (props) => LineChartWidget(title: props['title'] as String? ?? 'Ventes'),
  );
  SduiWidgetRegistry.register(
    'terminal_status_list',
    (_) => const TerminalStatusList(),
  );
}
