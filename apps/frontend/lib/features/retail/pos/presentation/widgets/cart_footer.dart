import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_actions_bar.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_helpers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_split_payment_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/receipt_dialog.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/serial_input_dialog.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'prescription_input_dialog.dart';

class CartFooter extends ConsumerWidget {
  const CartFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final role = userProfile?.role ?? '';
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final canAccessClientOrders = config != null
        ? config.canAccess(role, 'client_orders')
        : (role == 'commercial' ||
            role == 'manager' ||
            role == 'owner' ||
            role == 'cashier');

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total :',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                fcfa(cartState.totalAmount),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CartActionsBar(
            cartState: cartState,
            userRole: role,
            canAccessClientOrders: canAccessClientOrders,
            userId: userProfile?.id,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: cartState.items.isEmpty || checkoutState.isLoading
                  ? null
                  : () async {
                      final session =
                          ref.read(sessionProvider).valueOrNull;
                      final selectedCustomer =
                          ref.read(selectedCustomerProvider);

                      if (cartState.paymentMethod == 'CREDIT' &&
                          selectedCustomer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Veuillez sélectionner un client pour une vente à crédit'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Epic 26 — Collect serial numbers for items that require tracking
                      CartState effectiveCart = cartState;
                      for (int i = 0;
                          i < cartState.items.length;
                          i++) {
                        final item = cartState.items[i];
                        if (item.isFreeItem) continue;
                        final trackSerial =
                            item.product.trackSerialNumbers;
                        if (trackSerial && item.serialNumber == null) {
                          if (!context.mounted) return;
                          final serial = await showSerialInputDialog(
                            context,
                            productName: item.product.name,
                          );
                          if (serial == null) return;
                          final updatedItems =
                              List<CartItem>.from(effectiveCart.items);
                          updatedItems[i] =
                              updatedItems[i].copyWith(serialNumber: serial);
                          effectiveCart =
                              effectiveCart.copyWith(items: updatedItems);
                        }
                      }

                      // Epic 26 — Prescription dialog (AC2 — FR94)
                      final needsPrescription = effectiveCart.items.any(
                        (i) => !i.isFreeItem && i.product.requiresPrescription,
                      );
                      if (needsPrescription) {
                        if (!context.mounted) return;
                        final rx = await showPrescriptionDialog(context);
                        if (rx == null) return;
                        effectiveCart =
                            effectiveCart.copyWith(prescriptionData: rx);
                      }

                      final order = await ref
                          .read(checkoutControllerProvider.notifier)
                          .checkout(effectiveCart, session?.remoteId);
                      if (order != null && context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => ReceiptDialog(
                            order: order,
                            cartSnapshot: effectiveCart,
                          ),
                        );
                      }
                    },
              child: checkoutState.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ENCAISSER'),
            ),
          ),
          // Sélecteur de mode de paiement
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('Mode :',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                DropdownButton<String>(
                  value: cartState.paymentMethod,
                  underline: Container(),
                  items: (ref
                              .watch(enabledPaymentMethodsProvider)
                              .valueOrNull ??
                          kDefaultPaymentMethods)
                      .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(paymentMethodLabel(code),
                              style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(cartProvider.notifier)
                          .updatePaymentMethod(val);
                    }
                  },
                ),
                if (cartState.paymentMethod == 'SPLIT')
                  IconButton(
                    icon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16),
                    onPressed: () => showSplitPaymentDialog(
                        context, ref, cartState),
                    tooltip: 'Configurer le paiement fractionné',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
