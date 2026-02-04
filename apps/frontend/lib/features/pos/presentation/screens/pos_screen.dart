import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/models/order.dart';
import '../providers/pos_providers.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final productRepo = ref.read(productRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scalario POS')),
      body: Row(
        children: [
          // Product List
          Expanded(
            flex: 2,
            child: FutureBuilder<List<Product>>(
              future: productRepo.getAllProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data ?? [];
                
                if (products.isEmpty) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Seed Data
                        await productRepo.addProduct(Product()
                          ..name = 'Coca Cola'
                          ..price = 1.50
                          ..sku = 'COKE'
                          ..stock = 100);
                        await productRepo.addProduct(Product()
                          ..name = 'Sandwich'
                          ..price = 3.00
                          ..sku = 'SAND'
                          ..stock = 50);
                        // Trigger rebuild (hacky for demo)
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text('Seed Test Products'),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(OrderItem()
                          ..productSku = product.sku
                          ..productName = product.name
                          ..price = product.price
                          ..quantity = 1);
                      },
                      child: Card(
                        color: Colors.blue.shade50,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(product.name, style: Theme.of(context).textTheme.titleLarge),
                            Text('\$${product.price}', style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Cart
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return ListTile(
                          title: Text(item.productName),
                          trailing: Text('\$${item.price}'),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text('Total: \$${ref.read(cartProvider.notifier).total}',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: cart.isEmpty ? null : () async {
                            final order = Order()
                              ..items = cart
                              ..totalAmount = ref.read(cartProvider.notifier).total;
                            
                            await ref.read(orderRepositoryProvider).createOrder(order);
                            ref.read(cartProvider.notifier).clear();
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order Created Successfully!')),
                              );
                            }
                          },
                          child: const Text('PAY'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
