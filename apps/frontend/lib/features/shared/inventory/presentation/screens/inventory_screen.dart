import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/delivery_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_out_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_pending_screen.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/loss_declaration_form.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/partial_inventory_screen.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/screens/purchase_orders_screen.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';

class InventoryScreen extends ConsumerWidget {
  final int initialIndex;

  const InventoryScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(inventoryRepositoryProvider);
    final statsAsync = ref.watch(purchaseOrderStatsProvider);
    final pendingCount = statsAsync.valueOrNull?['total'] ?? 0;

    return DefaultTabController(
      length: 5,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: ScalarioAppBar(
          title: 'Inventaire',
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Réceptions'),
              const Tab(icon: Icon(Icons.swap_horiz_outlined), text: 'Transferts'),
              const Tab(icon: Icon(Icons.remove_circle_outline), text: 'Pertes'),
              const Tab(icon: Icon(Icons.fact_check_outlined), text: 'Comptage'),
              Tab(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                text: 'Commandes',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReceptionsTab(repo: repo),
            _TransfersTab(repo: repo),
            _LossTab(repo: repo),
            _InventoryCountTab(repo: repo),
            const PurchaseOrdersScreen(),
          ],
        ),
      ),
    );
  }
}

// ─── Réceptions tab ───────────────────────────────────────────────────────────

class _ReceptionsTab extends StatelessWidget {
  final dynamic repo;

  const _ReceptionsTab({required this.repo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DeliveryForm(repository: repo),
    );
  }
}

// ─── Transferts tab ───────────────────────────────────────────────────────────

class _TransfersTab extends StatelessWidget {
  final dynamic repo;

  const _TransfersTab({required this.repo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TransferOutForm(repository: repo),
          const SizedBox(height: 16),
          TransferPendingScreen(repository: repo),
        ],
      ),
    );
  }
}

// ─── Pertes tab ───────────────────────────────────────────────────────────────

class _LossTab extends StatelessWidget {
  final dynamic repo;

  const _LossTab({required this.repo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LossDeclarationForm(repository: repo),
    );
  }
}

// ─── Inventaire (comptage) tab ────────────────────────────────────────────────

class _InventoryCountTab extends StatelessWidget {
  final dynamic repo;

  const _InventoryCountTab({required this.repo});

  @override
  Widget build(BuildContext context) {
    return PartialInventoryScreen(repository: repo, embedded: true);
  }
}
