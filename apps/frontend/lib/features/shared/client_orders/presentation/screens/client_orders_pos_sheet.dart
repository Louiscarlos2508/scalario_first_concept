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
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userId = ref.watch(userProfileProvider).valueOrNull?.id;
    final ordersAsync = ref.watch(
      clientOrdersProvider(ClientOrdersFilter(createdBy: userId)),
    );

    return ordersAsync.when(
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
          onRefresh: () async => ref.invalidate(
            clientOrdersProvider(ClientOrdersFilter(createdBy: userId)),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                _OrderTile(order: orders[index]),
          ),
        );
      },
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
