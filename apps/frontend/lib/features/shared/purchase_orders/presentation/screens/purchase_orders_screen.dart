import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/purchase_orders/data/models/purchase_order_local.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/screens/purchase_order_detail_screen.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/widgets/create_purchase_order_sheet.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/widgets/receive_purchase_order_sheet.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';

// Status chip color mapping
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

class PurchaseOrdersScreen extends ConsumerWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(purchaseOrdersProvider);
    final activeFilter = ref.watch(purchaseOrdersFilterProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Achats',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(purchaseOrdersProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('po_fab'),
        heroTag: null,
        onPressed: () => _openCreateSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                    label: 'Tous',
                    value: null,
                    active: activeFilter == null,
                    ref: ref),
                const SizedBox(width: 6),
                _FilterChip(
                    label: 'Brouillon',
                    value: 'draft',
                    active: activeFilter == 'draft',
                    ref: ref),
                const SizedBox(width: 6),
                _FilterChip(
                    label: 'Confirmé',
                    value: 'confirmed',
                    active: activeFilter == 'confirmed',
                    ref: ref),
                const SizedBox(width: 6),
                _FilterChip(
                    label: 'Partiel',
                    value: 'partially_received',
                    active: activeFilter == 'partially_received',
                    ref: ref),
                const SizedBox(width: 6),
                _FilterChip(
                    label: 'Reçu',
                    value: 'received',
                    active: activeFilter == 'received',
                    ref: ref),
                const SizedBox(width: 6),
                _FilterChip(
                    label: 'Annulé',
                    value: 'cancelled',
                    active: activeFilter == 'cancelled',
                    ref: ref),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ordersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Erreur : $err',
                    style:
                        const TextStyle(color: AppColors.error)),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    key: const Key('po_empty_state'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart_outlined,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucune commande',
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          key: const Key('po_empty_cta'),
                          icon: const Icon(Icons.add),
                          label:
                              const Text('Créer la première commande'),
                          onPressed: () => _openCreateSheet(context),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) =>
                      _PurchaseOrderCard(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const CreatePurchaseOrderSheet(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final bool active;
  final WidgetRef ref;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.active,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        ref.read(purchaseOrdersFilterProvider.notifier).state = value;
        ref.invalidate(purchaseOrdersProvider);
      },
    );
  }
}

class _PurchaseOrderCard extends ConsumerWidget {
  final PurchaseOrderLocal order;

  const _PurchaseOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = order.expectedDate != null
        ? '${order.expectedDate!.day.toString().padLeft(2, '0')}/${order.expectedDate!.month.toString().padLeft(2, '0')}/${order.expectedDate!.year}'
        : 'Date non définie';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PurchaseOrderDetailScreen(orderId: order.id),
          ),
        ),
        onLongPress: () => _showContextMenu(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.supplierName ?? 'Fournisseur inconnu',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(dateStr,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('${order.lineCount} article(s)',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      _statusLabel(order.status),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _statusColor(order.status),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              if (order.status == 'confirmed' ||
                  order.status == 'partially_received') ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: Key('po_receive_${order.id}'),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text('Réceptionner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _openReceiveSheet(context, ref),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReceiveSheet(BuildContext context, WidgetRef ref) async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;

    final repo = ref.read(purchaseOrdersRepositoryProvider);

    try {
      final fullOrder = await repo.getOrder(order.id, tenantId: tenantId);
      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => ReceivePurchaseOrderSheet(
          order: fullOrder,
          onSuccess: () => ref.invalidate(purchaseOrdersProvider),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    if (order.status != 'draft') return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline,
                  color: Colors.blue),
              title: const Text('Confirmer la commande'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _confirmOrder(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;

    try {
      final repo = ref.read(purchaseOrdersRepositoryProvider);
      await repo.updateStatus(order.id, 'confirmed', tenantId);
      ref.invalidate(purchaseOrdersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande confirmée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
