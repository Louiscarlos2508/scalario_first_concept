import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/core/auth/auth_state.dart';

class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return Column(
      children: [
        // Category Selector
        SizedBox(
          height: 60,
          child: categoriesAsync.when(
            data: (categories) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: selectedCategoryId == null,
                    onSelected: (selected) {
                      ref.read(selectedCategoryIdProvider.notifier).state = null;
                    },
                  ),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: selectedCategoryId == c.remoteId,
                        onSelected: (selected) {
                          ref.read(selectedCategoryIdProvider.notifier).state = selected ? c.remoteId : null;
                        },
                      ),
                    )),
              ],
            ),
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('No products found.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        ref.read(cartProvider.notifier).addProduct(product);
                      },
                      onLongPress: () => _showBranchStock(context, ref, product),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2, size: 48, color: Colors.teal),
                          const SizedBox(height: 8),
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  void _showBranchStock(BuildContext context, WidgetRef ref, dynamic product) async {
    if (product.barcode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product has no barcode for lookup')),
      );
      return;
    }

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: ref.read(productRepositoryProvider).getStockAcrossBranches(product.barcode!, user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final stocks = snapshot.data ?? [];

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stock across branches: ${product.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                if (stocks.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No other branches found with this product.')),
                ...stocks.map((s) => ListTile(
                  title: Text(s['tenant']['name']),
                  trailing: Text(
                    '${s['stockQuantity']} left',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (s['stockQuantity'] as num) > 5 ? Colors.green : Colors.red,
                    ),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
