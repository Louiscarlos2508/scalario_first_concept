import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/freshness_chip.dart';
import 'package:frontend/features/shared/freshness/presentation/providers/freshness_provider.dart';
import 'package:frontend/features/shared/freshness/presentation/widgets/declassify_sheet.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

/// AC2 (Story 24-3) — Displays all active batches grouped by freshness level.
class FreshnessScreen extends ConsumerWidget {
  const FreshnessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(freshnessProvider);
    final thresholds = ref.watch(freshnessThresholdsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(freshnessProvider),
      child: batchesAsync.when(
        data: (batches) {
          if (batches.isEmpty) {
            return const _EmptyState();
          }

          // Partition into sections
          final expired = <Map<String, dynamic>>[];
          final urgent = <Map<String, dynamic>>[];
          final watch = <Map<String, dynamic>>[];
          final ok = <Map<String, dynamic>>[];

          for (final b in batches) {
            final percent = (b['freshnessPercent'] as num?)?.toDouble() ?? 0;
            if (percent <= 0) {
              expired.add(b);
            } else if (percent < thresholds.orangeThreshold) {
              urgent.add(b);
            } else if (percent < thresholds.greenThreshold) {
              watch.add(b);
            } else {
              ok.add(b);
            }
          }

          final hasUrgent =
              expired.isNotEmpty || urgent.isNotEmpty || watch.isNotEmpty;

          if (!hasUrgent && ok.isEmpty) {
            return const _EmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (expired.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Expirés',
                  color: Colors.red.shade900,
                  count: expired.length,
                ),
                ...expired.map((b) => _BatchTile(batch: b, thresholds: thresholds)),
                const SizedBox(height: 12),
              ],
              if (urgent.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Urgents',
                  color: Colors.red,
                  count: urgent.length,
                ),
                ...urgent.map((b) => _BatchTile(batch: b, thresholds: thresholds)),
                const SizedBox(height: 12),
              ],
              if (watch.isNotEmpty) ...[
                _SectionHeader(
                  label: 'À surveiller',
                  color: Colors.orange,
                  count: watch.length,
                ),
                ...watch.map((b) => _BatchTile(batch: b, thresholds: thresholds)),
                const SizedBox(height: 12),
              ],
              if (ok.isNotEmpty) ...[
                _SectionHeader(
                  label: 'OK',
                  color: Colors.green,
                  count: ok.length,
                ),
                ...ok.map((b) => _BatchTile(batch: b, thresholds: thresholds)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            'Tous vos lots sont frais',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: color),
          const SizedBox(width: 8),
          Text(
            '$label ($count)',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BatchTile extends ConsumerWidget {
  final Map<String, dynamic> batch;
  final FreshnessThresholds thresholds;

  const _BatchTile({required this.batch, required this.thresholds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemName = batch['itemName']?.toString() ?? '—';
    final remainingQty = (batch['remainingQty'] as num?)?.toDouble() ?? 0;
    final freshnessPercent =
        (batch['freshnessPercent'] as num?)?.toDouble() ?? 0;
    final expiresAtRaw = batch['expiresAt']?.toString();
    final expiresAt = expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;
    // AC3 (Story 26-4) — bestBeforeDate takes priority over expiresAt for freshness color
    final bestBeforeRaw = batch['bestBeforeDate']?.toString();
    final bestBeforeDate = bestBeforeRaw != null ? DateTime.tryParse(bestBeforeRaw) : null;
    final referenceDate = bestBeforeDate ?? expiresAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: referenceDate != null
            ? FreshnessChip(
                expiresAt: referenceDate,
                // approximate expiryDays from freshnessPercent and remaining days
                expiryDays: _inferExpiryDays(referenceDate, freshnessPercent),
                greenThreshold: thresholds.greenThreshold,
                orangeThreshold: thresholds.orangeThreshold,
              )
            : const Icon(Icons.inventory_2_outlined),
        title: Text(itemName),
        // AC4 — show both bestBeforeDate and expiresAt when available
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bestBeforeDate != null)
              Text('Garde optimale : ${_formatDate(bestBeforeDate)}', style: const TextStyle(fontSize: 12)),
            if (expiresAt != null)
              Text(
                'Expire le ${_formatDate(expiresAt)} · ${expiresAt.difference(DateTime.now()).inDays}j restants',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          'Qté : $remainingQty',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onLongPress: () => _showDeclassify(context, ref),
      ),
    );
  }

  int _inferExpiryDays(DateTime expiresAt, double freshnessPercent) {
    if (freshnessPercent <= 0) return 1;
    final remainingDays = expiresAt.difference(DateTime.now()).inHours / 24;
    if (remainingDays <= 0) return 1;
    return ((remainingDays / freshnessPercent) * 100).ceil().clamp(1, 3650);
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  void _showDeclassify(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DeclassifySheet(batch: batch),
    ).then((refreshed) {
      if (refreshed == true) {
        ref.invalidate(freshnessProvider);
      }
    });
  }
}
