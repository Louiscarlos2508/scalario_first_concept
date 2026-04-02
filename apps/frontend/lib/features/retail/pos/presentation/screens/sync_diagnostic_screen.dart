import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/core/models/sync_status.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Liste des ordres en état [SyncStatus.failed] (outbox définitivement bloquée).
final failedOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getFailedOrders();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Fix 3 — Écran diagnostic admin : visualise les ordres en état `failed`
/// (outbox bloquée après [TransactionSyncAdapter._maxRetries] tentatives)
/// et permet un retry manuel.
///
/// Accès : réservé aux profils owner/manager via contrôle d'accès existant.
class SyncDiagnosticScreen extends ConsumerWidget {
  const SyncDiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failedOrdersAsync = ref.watch(failedOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Forcer un sync',
            onPressed: () => ref.read(syncServiceProvider).forceSync(),
          ),
        ],
      ),
      body: failedOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Aucun ordre bloqué',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _FailedOrderTile(order: order);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile
// ---------------------------------------------------------------------------

class _FailedOrderTile extends ConsumerWidget {
  final Order order;
  const _FailedOrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ordre ${order.uuid.substring(0, 8)}…',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusChip(order.syncStatus),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow('Montant',
                '${order.totalAmount.toStringAsFixed(2)} ${_currency()}'),
            _InfoRow('Créé le', _formatDate(order.createdAt)),
            _InfoRow('Articles', '${order.items.length}'),
            if (order.sessionId != null)
              _InfoRow('Session', order.sessionId!.substring(0, 8)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier UUID'),
                  onPressed: () => _copyToClipboard(context, order.uuid),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Retenter'),
                  onPressed: () => _retryOrder(context, ref, order.uuid),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryOrder(
      BuildContext context, WidgetRef ref, String uuid) async {
    final repo = ref.read(orderRepositoryProvider);
    await repo.retryFailedOrder(uuid);
    ref.invalidate(failedOrdersProvider);
    ref.read(syncServiceProvider).forceSync();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ordre ${uuid.substring(0, 8)}… remis en file'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    // Clipboard non importé pour éviter une dépendance supplémentaire —
    // accessible via la sélection du texte dans le tile.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(text),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _currency() => 'FCFA';

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SyncStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
