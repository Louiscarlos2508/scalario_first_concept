import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_providers.dart';
import 'package:frontend/core/sdui/sdui_renderer.dart';
import 'package:frontend/core/sdui/sdui_widget_registry.dart';
import 'package:frontend/features/retail/dashboard/data/models/sales_stat.dart';
import 'package:frontend/features/retail/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:frontend/features/retail/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/kpi_card_grid.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/line_chart_widget.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/terminal_status_list.dart';

// ── Shared fixtures ───────────────────────────────────────────────────────────

final _mockStats = [
  SalesStat(day: DateTime(2026, 3, 9), revenue: 15000, orderCount: 5),
  SalesStat(day: DateTime(2026, 3, 10), revenue: 22500, orderCount: 8),
];

final _mockTerminals = [
  {
    'deviceId': 'caisse-1',
    'lastSeen': DateTime.now().toIso8601String(),
    'status': 'ONLINE',
  },
];

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Build [OverviewScreen] with all network providers stubbed.
Widget _buildOverviewScreen({Future<SduiLayout>? layoutResult}) {
  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      salesStatsProvider.overrideWith((ref) => Future.value(_mockStats)),
      terminalStatusProvider
          .overrideWith((ref) => Future.value(_mockTerminals)),
      sduiLayoutProvider('dashboard').overrideWith(
        (ref) => layoutResult ?? Future.value(SduiLayout.dashboardDefault()),
      ),
    ],
    child: const MaterialApp(home: OverviewScreen()),
  );
}

/// Wrap [SduiRenderer] at [width] with mocked data providers.
Widget _buildRendererAt(double width, SduiLayout layout) {
  return ProviderScope(
    overrides: [
      salesStatsProvider.overrideWith((ref) => Future.value(_mockStats)),
      terminalStatusProvider
          .overrideWith((ref) => Future.value(_mockTerminals)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: SduiRenderer(layout: layout)),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SduiWidgetRegistry.reset();
    SduiWidgetRegistry.register('kpi_card_grid', (_) => const KpiCardGrid());
    SduiWidgetRegistry.register(
      'line_chart',
      (props) => LineChartWidget(title: props['title'] as String? ?? 'Ventes'),
    );
    SduiWidgetRegistry.register(
      'terminal_status_list',
      (_) => const TerminalStatusList(),
    );
  });

  tearDown(() => SduiWidgetRegistry.reset());

  // ── AC6: Tablet layout (800dp) ─────────────────────────────────────────────

  group('Tablet layout (800dp) — dashboard_scroll', () {
    testWidgets('renders KPI card labels and terminal status',
        (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(800, SduiLayout.dashboardDefault()),
      );
      await tester.pump(); // resolve futures
      await tester.pump();

      expect(find.text('Ventes du jour'), findsOneWidget);
      expect(find.text('État des caisses'), findsOneWidget);
    });
  });

  // ── AC6: Phone layout (400dp) ──────────────────────────────────────────────

  group('Phone layout (400dp) — dashboard_scroll', () {
    testWidgets('renders KPI card labels', (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(400, SduiLayout.dashboardDefault()),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Ventes du jour'), findsOneWidget);
    });
  });

  // ── AC1: KPI data rendered ─────────────────────────────────────────────────

  group('KPI card data rendering (AC1)', () {
    testWidgets('KpiCardGrid renders revenue in FCFA format', (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(800, SduiLayout.dashboardDefault()),
      );
      await tester.pump();
      await tester.pump();

      // 15000 + 22500 = 37500 FCFA
      expect(find.textContaining('FCFA'), findsWidgets);
      expect(find.text('Transactions'), findsOneWidget);
    });
  });

  // ── AC3: Offline fallback ──────────────────────────────────────────────────

  group('Offline fallback (AC3)', () {
    testWidgets('loading SDUI layout uses dashboardDefault — no blank screen',
        (tester) async {
      final never = Completer<SduiLayout>().future;
      await tester.pumpWidget(_buildOverviewScreen(layoutResult: never));
      await tester.pump(); // layout never resolves → falls back to dashboardDefault
      await tester.pump(); // salesStatsProvider resolves

      expect(find.text('Ventes du jour'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
