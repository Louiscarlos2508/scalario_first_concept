import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';

void showCartParkDialog(BuildContext context, WidgetRef ref, CartState cart) {
  final controller =
      TextEditingController(text: 'Client ${DateTime.now().minute}');
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: kSheetDialogShape,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetDialogHeader(
              icon: Icons.pause_circle_outline,
              iconColor: kSheetAmber,
              title: 'Mettre en attente',
              subtitle: 'La vente sera sauvegardée',
            ),
            const SizedBox(height: 20),

            TextField(
              controller: controller,
              autofocus: true,
              decoration: sheetInputDecoration(
                label: 'Référence client',
                hint: 'Ex: Table 5, M. Diallo...',
              ),
            ),
            const SizedBox(height: 24),

            SheetActionRow(
              confirmLabel: 'Mettre en attente',
              confirmColor: kSheetAmber,
              onConfirm: () {
                ref
                    .read(parkedCartsProvider.notifier)
                    .parkCart(cart, controller.text);
                ref.read(cartProvider.notifier).clearCart();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
