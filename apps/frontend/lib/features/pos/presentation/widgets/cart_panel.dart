import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);

    // Listen for errors/success
    ref.listen(checkoutControllerProvider, (_, state) {
      state.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout Failed: $err'), backgroundColor: Colors.red),
        ),
        data: (_) {
           // Success handling is usually silent or clear cart (which logic does), 
           // but we can add a snackbar here if we want explicit confirmation beyond cart clearing.
        },
      );
    });

    return Container(
      width: 350,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          AppBar(
            title: const Text('Current Sale', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 1,
            automaticallyImplyLeading: false, 
            actions: [
              IconButton(onPressed: () => ref.read(cartProvider.notifier).clearCart(), icon: const Icon(Icons.delete_outline, color: Colors.red))
            ]
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cartState.items.length,
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text('${item.quantity} x \$${item.product.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => ref.read(cartProvider.notifier).removeProduct(item.product),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('\$${cartState.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: cartState.items.isEmpty || checkoutState.isLoading 
                      ? null 
                      : () {
                         ref.read(checkoutControllerProvider.notifier).checkout(cartState);
                      },
                    child: checkoutState.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('PAY & PRINT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
