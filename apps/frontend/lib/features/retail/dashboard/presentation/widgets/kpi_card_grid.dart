import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:frontend/features/retail/dashboard/presentation/screens/inventory_screen.dart';

/// Dashboard KPI card grid panel.
/// Registered as SDUI type `kpi_card_grid`.
/// Reads [salesStatsProvider] via ref.watch.
class KpiCardGrid extends ConsumerWidget {
  const KpiCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(salesStatsProvider);

    return statsAsync.when(
      data: (stats) {
        final totalRevenue = stats.fold<double>(0, (s, i) => s + i.revenue);
        final totalOrders = stats.fold<int>(0, (s, i) => s + i.orderCount);
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
                icon: Icons.attach_money,
                label: 'Ventes du jour',
                value: fcfa.format(totalRevenue),
                iconColor: AppColors.success,
              ),
              _KpiCard(
                icon: Icons.receipt_long,
                label: 'Transactions',
                value: totalOrders.toString(),
                iconColor: AppColors.primary,
              ),
              _KpiCard(
                icon: Icons.people,
                label: 'Clients actifs',
                value: '--',
                iconColor: AppColors.primary,
              ),
              _KpiCard(
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
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.onTap,
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
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(height: 12),
                Text(label, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
