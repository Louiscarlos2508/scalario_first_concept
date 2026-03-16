import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:frontend/features/retail/dashboard/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/retail/dashboard/presentation/screens/categories_screen.dart';
import 'package:frontend/features/retail/dashboard/presentation/screens/stock_history_screen.dart';
import 'package:frontend/features/retail/dashboard/presentation/screens/reports_screen.dart';
import 'package:frontend/features/retail/dashboard/presentation/screens/customers_screen.dart';
import 'package:frontend/features/retail/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_providers.dart';
import 'package:frontend/core/sdui/sdui_renderer.dart';
import 'dart:async';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OverviewScreen(),
    const InventoryScreen(),
    const CategoriesScreen(),
    const CustomersScreen(),
    const StockHistoryScreen(),
    const ReportsScreen(),
    const SettingsPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: _screens[_selectedIndex],
    );
  }
}

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  // Timer for auto-refresh
  // ignore: unused_field
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Only refresh if the widget is mounted
      if (mounted) {
        ref.refresh(salesStatsProvider);
        ref.refresh(terminalStatusProvider);
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
      appBar: AppBar(
        title: const Text('Tableau de bord'),
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
              ref.refresh(salesStatsProvider);
              ref.refresh(terminalStatusProvider);
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
      error: (_, __) => SduiLayout.dashboardDefault(),
    );
    return SduiRenderer(layout: layout);
  }

}

class ReportsPlaceholder extends StatelessWidget {
  const ReportsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports')),
    body: const Center(child: Text('Sales Reports Coming Soon')),
  );
}

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Paramètres')),
    body: const Center(child: Text('Paramètres à venir')),
  );
}
