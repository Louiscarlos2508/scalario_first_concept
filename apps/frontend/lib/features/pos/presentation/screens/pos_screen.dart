import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/product_grid.dart';
import '../widgets/cart_panel.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scalario POS'),
        centerTitle: false,
        actions: [
          IconButton(
             icon: const Icon(Icons.sync), 
             onPressed: () {
               // Trigger manual sync or refresh products
               // ref.read(syncServiceProvider).forceSync();
               // ref.refresh(productListProvider);
             },
             tooltip: 'Sync Now',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Product Grid
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade50,
              child: const ProductGrid(),
            ),
          ),
          
          // Right Side: Cart
          const VerticalDivider(width: 1),
          const CartPanel(),
        ],
      ),
    );
  }
}
