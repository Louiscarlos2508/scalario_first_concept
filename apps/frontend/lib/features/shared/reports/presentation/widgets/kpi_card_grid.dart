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
import 'package:frontend/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart'
    show lowStockCountProvider;

/// Dashboard KPI panel — Zone A + Zone B.
///
/// Zone A : 4 KPI cards toujours visibles (CA, Ventes, Bénéfice net, Dépenses).
///   Mobile  (< 600dp) : grille 2×2.
///   Tablette (≥ 600dp) : ligne 1×4.
///
/// Zone B : bannières d'alerte tap-able, visibles SEULEMENT si valeur > 0.
///   Aucun affichage si tout est à 0 (pas de "0 — Tout va bien").
///
/// Registered as SDUI type `kpi_card_grid`.
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
    final lowStockCountAsync = ref.watch(lowStockCountProvider);
    final role = ref.watch(userProfileProvider).valueOrNull?.role;
    final canSeeAlerts = role == 'owner' || role == 'manager';
    final businessConfig = ref.watch(businessTypeConfigProvider).valueOrNull;
    final visibleSections = businessConfig?.visibleSections ?? [];
    final freshnessRelevant = visibleSections.isEmpty ||
        visibleSections.contains('freshness') ||
        visibleSections.contains('expiry');
    final isDistribution = businessConfig?.documentType == 'delivery_note';

    return statsAsync.when(
      data: (stats) {
        final totalRevenue = stats.fold<double>(0, (s, i) => s + i.revenue);
        final totalOrders = stats.fold<int>(0, (s, i) => s + i.orderCount);
        final expenses = expensesAsync.valueOrNull ?? [];
        final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
        final netProfit = totalRevenue - totalExpenses;

        final pendingPurchaseOrders = poStatsAsync.valueOrNull?['total'] ?? 0;
        final lowStockCount = lowStockCountAsync.valueOrNull ?? 0;
        final stockAlertCount = stockAlertCountAsync.valueOrNull ?? 0;
        final urgentBatchCount = urgentBatchAsync.valueOrNull ?? 0;
        final reservationsPending =
            (reservationsKpiAsync.valueOrNull?['pendingCount'] as num?)
                    ?.toInt() ??
                0;
        final clientOrdersInProgress =
            clientOrderKpisAsync.valueOrNull?.inProgressCount ?? 0;

        final fcfa = NumberFormat.currency(
          locale: 'fr_FR',
          symbol: 'FCFA',
          decimalDigits: 0,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Zone A : 4 KPIs principaux ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: isTablet
                      ? _TabletKpiRow(
                          totalRevenue: totalRevenue,
                          totalOrders: totalOrders,
                          netProfit: netProfit,
                          totalExpenses: totalExpenses,
                          fcfa: fcfa,
                        )
                      : _MobileKpiGrid(
                          totalRevenue: totalRevenue,
                          totalOrders: totalOrders,
                          netProfit: netProfit,
                          totalExpenses: totalExpenses,
                          fcfa: fcfa,
                        ),
                ),

                // ── Zone B : Alertes conditionnelles (si > 0) ────────────
                if (canSeeAlerts)
                  _AlertsSection(
                    ref: ref,
                    stockAlertCount: stockAlertCount,
                    lowStockCount: lowStockCount,
                    urgentBatchCount: urgentBatchCount,
                    freshnessRelevant: freshnessRelevant,
                    pendingPurchaseOrders: pendingPurchaseOrders,
                    reservationsPending: reservationsPending,
                    clientOrdersInProgress: clientOrdersInProgress,
                    isDistribution: isDistribution,
                  ),
              ],
            );
          },
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

// ── Zone A — Tablette : 4 colonnes ────────────────────────────────────────────

class _TabletKpiRow extends StatelessWidget {
  final double totalRevenue;
  final int totalOrders;
  final double netProfit;
  final double totalExpenses;
  final NumberFormat fcfa;

