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
    final canAccessClientOrders = role != 'cashier' &&
        (config != null
            ? config.canAccess(role, 'client_orders')
            : (role == 'commercial' ||
                role == 'manager' ||
                role == 'owner'));
    final methods = ref.watch(enabledPaymentMethodsProvider).valueOrNull ??
        kDefaultPaymentMethods;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Actions bar ────────────────────────────────────────────────
          CartActionsBar(
            cartState: cartState,
            userRole: role,
            canAccessClientOrders: canAccessClientOrders,
            userId: userProfile?.id,
          ),
          const SizedBox(height: 10),

          // ── Total row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                fcfa(cartState.totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Payment method chips ───────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final method in methods)
                _PayChip(
                  label: method.label,
                  selected: cartState.paymentMethod == method.code,
                  onTap: () => ref
                      .read(cartProvider.notifier)
                      .updatePaymentMethod(method.code),
                ),
              if (cartState.paymentMethod == 'SPLIT')
                GestureDetector(
                  onTap: () =>
                      showSplitPaymentDialog(context, ref, cartState),
                  child: const Tooltip(
                    message: 'Configurer le paiement fractionné',
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── ENCAISSER button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: cartState.items.isEmpty || checkoutState.isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
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
                            updatedItems[i] = updatedItems[i]
                                .copyWith(serialNumber: serial);
                            effectiveCart =
                                effectiveCart.copyWith(items: updatedItems);
                          }
                        }

                        // Epic 26 — Prescription dialog (AC2 — FR94)
                        final needsPrescription = effectiveCart.items.any(
                          (i) =>
                              !i.isFreeItem && i.product.requiresPrescription,
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
                              customerName: selectedCustomer?.name,
                            ),
                          );
                        }
                      },
                child: checkoutState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENCAISSER',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment method chip ───────────────────────────────────────────────────────

class _PayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A73E8) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF1A73E8) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
