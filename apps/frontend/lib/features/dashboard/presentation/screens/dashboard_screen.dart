import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:frontend/features/dashboard/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/dashboard/presentation/screens/categories_screen.dart';
import 'package:frontend/features/dashboard/presentation/screens/stock_history_screen.dart';
import 'package:frontend/features/dashboard/presentation/screens/reports_screen.dart';
import 'package:frontend/features/dashboard/presentation/screens/customers_screen.dart';
import 'package:frontend/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:frontend/features/dashboard/data/models/sales_stat.dart';
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
    final statsAsync = ref.watch(salesStatsProvider);
    final dateRange = ref.watch(salesStatsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
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
                  ? 'Last 7 Days'
                  : '${DateFormat('MM/dd').format(dateRange.start)} - ${DateFormat('MM/dd').format(dateRange.end)}',
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
      body: statsAsync.when(
        data: (stats) => _buildDashboard(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<SalesStat> stats) {
    final totalRevenue = stats.fold<double>(
      0.0,
      (sum, item) => sum + item.revenue,
    );
    final totalOrders = stats.fold<int>(
      0,
      (sum, item) => sum + item.orderCount,
    );
    final avgTicket = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(
                context,
                'Total Revenue',
                '\$ ${totalRevenue.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Order Count',
                totalOrders.toString(),
                Icons.shopping_basket,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Avg. Ticket',
                '\$ ${avgTicket.toStringAsFixed(2)}',
                Icons.confirmation_number_outlined,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Revenue Trends (Last 7 Days)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildSalesChart(context, stats),
          const SizedBox(height: 32),
          const TerminalsStatusWidget(),
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, List<SalesStat> stats) {
    if (stats.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('No sales data yet for the last 7 days')),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= stats.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(stats[index].day),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                interval: 1,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: stats.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.revenue);
              }).toList(),
              isCurved: true,
              color: Colors.teal,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.teal.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    appBar: AppBar(title: const Text('Settings')),
    body: const Center(child: Text('System Settings Coming Soon')),
  );
}

class TerminalsStatusWidget extends ConsumerWidget {
  const TerminalsStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminalsAsync = ref.watch(terminalStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Terminals', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        terminalsAsync.when(
          data: (terminals) {
            if (terminals.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('No terminals active yet'),
                  subtitle: Text('Start a POS terminal to see it here'),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: terminals.length,
              itemBuilder: (context, index) {
                final t = terminals[index];
                final lastSeen = DateTime.parse(t['lastSeen']);
                final isOnline =
                    t['status'] == 'ONLINE' &&
                    DateTime.now().difference(lastSeen).inMinutes < 5;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOnline
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.computer,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    title: Text(t['deviceId']),
                    subtitle: Text(
                      'Last seen: ${DateFormat('HH:mm:ss').format(lastSeen)}',
                    ),
                    trailing: Chip(
                      label: Text(isOnline ? 'ONLINE' : 'OFFLINE'),
                      backgroundColor: isOnline
                          ? Colors.green.shade50
                          : Colors.grey.shade50,
                      labelStyle: TextStyle(
                        color: isOnline ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error loading terminals: $err'),
        ),
      ],
    );
  }
}
