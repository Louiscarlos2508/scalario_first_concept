import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/backoffice/presentation/widgets/dashboard_shell.dart';
import 'package:frontend/features/retail/inventory/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/retail/catalog/presentation/screens/catalog_screen.dart';
import 'package:frontend/features/retail/inventory/presentation/screens/stock_history_screen.dart';
import 'package:frontend/features/retail/reports/presentation/screens/reports_screen.dart';
import 'package:frontend/features/retail/customers/presentation/screens/customers_screen.dart';
import 'package:frontend/features/retail/reports/presentation/providers/report_providers.dart' show salesStatsProvider, activeSessionsProvider, salesStatsDateRangeProvider;
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_providers.dart';
import 'package:frontend/core/sdui/sdui_renderer.dart';
import 'package:frontend/features/retail/expenses/presentation/screens/expenses_screen.dart';
import 'package:frontend/features/retail/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/retail/settings/presentation/screens/settings_screen.dart';
import 'dart:async';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  // IndexedStack : tous les écrans restent montés → état (scroll, onglet)
  // préservé lors des changements de section.
  static const List<Widget> _screens = [
    OverviewScreen(),
    InventoryScreen(),
    CatalogScreen(),
    CustomersScreen(),
    StockHistoryScreen(),
    ReportsScreen(),
    ExpensesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      child: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  // ignore: unused_field
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(salesStatsProvider);
        ref.invalidate(activeSessionsProvider);
        ref.invalidate(expensesProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(salesStatsDateRangeProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Tableau de bord',
        actions: [
          TextButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: dateRange,
              );
              if (picked != null) {
                ref.read(salesStatsDateRangeProvider.notifier).state = picked;
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
              dateRange == null
                  ? '7 derniers jours'
                  : '${DateFormat('dd/MM').format(dateRange.start)} – ${DateFormat('dd/MM').format(dateRange.end)}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(salesStatsProvider);
              ref.invalidate(activeSessionsProvider);
              ref.invalidate(expensesProvider);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildSduiBody(),
    );
  }

  Widget _buildSduiBody() {
    final layoutAsync = ref.watch(sduiLayoutProvider('dashboard'));
    final layout = layoutAsync.when(
      data: (l) => l,
      loading: () => SduiLayout.dashboardDefault(),
      error: (_, _) => SduiLayout.dashboardDefault(),
    );
    return SduiRenderer(layout: layout);
  }
}

