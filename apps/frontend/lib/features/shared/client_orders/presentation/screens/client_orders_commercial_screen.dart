import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_order_detail_screen.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_order_form_screen.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

({Color color, String label}) _statusChip(String status) => switch (status) {
      'draft' => (color: Colors.grey, label: 'Brouillon'),
      'confirmed' => (color: Colors.blue, label: 'Confirmée ✓'),
      'in-progress' => (color: Colors.orange, label: 'En préparation'),
      'ready' => (color: Colors.teal, label: 'Prête à livrer'),
      'delivered' => (color: Colors.green, label: 'Livrée'),
      'invoiced' => (color: Colors.purple, label: 'Facturée'),
      'paid' => (color: Colors.green, label: 'Payée ✓'),
      'cancelled' => (color: Colors.red, label: 'Annulée'),
      _ => (color: Colors.grey, label: status),
    };

class ClientOrdersCommercialScreen extends ConsumerWidget {
  const ClientOrdersCommercialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userProfileProvider).valueOrNull?.id;
    final ordersAsync = ref.watch(
      clientOrdersProvider(ClientOrdersFilter(createdBy: userId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ClientOrderFormScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune commande pour le moment',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une commande'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClientOrderFormScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(clientOrdersProvider(ClientOrdersFilter(createdBy: userId))),
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) =>
                  _OrderTile(order: orders[index]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final ClientOrder order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final chip = _statusChip(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            Text(
              order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: chip.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: chip.color.withValues(alpha: 0.5)),
              ),
              child: Text(
                chip.label,
                style: TextStyle(
                  fontSize: 11,
                  color: chip.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              order.customerName ?? 'Client inconnu',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              '${DateFormat('dd/MM/yyyy').format(order.createdAt)}'
              ' · ${order.lines.length} article(s)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (order.status == 'draft')
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 13, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'En attente de validation',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Text(
          _fcfa(order.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientOrderDetailScreen(orderId: order.id),
          ),
        ),
      ),
    );
  }
}
