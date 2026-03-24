import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';

/// Dashboard line chart panel.
/// Registered as SDUI type `line_chart`.
/// Reads [salesStatsProvider] via ref.watch.
/// [title] comes from the SDUI layout JSON `title` property.
class LineChartWidget extends ConsumerWidget {
  final String title;

  const LineChartWidget({super.key, this.title = 'Ventes'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(salesStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) {
              if (stats.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Aucune donnée de ventes',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                );
              }
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.only(top: 16, right: 16, left: 8),
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.textPrimary,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final formatted = spot.y
                                .toStringAsFixed(0)
                                .replaceAllMapped(
                                  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                  (m) => '${m[1]} ',
                                );
                            return LineTooltipItem(
                              '$formatted FCFA',
                              const TextStyle(
                                color: AppColors.surface,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= stats.length) {
                              return const SizedBox();
                            }
                            // Noms de jours FR abrégés (lundi=1 … dimanche=7).
                            const dayAbbr = [
                              'lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'
                            ];
                            final label = stats.length <= 7
                                ? dayAbbr[
                                    stats[index].day.weekday - 1]
                                : DateFormat('dd/MM').format(stats[index].day);
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(label, style: AppTextStyles.labelSmall),
                            );
                          },
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, meta) {
                            // N'afficher que min et max auto calculés par fl_chart.
                            if (value == meta.min || value == meta.max) {
                              return const SizedBox();
                            }
                            final label = value >= 1000000
                                ? '${(value / 1000000).toStringAsFixed(1)}M'
                                : value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(0)}k'
                                    : value.toStringAsFixed(0);
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                label,
                                style: AppTextStyles.labelSmall,
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: stats
                            .asMap()
                            .entries
                            .map((e) =>
                                FlSpot(e.key.toDouble(), e.value.revenue))
                            .toList(),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
