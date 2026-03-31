import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';

import 'package:frontend/features/shared/client_orders/presentation/screens/client_order_form_screen.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ClientOrdersPosSheet extends StatefulWidget {
  const ClientOrdersPosSheet({super.key});

  @override
  State<ClientOrdersPosSheet> createState() => _ClientOrdersPosSheetState();
}

class _ClientOrdersPosSheetState extends State<ClientOrdersPosSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: const [
              Icon(Icons.assignment_outlined, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Commandes clients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // ── TabBar ────────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_circle_outline, size: 20),
              text: 'Nouvelle',
            ),
            Tab(
              icon: Icon(Icons.list_alt_outlined, size: 20),
              text: 'Mes commandes',
            ),
          ],
        ),

        const Divider(height: 1),

        // ── TabBarView ────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet 1 — Formulaire nouvelle commande
              SingleChildScrollView(
                child: ClientOrderFormScreen(
                  isEmbedded: true,
                  onCreated: () => _tabController.animateTo(1),
                ),
              ),
              // Onglet 2 — Liste mes commandes (kept alive)
              const _MyOrdersList(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Onglet "Mes commandes" ────────────────────────────────────────────────────

class _MyOrdersList extends ConsumerStatefulWidget {
  const _MyOrdersList();

  @override
  ConsumerState<_MyOrdersList> createState() => _MyOrdersListState();
}

class _MyOrdersListState extends ConsumerState<_MyOrdersList>
    with AutomaticKeepAliveClientMixin {
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(clientOrdersProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userId = ref.watch(userProfileProvider).valueOrNull?.id;
    final filter = ClientOrdersFilter(createdBy: userId);
    final ordersAsync = ref.watch(clientOrdersProvider(filter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              const Text(
                'Mes commandes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Rafraîchir',
                onPressed: () => ref.invalidate(clientOrdersProvider(filter)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune commande',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Créez votre première commande\ndans l\'onglet "Nouvelle"',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(clientOrdersProvider(filter)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _OrderTile(order: orders[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Order tile ────────────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final ClientOrder order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (order.status) {
      'draft' => (Colors.grey, 'Brouillon'),
      'confirmed' => (Colors.blue, 'Confirmée ✓'),
      'in-progress' => (Colors.orange, 'En préparation'),
      'ready' => (Colors.teal, 'Prête à livrer'),
      'delivered' => (Colors.green, 'Livrée'),
      'invoiced' => (Colors.purple, 'Facturée'),
      'paid' => (Colors.green.shade800, 'Payée ✓'),
      'cancelled' => (Colors.red, 'Annulée'),
      _ => (Colors.grey, order.status),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Row(
          children: [
            Text(
              order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
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
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '${DateFormat('dd/MM/yyyy').format(order.createdAt)}'
              ' · ${order.lines.length} article(s)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (order.status == 'draft')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'En attente de confirmation par le responsable',
                      style: TextStyle(
                          fontSize: 10, color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
            if (order.status == 'confirmed')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 12, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Validée — en cours de préparation',
                      style: TextStyle(
                          fontSize: 10, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            if (order.status == 'ready')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 12, color: Colors.teal.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Prête — le client peut venir récupérer',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w600),
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
        onTap: () => showDialog(
          context: context,
          builder: (_) => _PosOrderDetailDialog(order: order),
        ),
      ),
    );
  }
}

// ── Dialog détail commande (vue POS) ─────────────────────────────────────────

class _PosOrderDetailDialog extends ConsumerWidget {
  final ClientOrder order;
  const _PosOrderDetailDialog({required this.order});

  Future<void> _showEncaissementDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final enabledMethods =
        ref.read(enabledPaymentMethodsProvider).valueOrNull ?? kDefaultPaymentMethods;
    final methods = enabledMethods.where((m) => m != 'SPLIT').toList();
    String paymentMethod = methods.contains('CASH') ? 'CASH' : methods.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Encaisser la commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total à encaisser'),
                    Text(
                      _fcfa(order.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: paymentMethod,
                    isDense: true,
                    items: methods
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(paymentMethodLabel(m)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => paymentMethod = v!),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final repo = ref.read(clientOrderRepositoryProvider);
      await repo.payOrder(order.id, tenantId: tenantId, paymentMethod: paymentMethod);
      ref.invalidate(clientOrdersProvider);
      ref.invalidate(clientOrderKpisProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement enregistré ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusColor, statusLabel) = switch (order.status) {
      'draft' => (Colors.grey, 'Brouillon'),
      'confirmed' => (Colors.blue, 'Confirmée ✓'),
      'in-progress' => (Colors.orange, 'En préparation'),
      'ready' => (Colors.teal, 'Prête à livrer'),
      'delivered' => (Colors.green, 'Livrée'),
      'invoiced' => (Colors.purple, 'Facturée'),
      'paid' => (Colors.green.shade800, 'Payée ✓'),
      'cancelled' => (Colors.red, 'Annulée'),
      _ => (Colors.grey, order.status),
    };

    return AlertDialog(
      title: Row(
        children: [
          Text(order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Client', order.customerName ?? 'Client inconnu'),
              _detailRow('Date',
                  DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
              if (order.notes != null && order.notes!.isNotEmpty)
                _detailRow('Notes', order.notes!),
              const Divider(height: 20),
              const Text('Articles',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...order.lines.map((line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            line.itemName ?? line.catalogItemId,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text('×${line.quantity.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        Text(_fcfa(line.quantity * line.unitPrice)),
                      ],
                    ),
                  )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_fcfa(order.totalAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              if (order.status == 'draft') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'En attente de confirmation par le responsable',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (order.status == 'confirmed') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Commande validée — en cours de préparation',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (order.status == 'ready') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 16, color: Colors.teal.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Commande prête — le client peut venir récupérer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (order.status == 'delivered')
          FilledButton.icon(
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Encaisser'),
            onPressed: () {
              Navigator.pop(context);
              _showEncaissementDialog(context, ref);
            },
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
