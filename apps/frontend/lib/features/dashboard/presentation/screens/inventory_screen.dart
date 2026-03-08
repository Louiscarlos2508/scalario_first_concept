import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../pos/presentation/providers/pos_providers.dart';
import '../../../pos/data/models/product.dart';

import '../widgets/product_form_dialog.dart';
import '../widgets/stock_adjustment_dialog.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginatedProductsAsync = ref.watch(paginatedProductListProvider);
    final searchQuery = ref.watch(inventorySearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          // Search Bar
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                ref.read(inventorySearchProvider.notifier).state = value;
                ref.read(inventoryPageProvider.notifier).state =
                    1; // Reset to page 1
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(paginatedProductListProvider);
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: paginatedProductsAsync.when(
        data: (data) => _buildProductTable(context, ref, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
                product == null ? 'Product created' : 'Product updated',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
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
        await ref
            .read(productRepositoryProvider)
            .adjustStock(
              productId: product.remoteId!,
              quantity: result['quantity'],
              type: result['type'],
              reason: result['reason'],
            );
        ref.refresh(paginatedProductListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock adjusted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildProductTable(
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
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Barcode')),
                    DataColumn(label: Text('Price')),
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
                        DataCell(
                          Text('\$ ${product.price.toStringAsFixed(2)}'),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.stockQuantity <= 5
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.stockQuantity.toString(),
                              style: TextStyle(
                                color: product.stockQuantity <= 5
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
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
                                tooltip: 'Adjust Stock',
                                onPressed: () => _showAdjustmentDialog(
                                  context,
                                  ref,
                                  product,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () =>
                                    _showProductDialog(context, ref, product),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Product?'),
                                      content: Text(
                                        'Are you sure you want to delete ${product.name}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
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
          // Pagination Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total: $total items'),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => ref.read(inventoryPageProvider.notifier).state =
                          currentPage - 1
                    : null,
              ),
              Text('Page $currentPage of $totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => ref.read(inventoryPageProvider.notifier).state =
                          currentPage + 1
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
