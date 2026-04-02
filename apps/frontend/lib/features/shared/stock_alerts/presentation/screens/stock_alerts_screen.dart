import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/widgets/create_purchase_order_sheet.dart';

class StockAlertsScreen extends ConsumerWidget {
  const StockAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(stockAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Alertes stock',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(stockAlertsProvider),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erreur : $err',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const _EmptyState();
          }

          // Sort: critical first
          final sorted = [...alerts]..sort((a, b) {
              final aScore = _severity(a);
              final bScore = _severity(b);
              return bScore.compareTo(aScore);
            });

          final criticalCount =
              sorted.where((a) => _severity(a) == 2).length;
          final warningCount = sorted.length - criticalCount;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(stockAlertsProvider),
            child: CustomScrollView(
              slivers: [
                // Summary bar
                SliverToBoxAdapter(
                  child: _SummaryBar(
                      criticalCount: criticalCount,
                      warningCount: warningCount),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: sorted.length,
                    itemBuilder: (context, index) => _AlertCard(
                      alert: sorted[index],
                      key: Key('alert_${sorted[index]['catalogItemId']}'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Returns 2 = critical, 1 = warning.
  static int _severity(Map<String, dynamic> alert) {
    final stock = (alert['stockQuantity'] as num?)?.toDouble() ?? 0;
    if (stock <= 0) return 2;
    final threshold = (alert['minStockLevel'] as num?)?.toDouble() ?? 0;
    if (threshold > 0 && stock <= threshold * 0.4) return 2;
    return 1;
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int criticalCount;
  final int warningCount;
  const _SummaryBar(
      {required this.criticalCount, required this.warningCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (criticalCount > 0) ...[
            _Badge(
              count: criticalCount,
              label: 'Critique${criticalCount > 1 ? 's' : ''}',
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
          ],
          if (warningCount > 0)
            _Badge(
              count: warningCount,
              label: 'Attention',
              color: Colors.orange.shade700,
            ),
          const Spacer(),
          Text(
            '${criticalCount + warningCount} article${criticalCount + warningCount > 1 ? 's' : ''}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _Badge(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final name = alert['itemName']?.toString() ?? '';
    final stock = (alert['stockQuantity'] as num?)?.toDouble() ?? 0;
    final threshold = (alert['minStockLevel'] as num?)?.toDouble() ?? 0;
    final deficit = (alert['deficit'] as num?)?.toDouble() ?? 0;
    final catalogItemId = alert['catalogItemId']?.toString();
    final isCritical = StockAlertsScreen._severity(alert) == 2;

    final severityColor = isCritical ? AppColors.error : Colors.orange.shade700;
    final severityLabel = isCritical ? 'Critique' : 'Attention';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        // Left accent border via BoxDecoration trick
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity stripe
              Container(width: 4, color: severityColor),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: severityColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        severityColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    severityLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: severityColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _InfoChip(
                                    label: 'Stock',
                                    value: _qty(stock),
                                    valueColor: severityColor),
                                const SizedBox(width: 8),
                                _InfoChip(
                                    label: 'Seuil',
                                    value: _qty(threshold)),
                                const SizedBox(width: 8),
                                _InfoChip(
                                    label: 'Déficit',
                                    value: _qty(deficit),
                                    valueColor: AppColors.error),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action
                      TextButton(
                        key: Key('reappro_$catalogItemId'),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const CreatePurchaseOrderSheet(),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_shopping_cart,
                                size: 18, color: AppColors.primary),
                            const SizedBox(height: 2),
                            const Text(
                              'Réappro.',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _qty(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoChip(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('stock_alerts_empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
          SizedBox(height: 16),
          Text(
            'Aucun stock critique',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Tous vos articles sont au-dessus\ndes seuils d\'alerte.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
