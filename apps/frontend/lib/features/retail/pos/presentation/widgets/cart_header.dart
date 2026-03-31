import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/parked_carts_dialog.dart';

class CartHeader extends ConsumerWidget {
  const CartHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider).items;

    return AppBar(
      title: const Text('Panier', style: TextStyle(color: Colors.black)),
      backgroundColor: Colors.white,
      elevation: 1,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          onPressed: () {
            final parked = ref.watch(parkedCartsProvider);
            if (parked.isEmpty) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (context) => const ParkedCartsDialog(),
            );
          },
          icon: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
          tooltip: 'Ventes en attente',
        ),
        IconButton(
          onPressed: cartItems.isEmpty
              ? null
              : () => ref.read(cartProvider.notifier).clearCart(),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
      ],
    );
  }
}
