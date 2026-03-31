import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_customer_header.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_footer.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_header.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_item_list.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final isManager =
        userProfile?.role == 'manager' || userProfile?.role == 'owner';

    // Listen for checkout errors — success is handled by ReceiptDialog
    ref.listen(checkoutControllerProvider, (_, state) {
      state.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de paiement : $err'),
            backgroundColor: Colors.red,
          ),
        ),
      );
    });

    // AC2 — Parent stock low warning snackbar
    ref.listen(parentStockWarningProvider, (_, warning) {
      if (warning == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('snackbar_parent_stock_low'),
          content: Text(warning),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      ref.read(parentStockWarningProvider.notifier).state = null;
    });

    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          const CartHeader(),
          const CartCustomerHeader(),
          Expanded(child: CartItemList(isManager: isManager)),
          const CartFooter(),
        ],
      ),
    );
  }
}
