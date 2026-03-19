import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/purchase_orders/data/models/purchase_order_local.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/widgets/receive_purchase_order_sheet.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return Colors.blue;
    case 'partially_received':
      return Colors.orange;
    case 'received':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'draft':
      return 'Brouillon';
    case 'confirmed':
      return 'Confirmé';
    case 'partially_received':
      return 'Partiel';
    case 'received':
      return 'Reçu';
    case 'cancelled':
      return 'Annulé';
    default:
      return status;
  }
}

final _orderDetailProvider =
    FutureProvider.family<PurchaseOrderLocal, String>((ref, id) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) throw Exception('No tenant');
  final repo = ref.watch(purchaseOrdersRepositoryProvider);
  return repo.getOrder(id, tenantId: tenantId);
});

class PurchaseOrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const PurchaseOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_orderDetailProvider(orderId));

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Détail commande',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_orderDetailProvider(orderId)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erreur : $err',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (order) => _DetailBody(order: order, orderId: orderId),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final PurchaseOrderLocal order;
  final String orderId;

  const _DetailBody({required this.order, required this.orderId});

  bool get _canReceive =>
      order.status == 'confirmed' || order.status == 'partially_received';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = order.expectedDate != null
        ? '${order.expectedDate!.day.toString().padLeft(2, '0')}/${order.expectedDate!.month.toString().padLeft(2, '0')}/${order.expectedDate!.year}'
        : 'Non définie';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.supplierName ?? 'Fournisseur inconnu',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        label: Text(
                          _statusLabel(order.status),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: _statusColor(order.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Date prévue', value: dateStr),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _InfoRow(label: 'Notes', value: order.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Articles commandés',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),

          // Lines list
          ...order.lines.map((line) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(line.itemName ?? line.catalogItemId ?? '—'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Commandé : ${line.expectedQuantity}'),
                      if (line.receivedQuantity != null)
                        Text(
                          'Reçu : ${line.receivedQuantity}',
                          style: TextStyle(
                            color: line.receivedQuantity! >=
                                    line.expectedQuantity
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      if (line.qualityNotes != null &&
                          line.qualityNotes!.isNotEmpty)
                        Text('Notes : ${line.qualityNotes}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                    ],
                  ),
                ),
              )),

          if (order.lines.isEmpty)
            const Center(
              child: Text('Aucune ligne',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),

          const SizedBox(height: 24),

          if (_canReceive)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('receive_button'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Réceptionner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _openReceiveSheet(context, ref),
              ),
            ),
        ],
      ),
    );
  }

  void _openReceiveSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReceivePurchaseOrderSheet(
        order: order,
        onSuccess: () {
          ref.invalidate(_orderDetailProvider(orderId));
          ref.invalidate(purchaseOrdersProvider);
          ref.invalidate(purchaseOrderStatsProvider);
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
