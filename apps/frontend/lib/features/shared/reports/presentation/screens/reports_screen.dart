import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/business_type/utils/access_utils.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/shared/reports/presentation/screens/session_history_screen.dart';
import 'package:frontend/features/shared/reports/presentation/screens/sales_history_screen.dart';
import 'package:frontend/core/theme/app_theme.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    // React to external signals (e.g. from TerminalStatusList)
    ref.listen(showSessionHistoryProvider, (_, show) {
      if (show && mounted) setState(() => _showHistory = true);
    });

    if (_showHistory) {
      return PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            setState(() => _showHistory = false);
            ref.read(showSessionHistoryProvider.notifier).state = false;
          }
        },
        child: SessionHistoryScreen(
          onBack: () {
            setState(() => _showHistory = false);
            ref.read(showSessionHistoryProvider.notifier).state = false;
          },
        ),
      );
    }

    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final canSeeFullHistory = canAccessScreen(role, 'daily_sales', config) ||
        canAccessScreen(role, 'backoffice', config);
    final canSeeSessionHistory = canAccessScreen(role, 'pos', config);
    final canSeeAnalytics = canAccessScreen(role, 'backoffice', config);

    final reportAsync = ref.watch(salesReportProvider);
    final dateRange = ref.watch(salesReportDateRangeProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Rapports',
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
                ref.read(salesReportDateRangeProvider.notifier).state = picked;
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
              dateRange == null
                  ? 'Toute la période'
                  : '${DateFormat('dd/MM').format(dateRange.start)} – ${DateFormat('dd/MM').format(dateRange.end)}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(salesReportProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: reportAsync.when(
        data: (data) => _buildReportBody(
          data,
          canSeeFullHistory: canSeeFullHistory,
          canSeeSessionHistory: canSeeSessionHistory,
          canSeeAnalytics: canSeeAnalytics,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
    );
  }

  Widget _buildReportBody(
    Map<String, dynamic> data, {
    required bool canSeeFullHistory,
    required bool canSeeSessionHistory,
    required bool canSeeAnalytics,
  }) {
    final productSales = (data['productSales'] as List<dynamic>?) ?? [];
    final paymentMethodStats =
        (data['paymentMethodStats'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canSeeFullHistory) _buildSalesHistoryCard(),
          if (canSeeFullHistory) const SizedBox(height: 16),
          if (canSeeSessionHistory) _buildSessionHistoryCard(),
          if (canSeeAnalytics) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Ventes par produit'),
            const SizedBox(height: 16),
            _buildProductSalesTable(productSales),
            const SizedBox(height: 40),
            _buildSectionTitle('Ventes par méthode de paiement'),
            const SizedBox(height: 16),
            _buildPaymentMethodChart(paymentMethodStats),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesHistoryCard() {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.receipt_long, color: Colors.white, size: 20),
        ),
        title: const Text('Historique des ventes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Consulter toutes les transactions par période'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
        ),
      ),
    );
  }

  Widget _buildSessionHistoryCard() {
    return Card(
      key: const Key('session_history_card'),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.point_of_sale, color: Colors.white, size: 20),
        ),
        title: const Text('Historique des sessions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Consulter les Z-reports des caisses clôturées'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() => _showHistory = true),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildProductSalesTable(List<dynamic> productSales) {
    if (productSales.isEmpty) {
      return const Text('Aucune vente pour cette période.');
    }

    final sortedSales = List.from(productSales);
    sortedSales.sort(
      (a, b) => (b['revenue'] as num).compareTo(a['revenue'] as num),
    );

    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: AppColors.border),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Produit')),
          DataColumn(label: Text('Qté'), numeric: true),
          DataColumn(label: Text('Recettes'), numeric: true),
        ],
        rows: sortedSales.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['name'])),
              DataCell(Text(item['quantity'].toString())),
              DataCell(Text(_fcfa((item['revenue'] as num).toDouble()))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethodChart(List<dynamic> stats) {
    if (stats.isEmpty) {
      return const Text('Aucune donnée de paiement pour cette période.');
    }

    return Row(
      children: [
        SizedBox(
          height: 200,
          width: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: stats.asMap().entries.map((e) {
                final index = e.key;
                final val = e.value;
                final color =
                    Colors.primaries[index % Colors.primaries.length];
                return PieChartSectionData(
                  color: color,
                  value: (val['value'] as num).toDouble(),
                  title: '',
                  radius: 50,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stats.asMap().entries.map((e) {
              final index = e.key;
              final val = e.value;
              final color =
                  Colors.primaries[index % Colors.primaries.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${val['name']} : ${_fcfa((val['value'] as num).toDouble())}',
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
