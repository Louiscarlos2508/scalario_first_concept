import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/inventory/presentation/widgets/delivery_form.dart';
import 'package:frontend/features/retail/inventory/presentation/widgets/transfer_out_form.dart';
import 'package:frontend/features/retail/inventory/presentation/widgets/transfer_pending_screen.dart';
import 'package:frontend/features/retail/inventory/presentation/widgets/loss_declaration_form.dart';
import 'package:frontend/features/retail/inventory/presentation/screens/partial_inventory_screen.dart';

class InventoryScreen extends ConsumerWidget {
  final int initialIndex;

  const InventoryScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(inventoryRepositoryProvider);

    return DefaultTabController(
      length: 4,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: const ScalarioAppBar(
          title: 'Inventaire',
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Réceptions'),
              Tab(icon: Icon(Icons.swap_horiz_outlined), text: 'Transferts'),
              Tab(icon: Icon(Icons.remove_circle_outline), text: 'Pertes'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Comptage'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReceptionsTab(repo: repo),
            _TransfersTab(repo: repo),
            _LossTab(repo: repo),
            _InventoryCountTab(repo: repo),
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
