import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/widgets/create_purchase_order_sheet.dart';

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _AlertFilter { all, stock, caisse }

extension _AlertFilterLabel on _AlertFilter {
  String get label {
    switch (this) {
      case _AlertFilter.all:
        return 'Toutes';
      case _AlertFilter.stock:
        return 'Stock';
      case _AlertFilter.caisse:
        return 'Caisse';
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StockAlertsScreen extends ConsumerStatefulWidget {
  const StockAlertsScreen({super.key});

  @override
  ConsumerState<StockAlertsScreen> createState() => _StockAlertsScreenState();

  /// Returns 2 = critical, 1 = warning.
  static int severity(Map<String, dynamic> alert) {
    final stock = (alert['stockQuantity'] as num?)?.toDouble() ?? 0;
    if (stock <= 0) return 2;
    final threshold = (alert['minStockLevel'] as num?)?.toDouble() ?? 0;
    if (threshold > 0 && stock <= threshold * 0.4) return 2;
    return 1;
  }
}

class _StockAlertsScreenState extends ConsumerState<StockAlertsScreen> {
  _AlertFilter _filter = _AlertFilter.all;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(stockAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Centre d\'alertes',
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
          // Sort: critical first
          final sorted = [...alerts]..sort((a, b) {
              return StockAlertsScreen.severity(b)
                  .compareTo(StockAlertsScreen.severity(a));
            });

          // Apply filter — "caisse" has no data yet, shows empty state
          final filtered = _filter == _AlertFilter.caisse
              ? <Map<String, dynamic>>[]
              : sorted; // "stock" and "all" show the same stock alerts for now

          final criticalCount =
              sorted.where((a) => StockAlertsScreen.severity(a) == 2).length;
          final warningCount = sorted.length - criticalCount;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(stockAlertsProvider),
            child: CustomScrollView(
              slivers: [
                // Filter chips
                SliverToBoxAdapter(
                  child: _FilterBar(
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                    alertCount: sorted.length,
                  ),
                ),

                // Summary bar
                if (filtered.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SummaryBar(
                      criticalCount: criticalCount,
                      warningCount: warningCount,
                    ),
                  ),

                // Alert list or empty state
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(filter: _filter),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _AlertCard(
                        alert: filtered[index],
                        key: Key('alert_${filtered[index]['catalogItemId']}'),
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
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _AlertFilter selected;
  final ValueChanged<_AlertFilter> onChanged;
  final int alertCount;

  const _FilterBar({
    required this.selected,
    required this.onChanged,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: _AlertFilter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => onChanged(f),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
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
    final normalLevel = (alert['normalStockLevel'] as num?)?.toDouble() ??
        (threshold > 0 ? threshold * 4 : (stock + deficit) * 2);
    final catalogItemId = alert['catalogItemId']?.toString();
    final isCritical = StockAlertsScreen.severity(alert) == 2;

    final severityColor =
        isCritical ? AppColors.error : Colors.orange.shade700;
    final severityLabel = isCritical ? 'Critique' : 'Attention';

    // Stock level as fraction of normal level (clamped 0–1)
    final stockPct =
        normalLevel > 0 ? (stock / normalLevel).clamp(0.0, 1.0) : 0.0;
    final thresholdPct =
        normalLevel > 0 ? (threshold / normalLevel).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: severityColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.inventory_2_outlined,
                                size: 16, color: severityColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: severityColor.withValues(alpha: 0.1),
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
                                const SizedBox(height: 2),
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          // Reappro action
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
                                    size: 16, color: AppColors.primary),
                                const SizedBox(height: 2),
                                Text(
                                  'Réappro.',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Stock info chips
                      Row(
                        children: [
                          _InfoChip(
                              label: 'En stock',
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

                      const SizedBox(height: 10),

                      // Stock level progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Niveau actuel',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary)),
                              Text(
                                '${(stockPct * 100).round()}%',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: severityColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Stack(
                            children: [
                              // Background track
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              // Threshold marker
                              if (thresholdPct > 0)
                                Positioned(
                                  left: null,
                                  child: FractionallySizedBox(
                                    widthFactor: thresholdPct,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade200,
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              // Fill bar
                              FractionallySizedBox(
                                widthFactor: stockPct,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: severityColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
  final _AlertFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isCaisse = filter == _AlertFilter.caisse;
    return Center(
      key: const Key('stock_alerts_empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCaisse
                ? Icons.point_of_sale_outlined
                : Icons.check_circle_outline,
            size: 64,
            color: isCaisse ? AppColors.textSecondary : AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            isCaisse ? 'Aucune alerte caisse' : 'Aucun stock critique',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            isCaisse
                ? 'Les alertes de caisse apparaîtront ici.'
                : 'Tous vos articles sont au-dessus\ndes seuils d\'alerte.',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
