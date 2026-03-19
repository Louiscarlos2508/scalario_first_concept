import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/core/theme/app_theme.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        data: (data) => _buildReportBody(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
      ),
    );
  }

  Widget _buildReportBody(BuildContext context, Map<String, dynamic> data) {
    final productSales = (data['productSales'] as List<dynamic>?) ?? [];
    final paymentMethodStats =
        (data['paymentMethodStats'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Ventes par produit'),
          const SizedBox(height: 16),
          _buildProductSalesTable(productSales),
          const SizedBox(height: 40),
          _buildSectionTitle(context, 'Ventes par méthode de paiement'),
          const SizedBox(height: 16),
          _buildPaymentMethodChart(context, paymentMethodStats),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildPaymentMethodChart(BuildContext context, List<dynamic> stats) {
    if (stats.isEmpty) return const Text('Aucune donnée de paiement pour cette période.');

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
                final color = Colors.primaries[index % Colors.primaries.length];
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
              final color = Colors.primaries[index % Colors.primaries.length];
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