  const _TabletKpiRow({
    required this.totalRevenue,
    required this.totalOrders,
    required this.netProfit,
    required this.totalExpenses,
    required this.fcfa,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _KpiCard(
            key: const Key('kpi_ca'),
            icon: Icons.attach_money,
            label: 'CA',
            value: fcfa.format(totalRevenue),
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            key: const Key('kpi_ventes'),
            icon: Icons.receipt_long,
            label: 'Ventes',
            value: '$totalOrders',
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            key: const Key('kpi_benefice'),
            icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
            label: 'Bénéfice net',
            value: fcfa.format(netProfit),
            iconColor: netProfit >= 0 ? AppColors.success : AppColors.error,
            valueColor: netProfit < 0 ? AppColors.error : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            key: const Key('kpi_depenses'),
            icon: Icons.money_off,
            label: 'Dépenses',
            value: fcfa.format(totalExpenses),
            iconColor: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

// ── Zone A — Mobile : grille 2×2 ─────────────────────────────────────────────

class _MobileKpiGrid extends StatelessWidget {
  final double totalRevenue;
  final int totalOrders;
  final double netProfit;
  final double totalExpenses;
  final NumberFormat fcfa;

  const _MobileKpiGrid({
    required this.totalRevenue,
    required this.totalOrders,
    required this.netProfit,
    required this.totalExpenses,
    required this.fcfa,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                key: const Key('kpi_ca'),
                icon: Icons.attach_money,
                label: 'CA',
                value: fcfa.format(totalRevenue),
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                key: const Key('kpi_ventes'),
                icon: Icons.receipt_long,
                label: 'Ventes',
                value: '$totalOrders',
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                key: const Key('kpi_benefice'),
                icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                label: 'Bénéfice net',
                value: fcfa.format(netProfit),
                iconColor: netProfit >= 0 ? AppColors.success : AppColors.error,
                valueColor: netProfit < 0 ? AppColors.error : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                key: const Key('kpi_depenses'),
                icon: Icons.money_off,
                label: 'Dépenses',
                value: fcfa.format(totalExpenses),
                iconColor: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Zone B — Alertes conditionnelles ─────────────────────────────────────────

class _AlertsSection extends StatelessWidget {
  final WidgetRef ref;
  final int stockAlertCount;
  final int lowStockCount;
  final int urgentBatchCount;
  final bool freshnessRelevant;
  final int pendingPurchaseOrders;
  final int reservationsPending;
  final int clientOrdersInProgress;
  final bool isDistribution;

  const _AlertsSection({
    required this.ref,
    required this.stockAlertCount,
    required this.lowStockCount,
    required this.urgentBatchCount,
    required this.freshnessRelevant,
    required this.pendingPurchaseOrders,
    required this.reservationsPending,
    required this.clientOrdersInProgress,
    required this.isDistribution,
  });

  @override
  Widget build(BuildContext context) {
    final alerts = <_AlertBannerData>[];

    if (stockAlertCount > 0) {
      final n = stockAlertCount;
      alerts.add(_AlertBannerData(
        icon: Icons.warning_amber_rounded,
        color: AppColors.error,
        label:
            '$n produit${n > 1 ? 's' : ''} en stock critique',
        moduleCode: 'inventory',
      ));
    } else if (lowStockCount > 0) {
      final n = lowStockCount;
      alerts.add(_AlertBannerData(
        icon: Icons.inventory_2,
        color: AppColors.warning,
        label: '$n produit${n > 1 ? 's' : ''} en stock bas',
        moduleCode: 'inventory',
      ));
    }

    if (freshnessRelevant && urgentBatchCount > 0) {
      final n = urgentBatchCount;
      alerts.add(_AlertBannerData(
        icon: Icons.eco_outlined,
        color: AppColors.warning,
        label: '$n lot${n > 1 ? 's' : ''} expirent bientôt',
        moduleCode: 'inventory',
      ));
    }

    if (pendingPurchaseOrders > 0) {
      final n = pendingPurchaseOrders;
      alerts.add(_AlertBannerData(
        icon: Icons.call_received_outlined,
        color: AppColors.primary,
        label:
            '$n commande${n > 1 ? 's' : ''} fournisseur${n > 1 ? 's' : ''} en attente',
        moduleCode: 'purchase_orders',
      ));
    }

    if (reservationsPending > 0) {
      final n = reservationsPending;
      alerts.add(_AlertBannerData(
        icon: Icons.bookmark_outline,
        color: AppColors.primary,
        label: '$n réservation${n > 1 ? 's' : ''} en cours',
        moduleCode: 'reservations',
      ));
    }

    if (clientOrdersInProgress > 0) {
      final n = clientOrdersInProgress;
      alerts.add(_AlertBannerData(
        icon: isDistribution
            ? Icons.local_shipping_outlined
            : Icons.assignment_outlined,
        color: AppColors.primary,
        label: isDistribution
            ? '$n livraison${n > 1 ? 's' : ''} à effectuer'
            : '$n commande${n > 1 ? 's' : ''} client${n > 1 ? 's' : ''} en cours',
        moduleCode: 'Commandes',
      ));
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: alerts
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AlertBanner(
                  icon: a.icon,
                  color: a.color,
                  label: a.label,
                  onTap: () => ref
                      .read(dashboardNavigationProvider.notifier)
                      .state = a.moduleCode,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AlertBannerData {
  final IconData icon;
  final Color color;
  final String label;
  final String moduleCode;

  const _AlertBannerData({
    required this.icon,
    required this.color,
    required this.label,
    required this.moduleCode,
  });
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: color.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color? valueColor;

  const _KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headlineLarge.copyWith(
                fontSize: 18,
                color: valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
