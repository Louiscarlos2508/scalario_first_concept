import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';

void showCartParkDialog(
    BuildContext context, WidgetRef ref, CartState cart) {
  final controller =
      TextEditingController(text: 'Client ${DateTime.now().minute}');
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mettre en attente'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Référence'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            ref
                .read(parkedCartsProvider.notifier)
                .parkCart(cart, controller.text);
            ref.read(cartProvider.notifier).clearCart();
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}
