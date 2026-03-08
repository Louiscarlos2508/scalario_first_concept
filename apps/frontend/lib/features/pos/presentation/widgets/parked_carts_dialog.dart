import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';

class ParkedCartsDialog extends ConsumerWidget {
  const ParkedCartsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parked = ref.watch(parkedCartsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Parked Sales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: parked.isEmpty
                ? const Center(child: Text('No parked carts'))
                : ListView.builder(
                    itemCount: parked.length,
                    itemBuilder: (context, index) {
                      final cart = parked[index];
                      return ListTile(
                        title: Text(cart.name ?? 'Unnamed'),
                        subtitle: Text(
                          '${cart.items.length} items - \$${cart.totalAmount.toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ref.read(cartProvider.notifier).replaceCart(cart);
                          ref
                              .read(parkedCartsProvider.notifier)
                              .removeParkedCart(cart);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
