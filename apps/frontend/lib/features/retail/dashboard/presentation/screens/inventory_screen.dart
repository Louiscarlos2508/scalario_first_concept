import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/inventory/delivery_form.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/inventory/transfer_out_form.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/inventory/transfer_pending_screen.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/inventory/loss_declaration_form.dart';
import 'package:frontend/features/retail/dashboard/presentation/screens/partial_inventory_screen.dart';

import '../widgets/product_form_dialog.dart';
import '../widgets/stock_adjustment_dialog.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class InventoryScreen extends ConsumerWidget {
  final int initialIndex;

  const InventoryScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(inventoryRepositoryProvider);

    return DefaultTabController(
      length: 5,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventaire'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Produits'),
              Tab(
                  icon: Icon(Icons.local_shipping_outlined),
                  text: 'Réceptions'),
              Tab(icon: Icon(Icons.swap_horiz_outlined), text: 'Transferts'),
              Tab(icon: Icon(Icons.remove_circle_outline), text: 'Pertes'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Inventaire'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProductsTab(),
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

// ─── Produits tab (existing product list) ─────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginatedAsync = ref.watch(paginatedProductListProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(inventorySearchProvider.notifier).state = value;
                      ref.read(inventoryPageProvider.notifier).state = 1;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.refresh(paginatedProductListProvider),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          Expanded(
            child: paginatedAsync.when(
              data: (data) => _buildTable(context, ref, data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur : $err')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context,
    WidgetRef ref, [
    Product? product,
  ]) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );

    if (result != null) {
      try {
        await ref.read(productRepositoryProvider).syncProduct(result);
        ref.refresh(paginatedProductListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                product == null ? 'Produit créé' : 'Produit mis à jour',
              ),
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

  Future<void> _showAdjustmentDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StockAdjustmentDialog(product: product),
    );

    if (result != null && product.remoteId != null) {
      try {
        await ref.read(productRepositoryProvider).adjustStock(
              productId: product.remoteId!,
              quantity: result['quantity'],
              type: result['type'],
              reason: result['reason'],
            );
        ref.refresh(paginatedProductListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Stock ajusté')));
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

  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    final List<Product> products = data['items'];
    final int total = data['total'];
    final int totalPages = data['totalPages'];
    final int currentPage = ref.watch(inventoryPageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor:
                      WidgetStateProperty.all(AppColors.background),
                  columns: const [
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Code-barres')),
                    DataColumn(label: Text('Prix')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: products.map((product) {
                    return DataRow(
                      onSelectChanged: (_) =>
                          _showProductDialog(context, ref, product),
                      cells: [
                        DataCell(Text(product.name)),
                        DataCell(Text(product.barcode ?? '-')),
                        DataCell(Text(_fcfa(product.price))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.stockQuantity <= 5
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.stockQuantity.toString(),
                              style: TextStyle(
                                color: product.stockQuantity <= 5
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history, size: 20),
                                tooltip: 'Ajuster le stock',
                                onPressed: () => _showAdjustmentDialog(
                                    context, ref, product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () =>
                                    _showProductDialog(context, ref, product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: AppColors.error),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title:
                                          const Text('Supprimer le produit ?'),
                                      content: Text(
                                          'Supprimer ${product.name} définitivement ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Supprimer',
                                              style: TextStyle(
                                                  color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true &&
                                      product.remoteId != null) {
                                    await ref
                                        .read(productRepositoryProvider)
                                        .deleteProductRemote(product.remoteId!);
                                    ref.refresh(paginatedProductListProvider);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total : $total article(s)'),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => ref
                          .read(inventoryPageProvider.notifier)
                          .state = currentPage - 1
                    : null,
              ),
              Text('Page $currentPage / $totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => ref
                          .read(inventoryPageProvider.notifier)
                          .state = currentPage + 1
                    : null,
              ),
            ],
          ),
        ],
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
    return PartialInventoryScreen(repository: repo);
  }
}
