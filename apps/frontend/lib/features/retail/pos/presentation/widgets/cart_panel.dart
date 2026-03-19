import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/core/services/receipt_service.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/customer_selection_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/parked_carts_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/discount_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/receipt_dialog.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final isManager =
        userProfile?.role == 'manager' || userProfile?.role == 'owner';

    // Listen for errors/success
    ref.listen(checkoutControllerProvider, (_, state) {
      state.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de paiement : $err'),
            backgroundColor: Colors.red,
          ),
        ),
        data: (_) async {
          _showPostCheckoutDialog(context, ref, cartState);
        },
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
      // Reset warning after display
      ref.read(parentStockWarningProvider.notifier).state = null;
    });

    return Container(
      width: 350,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          AppBar(
            title: const Text('Panier',
                style: TextStyle(color: Colors.black)),
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
                    builder: (context) => const ParkedCartsDialog(),
                  );
                },
                icon:
                    const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                tooltip: 'Ventes en attente',
              ),
              IconButton(
                onPressed: isManager
                    ? () => ref.read(cartProvider.notifier).clearCart()
                    : () => _showPermissionDenied(context),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          _buildCustomerHeader(context, ref),
          Expanded(
            child: ListView.builder(
              itemCount: cartState.items.length,
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.unitType != 'piece'
                          ? '${item.quantity} ${item.product.weightUnit ?? item.product.unitType} × ${_fcfa(item.unitPrice)}'
                          : '${item.quantity.toInt()} x ${_fcfa(item.product.price)}'),
                      if (item.discountAmount > 0)
                        Text(
                          'Remise : ${item.discountType == 'PERCENTAGE' ? '${item.discountAmount}%' : _fcfa(item.discountAmount)}',
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fcfa(item.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note),
                        onPressed: isManager
                            ? () => showDialog(
                                  context: context,
                                  builder: (context) =>
                                      DiscountDialog(item: item),
                                )
                            : () => _showPermissionDenied(context),
                        tooltip: 'Appliquer une remise',
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: isManager
                            ? () => ref
                                .read(cartProvider.notifier)
                                .removeProduct(item.product)
                            : () => _showPermissionDenied(context),
                      ),
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
                    const Text('Total :',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      _fcfa(cartState.totalAmount),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: cartState.items.isEmpty
                            ? null
                            : () =>
                                _showParkDialog(context, ref, cartState),
                        icon: const Icon(Icons.pause),
                        label: const Text('ATTENTE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: cartState.items.isEmpty ||
                                checkoutState.isLoading
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

                                final order = await ref
                                    .read(checkoutControllerProvider.notifier)
                                    .checkout(
                                        cartState, session?.remoteId);
                                if (order != null && context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                        ReceiptDialog(order: order),
                                  );
                                }
                              },
                        child: checkoutState.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('ENCAISSER'),
                      ),
                    ),
                  ],
                ),
                // Sélecteur de mode de paiement
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
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
                        items: [
                          'CASH',
                          'MOBILE_MONEY',
                          'CARD',
                          'CREDIT',
                          'SPLIT',
                        ]
                            .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style:
                                        const TextStyle(fontSize: 12))))
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
                          onPressed: () => _showSplitPaymentDialog(
                              context, ref, cartState),
                          tooltip: 'Configurer le paiement fractionné',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader(BuildContext context, WidgetRef ref) {
    final selectedCustomer = ref.watch(selectedCustomerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: selectedCustomer == null
                ? const Text('Aucun client',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 13))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedCustomer.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text(selectedCustomer.phone ?? 'Sans téléphone',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
          ),
          TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const CustomerSelectionDialog(),
            ),
            child: Text(
              selectedCustomer == null ? 'CHOISIR' : 'CHANGER',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (selectedCustomer != null)
            IconButton(
              icon:
                  const Icon(Icons.close, size: 16, color: Colors.red),
              onPressed: () =>
                  ref.read(selectedCustomerProvider.notifier).state =
                      null,
            ),
        ],
      ),
    );
  }

  void _showParkDialog(
      BuildContext context, WidgetRef ref, CartState cart) {
    final controller =
        TextEditingController(text: 'Client ${DateTime.now().minute}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre en attente'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(labelText: 'Référence'),
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

  void _showPermissionDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Permission refusée : rôle manager requis.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSplitPaymentDialog(
      BuildContext context, WidgetRef ref, CartState cart) {
    final total = cart.totalAmount;
    final Map<String, double> currentSplits =
        Map.from(cart.paymentSplits);

    if (currentSplits.isEmpty) {
      currentSplits['CASH'] = total;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final allocated =
              currentSplits.values.fold(0.0, (sum, v) => sum + v);
          final remaining = (total - allocated).clamp(0.0, total);

          return AlertDialog(
            title: const Text('Paiement fractionné'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total : ${_fcfa(total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Restant : ${_fcfa(remaining)}',
                  style: TextStyle(
                      color: remaining > 0 ? Colors.red : Colors.green),
                ),
                const Divider(),
                ...['CASH', 'MOBILE_MONEY', 'CARD'].map((method) {
                  return Row(
                    children: [
                      Expanded(child: Text(method)),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              suffixText: 'FCFA'),
                          onChanged: (val) {
                            setState(() {
                              currentSplits[method] =
                                  double.tryParse(val) ?? 0.0;
                            });
                          },
                          controller: TextEditingController(
                              text: currentSplits[method]
                                      ?.toStringAsFixed(0) ??
                                  '0')
                            ..selection = TextSelection.fromPosition(
                              TextPosition(
                                  offset: (currentSplits[method]
                                              ?.toStringAsFixed(0) ??
                                          '0')
                                      .length),
                            ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: remaining == 0
                    ? () {
                        ref
                            .read(cartProvider.notifier)
                            .updatePaymentSplits(currentSplits);
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPostCheckoutDialog(
      BuildContext context, WidgetRef ref, CartState cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle_outline,
            color: Colors.green, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vente réussie !',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total : ${_fcfa(cart.totalAmount)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FERMER'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final userProfile = ref.read(userProfileProvider).value;
              final activeTenantId = ref.read(activeTenantProvider);

              final tenantName = userProfile?.memberships
                      .where((m) => m.tenantId == activeTenantId)
                      .firstOrNull
                      ?.tenantName ??
                  'Scalario POS';

              await ReceiptService.generateAndPrintReceipt(
                  cart, tenantName);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.print),
            label: const Text('IMPRIMER LE REÇU'),
          ),
        ],
      ),
    );
  }
}
