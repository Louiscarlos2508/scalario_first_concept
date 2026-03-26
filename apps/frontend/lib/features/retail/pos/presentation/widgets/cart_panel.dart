import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/customer_selection_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/parked_carts_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/discount_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/receipt_dialog.dart';
import 'package:frontend/features/shared/catalog/data/models/price_level.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/serial_input_dialog.dart';
import 'prescription_input_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/reservation_deposit_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/pos_reservations_sheet.dart';
import 'package:frontend/features/shared/reports/presentation/screens/sales_history_screen.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';

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

    // Listen for errors — success is handled by ReceiptDialog in onPressed
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
      // Reset warning after display
      ref.read(parentStockWarningProvider.notifier).state = null;
    });

    return Container(
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
                    isScrollControlled: true,
                    useSafeArea: true,
                    showDragHandle: true,
                    builder: (context) => const ParkedCartsDialog(),
                  );
                },
                icon:
                    const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                tooltip: 'Ventes en attente',
              ),
              IconButton(
                onPressed: cartState.items.isEmpty
                    ? null
                    : () => ref.read(cartProvider.notifier).clearCart(),
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
                final hasPromo = item.appliedPromoId != null && !item.isFreeItem;
                final hasDiscount = item.discountAmount > 0 && !hasPromo;
                return ListTile(
                  onLongPress: isManager && !item.isFreeItem
                      ? () => _showPriceLevelOverride(context, ref, index, item)
                      : null,
                  title: Row(
                    children: [
                      Expanded(child: Text(item.isFreeItem
                          ? '${item.product.name} (offert)'
                          : item.product.name)),
                      // AC3 (Story 25-7) — PROMO badge
                      if (hasPromo)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PROMO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AC5 (Story 25-3) — variant label
                      if (item.variantLabel != null)
                        Text(item.variantLabel!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.blueGrey)),
                      // Price line — strikethrough original + green discounted
                      if (hasPromo)
                        Row(
                          children: [
                            Text(
                              item.product.unitType != 'piece'
                                  ? '${item.quantity} ${item.product.weightUnit ?? item.product.unitType} × ${_fcfa(item.unitPrice)}'
                                  : '${item.quantity.toInt()} × ${_fcfa(item.unitPrice)}',
                              style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Text(_fcfa(item.total),
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        )
                      else
                        Text(item.product.unitType != 'piece'
                            ? '${item.quantity} ${item.product.weightUnit ?? item.product.unitType} × ${_fcfa(item.unitPrice)}'
                            : item.isFreeItem
                                ? '${item.quantity.toInt()} × 0 FCFA'
                                : '${item.quantity.toInt()} × ${_fcfa(item.unitPrice)}'),
                      // Promo label
                      if (hasPromo && item.appliedPromoLabel != null)
                        Text(item.appliedPromoLabel!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.green)),
                      // AC3 (Story 25-5) — price level chip
                      if (item.appliedPriceLevelLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Chip(
                            key: Key('price_level_chip_$index'),
                            label: Text(item.appliedPriceLevelLabel!),
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.blue.withAlpha(30),
                          ),
                        ),
                      if (hasDiscount)
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
                        item.isFreeItem ? '0 FCFA' : _fcfa(item.total),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.isFreeItem ? Colors.green : null),
                      ),
                      if (!item.isFreeItem) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_note),
                          onPressed: isManager
                              ? () => showDialog(
                                    context: context,
                                    builder: (context) =>
                                        DiscountDialog(item: item),
                                  )
                              : null,
                          tooltip: 'Appliquer une remise',
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => ref
                              .read(cartProvider.notifier)
                              .removeProduct(item.product),
                        ),
                      ],
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
                OverflowBar(
                  spacing: 8,
                  overflowSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      onPressed: cartState.items.isEmpty
                          ? null
                          : () => _showParkDialog(context, ref, cartState),
                      icon: const Icon(Icons.pause),
                      label: const Text('ATTENTE'),
                    ),
                    if ((userProfile?.role ?? '') != 'cashier')
                      OutlinedButton.icon(
                        onPressed: () {
                          final role = userProfile?.role ?? '';
                          final isCommercial = role == 'commercial';
                          // Owner voit toutes les ventes (7j),
                          // commercial voit uniquement ses ventes du jour.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SalesHistoryScreen(
                                fixedUserId:
                                    isCommercial ? userProfile?.id : null,
                                initialPeriod: isCommercial ? 'today' : '7d',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.undo, color: Colors.orange),
                        label: const Text(
                          'RETOUR',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: cartState.items.isEmpty
                          ? null
                          : () => showDialog<void>(
                                context: context,
                                builder: (_) => ReservationDepositDialog(
                                  cartState: cartState,
                                ),
                              ),
                      icon: const Icon(Icons.bookmark_border,
                          color: Colors.purple),
                      label: const Text(
                        'RÉSERVATION',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        showDragHandle: true,
                        builder: (_) => const FractionallySizedBox(
                          heightFactor: 0.85,
                          child: PosReservationsSheet(),
                        ),
                      ),
                      icon: const Icon(Icons.bookmark_added_outlined,
                          color: Colors.teal),
                      label: const Text(
                        'EN COURS',
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
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

                                // Epic 26 — Collect serial numbers for items that require tracking
                                CartState effectiveCart = cartState;
                                for (int i = 0; i < cartState.items.length; i++) {
                                  final item = cartState.items[i];
                                  if (item.isFreeItem) continue;
                                  final trackSerial = item.product.trackSerialNumbers;
                                  if (trackSerial && item.serialNumber == null) {
                                    if (!context.mounted) return;
                                    final serial = await showSerialInputDialog(
                                      context,
                                      productName: item.product.name,
                                    );
                                    if (serial == null) return; // user cancelled
                                    final updatedItems = List<CartItem>.from(effectiveCart.items);
                                    updatedItems[i] = updatedItems[i].copyWith(serialNumber: serial);
                                    effectiveCart = effectiveCart.copyWith(items: updatedItems);
                                  }
                                }

                                // Epic 26 — Prescription dialog (AC2 — FR94)
                                final needsPrescription = effectiveCart.items.any(
                                  (i) => !i.isFreeItem && i.product.requiresPrescription,
                                );
                                if (needsPrescription) {
                                  if (!context.mounted) return;
                                  final rx = await showPrescriptionDialog(context);
                                  if (rx == null) return; // user cancelled
                                  effectiveCart = effectiveCart.copyWith(prescriptionData: rx);
                                }

                                final order = await ref
                                    .read(checkoutControllerProvider.notifier)
                                    .checkout(
                                        effectiveCart, session?.remoteId);
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
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('ENCAISSER'),
                  ),
                ),
                // Sélecteur de mode de paiement
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
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
                                child: Text(
                                    paymentMethodLabel(code),
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

  // AC4 (Story 25-5) — Price level override bottom sheet
  void _showPriceLevelOverride(BuildContext context, WidgetRef ref, int index, CartItem item) {
    final tenantId = ref.read(activeTenantProvider);
    final itemId = item.product.remoteId;
    if (tenantId == null || itemId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(catalogRepositoryProvider).getPriceLevels(
          itemId: itemId,
          tenantId: tenantId,
        ),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
          }
          final levels = (snapshot.data ?? []).map(PriceLevel.fromJson).toList();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Changer le niveau de prix', style: Theme.of(ctx).textTheme.titleMedium),
                const Divider(height: 20),
                if (levels.isEmpty)
                  const Text('Aucun niveau configuré pour cet article.'),
                ...levels.map((pl) => ListTile(
                  title: Text(pl.label),
                  subtitle: Text('${pl.price.toStringAsFixed(0)} FCFA${pl.minQty != null ? ' · min ${pl.minQty}' : ''}'),
                  onTap: () {
                    ref.read(cartProvider.notifier).applyPriceLevel(index, pl);
                    Navigator.of(ctx).pop();
                  },
                )),
              ],
            ),
          );
        },
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

}
