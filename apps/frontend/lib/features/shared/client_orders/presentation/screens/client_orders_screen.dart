import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_order_detail_screen.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_order_form_screen.dart';
import 'package:frontend/features/shared/client_orders/presentation/widgets/client_order_card.dart';

const _statusOptions = [
  ('draft', 'Brouillon'),
  ('confirmed', 'Confirmée'),
  ('in-progress', 'En cours'),
  ('ready', 'Prête'),
  ('delivered', 'Livrée'),
  ('cancelled', 'Annulée'),
];

class ClientOrdersScreen extends ConsumerStatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  ConsumerState<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends ConsumerState<ClientOrdersScreen> {
  String? _selectedStatus;
  final _customerController = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  ClientOrdersFilter get _filter => ClientOrdersFilter(
        status: _selectedStatus,
        customerName: _customerController.text.trim().isEmpty
            ? null
            : _customerController.text.trim(),
        dateFrom: _dateRange?.start,
        dateTo: _dateRange?.end,
      );

  void _refresh() => ref.invalidate(clientOrdersProvider(_filter));

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role;
    final ordersAsync = ref.watch(clientOrdersProvider(_filter));

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Commandes',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const ClientOrderFormScreen(),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(context),
          const Divider(height: 1),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('Aucune commande pour le moment'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final order = orders[i];
                      return ClientOrderCard(
                        order: order,
                        userRole: role,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientOrderDetailScreen(
                                orderId: order.id),
                          ),
                        ),
                        onConfirm: (role == 'owner' || role == 'manager') &&
                                order.status == 'draft'
                            ? () async {
                                final tenantId =
                                    ref.read(activeTenantProvider) ?? '';
                                final repo =
                                    ref.read(clientOrderRepositoryProvider);
                                await repo.confirmOrder(order.id,
                                    tenantId: tenantId);
                                _refresh();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Commande validée'),
                                        backgroundColor: Colors.green),
                                  );
                                }
                              }
                            : null,
                        onPrepare: order.status == 'confirmed'
                            ? () async {
                                final tenantId =
                                    ref.read(activeTenantProvider) ?? '';
                                final repo =
                                    ref.read(clientOrderRepositoryProvider);
                                await repo.prepareOrder(order.id,
                                    tenantId: tenantId);
                                _refresh();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Commande en préparation'),
                                        backgroundColor: Colors.orange),
                                  );
                                }
                              }
                            : null,
                        onDeliver: (order.status == 'in-progress' ||
                                order.status == 'ready')
                            ? () async {
                                // Navigation vers livraison — Story 30-5
                              }
                            : null,
                        onCancel: (role == 'owner' || role == 'manager') &&
                                (order.status == 'draft' ||
                                    order.status == 'confirmed')
                            ? () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Annuler la commande'),
                                    content: Text(
                                        'Confirmer l\'annulation de ${order.orderNumber} ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Retour'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Annuler la commande'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                final tenantId =
                                    ref.read(activeTenantProvider) ?? '';
                                final repo =
                                    ref.read(clientOrderRepositoryProvider);
                                await repo.cancelOrder(order.id,
                                    tenantId: tenantId);
                                _refresh();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Commande annulée'),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            : null,
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Erreur : $e'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: _selectedStatus == null,
                  onSelected: (_) =>
                      setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 6),
                ..._statusOptions.map((opt) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(opt.$2),
                        selected: _selectedStatus == opt.$1,
                        onSelected: (sel) => setState(() =>
                            _selectedStatus = sel ? opt.$1 : null),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Client search
              Expanded(
                child: TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher client…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  onSubmitted: (_) => _refresh(),
                  onChanged: (_) {
                    if (_customerController.text.isEmpty) _refresh();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Date range picker
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _dateRange == null
                      ? 'Période'
                      : '${DateFormat('dd/MM').format(_dateRange!.start)}–${DateFormat('dd/MM').format(_dateRange!.end)}',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _dateRange,
                  );
                  if (picked != null) {
                    setState(() => _dateRange = picked);
                  }
                },
              ),
              if (_dateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Effacer la période',
                  onPressed: () => setState(() => _dateRange = null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
