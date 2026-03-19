import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/shared/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/inventory_screen.dart';

/// Dashboard KPI card grid panel.
/// Registered as SDUI type `kpi_card_grid`.
/// Reads [salesStatsProvider] and [expensesProvider] via ref.watch.
class KpiCardGrid extends ConsumerWidget {
  const KpiCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(salesStatsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return statsAsync.when(
      data: (stats) {
        final totalRevenue = stats.fold<double>(0, (s, i) => s + i.revenue);
        final totalOrders = stats.fold<int>(0, (s, i) => s + i.orderCount);
        final expenses = expensesAsync.valueOrNull ?? [];
        final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
        final netProfit = totalRevenue - totalExpenses;
        final fcfa = NumberFormat.currency(
          locale: 'fr_FR',
          symbol: 'FCFA',
          decimalDigits: 0,
        );

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiCard(
                key: const Key('kpi_ventes'),
                icon: Icons.attach_money,
                label: 'Ventes (période)',
                value: fcfa.format(totalRevenue),
                iconColor: AppColors.success,
              ),
              _KpiCard(
                key: const Key('kpi_transactions'),
                icon: Icons.receipt_long,
                label: 'Transactions',
                value: totalOrders.toString(),
                iconColor: AppColors.primary,
              ),
              _KpiCard(
                key: const Key('kpi_clients'),
                icon: Icons.people,
                label: 'Clients actifs',
                value: '--',
                iconColor: AppColors.primary,
              ),
              _KpiCard(
                key: const Key('kpi_stock'),
                icon: Icons.inventory_2,
                label: 'Stock faible',
                value: '--',
                iconColor: AppColors.warning,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InventoryScreen(initialIndex: 1),
                  ),
                ),
              ),
              _KpiCard(
                key: const Key('kpi_depenses'),
                icon: Icons.money_off,
                label: 'Dépenses (période)',
                value: fcfa.format(totalExpenses),
                iconColor: AppColors.error,
              ),
              _KpiCard(
                key: const Key('kpi_benefice'),
                icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                label: 'Bénéfice net',
                value: fcfa.format(netProfit),
                iconColor: netProfit >= 0 ? AppColors.success : AppColors.error,
                valueColor: netProfit >= 0 ? null : AppColors.error,
                showWarning: netProfit < 0,
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onTap;
  final Color? valueColor;
  final bool showWarning;

  const _KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.onTap,
    this.valueColor,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 28),
                    if (showWarning) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.warning, color: AppColors.error, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(label, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.titleMedium.copyWith(color: valueColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
