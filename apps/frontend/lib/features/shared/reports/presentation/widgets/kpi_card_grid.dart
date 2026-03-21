import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show dashboardNavigationProvider;
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/shared/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/features/shared/freshness/presentation/providers/freshness_provider.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart'
    show ClientOrderKpis;
import 'package:frontend/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';

/// Dashboard KPI card grid panel.
/// Registered as SDUI type `kpi_card_grid`.
/// Reads [salesStatsProvider] and [expensesProvider] via ref.watch.
class KpiCardGrid extends ConsumerWidget {
  const KpiCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(salesStatsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final poStatsAsync = ref.watch(purchaseOrderStatsProvider);
    final stockAlertCountAsync = ref.watch(stockAlertCountProvider);
    final urgentBatchAsync = ref.watch(urgentBatchCountProvider);
    final reservationsKpiAsync = ref.watch(reservationsKpiProvider);
    final clientOrderKpisAsync = ref.watch(clientOrderKpisProvider);
    final activeClientCountAsync = ref.watch(activeClientCountProvider);
    final lowStockCountAsync = ref.watch(lowStockCountProvider);
    final role = ref.watch(userProfileProvider).valueOrNull?.role;
    final canSeeStockAlerts = role == 'owner' || role == 'manager';
    final visibleSections = ref
        .watch(businessTypeConfigProvider)
        .valueOrNull
        ?.visibleSections ?? [];
    final freshnessRelevant = visibleSections.isEmpty ||
        visibleSections.contains('freshness') ||
        visibleSections.contains('expiry');

    return statsAsync.when(
      data: (stats) {
        final totalRevenue = stats.fold<double>(0, (s, i) => s + i.revenue);
        final totalOrders = stats.fold<int>(0, (s, i) => s + i.orderCount);
        final expenses = expensesAsync.valueOrNull ?? [];
        final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
        final netProfit = totalRevenue - totalExpenses;
        final pendingOrders = poStatsAsync.valueOrNull?['total'] ?? 0;
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
                value: activeClientCountAsync.when(
                  data: (n) => '$n',
                  loading: () => '…',
                  error: (_, _) => '--',
                ),
                iconColor: AppColors.primary,
              ),
              _KpiCard(
                key: const Key('kpi_stock'),
                icon: Icons.inventory_2,
                label: 'Stock faible',
                value: lowStockCountAsync.when(
                  data: (n) => n == 0 ? '0 — OK' : '$n',
                  loading: () => '…',
                  error: (_, _) => '--',
                ),
                iconColor: lowStockCountAsync.valueOrNull != null &&
                        lowStockCountAsync.valueOrNull! > 0
                    ? AppColors.error
                    : AppColors.warning,
                onTap: () => ref.read(dashboardNavigationProvider.notifier).state = 'inventory',
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
              _KpiCard(
                key: const Key('kpi_commandes'),
                icon: Icons.shopping_cart_outlined,
                label: 'Commandes en attente',
                value: '$pendingOrders',
                iconColor: pendingOrders > 0 ? AppColors.warning : AppColors.textSecondary,
                onTap: () => ref.read(dashboardNavigationProvider.notifier).state = 'inventory',
              ),
              // Story 27-5 — Réservations en cours KPI
              if (canSeeStockAlerts)
                _KpiCard(
                  key: const Key('kpi_reservations'),
                  icon: Icons.bookmark_outlined,
                  label: 'Réservations en cours',
                  value: reservationsKpiAsync.when(
                    data: (kpi) => '${kpi['pendingCount'] ?? 0}',
                    loading: () => '…',
                    error: (_, _) => '--',
                  ),
                  subtitle: reservationsKpiAsync.when(
                    data: (kpi) {
                      final fcfa = NumberFormat.currency(
                          locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
                      return 'Acomptes : ${fcfa.format(kpi['totalDepositAmount'] ?? 0)}';
                    },
                    loading: () => null,
                    error: (_, _) => null,
                  ),
                  iconColor: AppColors.primary,
                  onTap: () => ref.read(dashboardNavigationProvider.notifier).state = 'reservations',
                ),
              if (canSeeStockAlerts)
                _KpiCard(
                  key: const Key('kpi_stock_critique'),
                  icon: Icons.warning_amber_rounded,
                  label: 'Stock critique',
                  value: stockAlertCountAsync.when(
                    data: (n) => n == 0 ? '0 — Tout va bien' : '$n',
                    loading: () => '…',
                    error: (_, _) => '--',
                  ),
                  iconColor: stockAlertCountAsync.valueOrNull != null &&
                          stockAlertCountAsync.valueOrNull! > 0
                      ? AppColors.error
                      : AppColors.success,
                  showWarning: (stockAlertCountAsync.valueOrNull ?? 0) > 0,
                  onTap: () => ref.read(dashboardNavigationProvider.notifier).state = 'inventory',
                ),
              // Story 30-6 — Commandes clients KPI cards (FR110)
              if (canSeeStockAlerts) ...[
                _KpiCard(
                  key: const Key('kpi_client_orders'),
                  icon: Icons.assignment_outlined,
                  label: 'Commandes en cours',
                  value: clientOrderKpisAsync.when(
                    data: (ClientOrderKpis kpis) => '${kpis.inProgressCount}',
                    loading: () => '…',
                    error: (_, _) => '--',
                  ),
                  iconColor: AppColors.primary,
                  onTap: () => ref
                      .read(dashboardNavigationProvider.notifier)
                      .state = 'Commandes',
                ),
                _KpiCard(
                  key: const Key('kpi_client_orders_revenue'),
                  icon: Icons.monetization_on_outlined,
                  label: 'CA en attente',
                  value: clientOrderKpisAsync.when(
                    data: (ClientOrderKpis kpis) => NumberFormat.currency(
                            locale: 'fr_FR',
                            symbol: 'FCFA',
                            decimalDigits: 0)
                        .format(kpis.pendingRevenue),
                    loading: () => '…',
                    error: (_, _) => '--',
                  ),
                  iconColor: AppColors.success,
                  onTap: () => ref
                      .read(dashboardNavigationProvider.notifier)
                      .state = 'Commandes',
                ),
              ],
              // AC4 (Story 24-3) — Lots urgents KPI card: hide when 0 and freshness irrelevant
              if (canSeeStockAlerts &&
                  (freshnessRelevant || (urgentBatchAsync.valueOrNull ?? 0) > 0))
                _KpiCard(
                  key: const Key('kpi_lots_urgents'),
                  icon: Icons.eco_outlined,
                  label: 'Lots urgents',
                  value: urgentBatchAsync.when(
                    data: (n) => n == 0 ? '0 — Tout frais' : '$n',
                    loading: () => '…',
                    error: (_, _) => '--',
                  ),
                  iconColor: (urgentBatchAsync.valueOrNull ?? 0) > 0
                      ? AppColors.warning
                      : AppColors.success,
                  showWarning: (urgentBatchAsync.valueOrNull ?? 0) > 0,
                  onTap: () => ref.read(dashboardNavigationProvider.notifier).state = 'inventory',
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
  final String? subtitle;
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
    this.subtitle,
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
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: AppTextStyles.bodySmall),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
