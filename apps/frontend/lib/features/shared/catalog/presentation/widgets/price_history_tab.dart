import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/price_history_provider.dart';
import 'package:intl/intl.dart';

/// AC5 (Story 26-5) — Price history tab for dynamic-priced catalog items.
class PriceHistoryTab extends ConsumerWidget {
  final String catalogItemId;

  const PriceHistoryTab({super.key, required this.catalogItemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(priceHistoryProvider(catalogItemId));
    final dateFormat = DateFormat('dd/MM/yyyy');
    final priceFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur : $err', style: const TextStyle(color: AppColors.error))),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('Aucun historique de prix.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Chart (only when ≥ 2 data points)
            if (entries.length >= 2) ...[
              Text('Évolution du prix', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: _PriceLineChart(entries: entries),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Pas encore assez de données pour afficher un graphique.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
            // History list (most recent first)
            Text('Historique', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            ...entries.map((e) => ListTile(
              key: Key('price_history_${e.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.price_change_outlined, color: AppColors.primary),
              title: Text(priceFormat.format(e.price), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(dateFormat.format(e.effectiveFrom), style: const TextStyle(fontSize: 12)),
              trailing: e.reason != null
                  ? Text(e.reason!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                  : null,
            )),
          ],
        );
      },
    );
  }
}

class _PriceLineChart extends StatelessWidget {
  final List<PriceHistoryEntry> entries;

  const _PriceLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Entries are newest-first — reverse for chronological x-axis
    final sorted = entries.reversed.toList();
    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.price);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPad = maxY == minY ? 500.0 : (maxY - minY) * 0.2;

    return LineChart(
      LineChartData(
        minY: minY - yPad,
        maxY: maxY + yPad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}
