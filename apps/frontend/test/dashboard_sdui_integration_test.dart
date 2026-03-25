import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_providers.dart';
import 'package:frontend/core/sdui/sdui_renderer.dart';
import 'package:frontend/core/sdui/sdui_widget_registry.dart';
import 'package:frontend/features/shared/expenses/data/models/expense.dart';
import 'package:frontend/features/shared/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/shared/reports/data/models/sales_stat.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart';
import 'package:frontend/features/shared/reports/presentation/widgets/kpi_card_grid.dart';
import 'package:frontend/features/shared/reports/presentation/widgets/line_chart_widget.dart';
import 'package:frontend/features/shared/reports/presentation/widgets/terminal_status_list.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart'
    show BusinessTypeConfig;
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart'
    show lowStockCountProvider;
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart'
    show ClientOrderKpis;
import 'package:frontend/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart';
import 'package:frontend/features/shared/freshness/presentation/providers/freshness_provider.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart'
    show unreadNotificationCountProvider;

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
      activeSessionsProvider.overrideWith((ref) => Future.value([])),
      sduiLayoutProvider('dashboard').overrideWith(
        (ref) => layoutResult ?? Future.value(SduiLayout.dashboardDefault()),
      ),
      unreadNotificationCountProvider.overrideWith((ref) => Stream.value(0)),
      purchaseOrderStatsProvider.overrideWith(
        (ref) => Future.value({'pendingCount': 0}),
      ),
      stockAlertCountProvider.overrideWith((ref) => Future.value(0)),
      urgentBatchCountProvider.overrideWith((ref) => Future.value(0)),
      reservationsKpiProvider.overrideWith(
        (ref) => Future.value({'pendingCount': 0, 'totalDepositAmount': 0}),
      ),
      clientOrderKpisProvider.overrideWith(
        (ref) => Future.value(ClientOrderKpis.zero),
      ),
      lowStockCountProvider.overrideWith((ref) => Future.value(0)),
      businessTypeConfigProvider.overrideWith(
        (ref) => Future.value(BusinessTypeConfig.fallback),
      ),
      userProfileProvider.overrideWith(
        (ref) => Future.value(UserProfile(
          id: 'test-owner',
          email: 'owner@test.com',
          memberships: [
            TenantMembership(tenantId: 'tenant-1', role: 'owner'),
          ],
        )),
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
      activeSessionsProvider.overrideWith((ref) => Future.value([])),
      purchaseOrderStatsProvider.overrideWith(
        (ref) => Future.value({'pendingCount': 0}),
      ),
      stockAlertCountProvider.overrideWith((ref) => Future.value(0)),
      urgentBatchCountProvider.overrideWith((ref) => Future.value(0)),
      reservationsKpiProvider.overrideWith(
        (ref) => Future.value({'pendingCount': 0, 'totalDepositAmount': 0}),
      ),
      clientOrderKpisProvider.overrideWith(
        (ref) => Future.value(ClientOrderKpis.zero),
      ),
      lowStockCountProvider.overrideWith((ref) => Future.value(0)),
      businessTypeConfigProvider.overrideWith(
        (ref) => Future.value(BusinessTypeConfig.fallback),
      ),
      userProfileProvider.overrideWith(
        (ref) => Future.value(UserProfile(
          id: 'test-owner',
          email: 'owner@test.com',
          memberships: [
            TenantMembership(tenantId: 'tenant-1', role: 'owner'),
          ],
        )),
      ),
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

      expect(find.text('CA'), findsOneWidget);
      expect(find.text('Ventes'), findsOneWidget);
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

      expect(find.text('CA'), findsOneWidget);
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
      expect(find.text('Ventes'), findsOneWidget);
    });
  });

  // ── Story 18-3: TerminalStatusList affiche deviceId ───────────────────────

  group('TerminalStatusList — device name (Story 18-3)', () {
    Widget buildWithSessions(List<Map<String, dynamic>> sessions) {
      return ProviderScope(
        overrides: [
          salesStatsProvider.overrideWith((ref) => Future.value(_mockStats)),
          terminalStatusProvider
              .overrideWith((ref) => Future.value(_mockTerminals)),
          activeSessionsProvider
              .overrideWith((ref) => Future.value(sessions)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TerminalStatusList()),
        ),
      );
    }

    testWidgets('shows deviceId when non-null', (tester) async {
      await tester.pumpWidget(buildWithSessions([
        {
          'deviceId': 'caisse-test-001',
          'openedAt': DateTime.now().toIso8601String(),
          'openingBalance': '5000',
          'status': 'OPEN',
        },
      ]));
      await tester.pump();
      await tester.pump();

      expect(find.text('caisse-test-001'), findsOneWidget);
    });

    testWidgets('shows "Terminal inconnu" when deviceId is null', (tester) async {
      await tester.pumpWidget(buildWithSessions([
        {
          'deviceId': null,
          'openedAt': DateTime.now().toIso8601String(),
          'openingBalance': '5000',
          'status': 'OPEN',
        },
      ]));
      await tester.pump();
      await tester.pump();

      expect(find.text('Terminal inconnu'), findsOneWidget);
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

      expect(find.text('CA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ── Story 17-3: KPI Dépenses & Bénéfice net ───────────────────────────────

  group('KPI Dépenses & Bénéfice net (Story 17-3)', () {
    Widget buildKpiGrid({
      required List<SalesStat> stats,
      required List<Expense> expenses,
    }) {
      return ProviderScope(
        overrides: [
          activeTenantProvider.overrideWith((ref) => 'tenant-1'),
          salesStatsProvider.overrideWith((ref) => Future.value(stats)),
          expensesProvider.overrideWith((ref) => Future.value(expenses)),
          purchaseOrderStatsProvider.overrideWith(
            (ref) => Future.value({'pendingCount': 0}),
          ),
          stockAlertCountProvider.overrideWith((ref) => Future.value(0)),
          urgentBatchCountProvider.overrideWith((ref) => Future.value(0)),
          reservationsKpiProvider.overrideWith(
            (ref) =>
                Future.value({'pendingCount': 0, 'totalDepositAmount': 0}),
          ),
          clientOrderKpisProvider.overrideWith(
            (ref) => Future.value(ClientOrderKpis.zero),
          ),
          lowStockCountProvider.overrideWith((ref) => Future.value(0)),
          businessTypeConfigProvider.overrideWith(
            (ref) => Future.value(BusinessTypeConfig.fallback),
          ),
          userProfileProvider.overrideWith(
            (ref) => Future.value(UserProfile(
              id: 'test-owner',
              email: 'owner@test.com',
              memberships: [
                TenantMembership(tenantId: 'tenant-1', role: 'owner'),
              ],
            )),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: KpiCardGrid()),
        ),
      );
    }

    testWidgets('shows Dépenses and Bénéfice net labels',
        (tester) async {
      final stats = [
        SalesStat(day: DateTime(2026, 3, 1), revenue: 100000, orderCount: 5),
      ];
      final expenses = [
        Expense(
          id: 'e1',
          tenantId: 't1',
          userId: 'u1',
          label: 'Loyer',
          amount: 30000,
          category: 'LOYER',
          date: DateTime(2026, 3, 1),
        ),
      ];

      await tester.pumpWidget(buildKpiGrid(stats: stats, expenses: expenses));
      await tester.pump();

      expect(find.text('Dépenses'), findsOneWidget);
      expect(find.text('Bénéfice net'), findsOneWidget);
    });

    testWidgets('shows trending_down icon when net profit is negative', (tester) async {
      final stats = [
        SalesStat(day: DateTime(2026, 3, 1), revenue: 100000, orderCount: 5),
      ];
      final expenses = [
        Expense(
          id: 'e1',
          tenantId: 't1',
          userId: 'u1',
          label: 'Loyer',
          amount: 150000,
          category: 'LOYER',
          date: DateTime(2026, 3, 1),
        ),
      ];

      await tester.pumpWidget(buildKpiGrid(stats: stats, expenses: expenses));
      await tester.pump();

      // net profit = 100 000 - 150 000 = -50 000 → trending_down icon visible
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('no trending_down icon when net profit is non-negative', (tester) async {
      final stats = [
        SalesStat(day: DateTime(2026, 3, 1), revenue: 200000, orderCount: 10),
      ];
      final expenses = [
        Expense(
          id: 'e1',
          tenantId: 't1',
          userId: 'u1',
          label: 'Loyer',
          amount: 50000,
          category: 'LOYER',
          date: DateTime(2026, 3, 1),
        ),
      ];

      await tester.pumpWidget(buildKpiGrid(stats: stats, expenses: expenses));
      await tester.pump();

      // net profit = 200 000 - 50 000 = 150 000 ≥ 0 → no trending_down
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });
  });
}
