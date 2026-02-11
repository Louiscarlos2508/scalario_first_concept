import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/pos/presentation/state/cart_state.dart';
import 'package:frontend/core/services/receipt_service.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/pos/presentation/widgets/customer_selection_dialog.dart';
import 'package:frontend/features/pos/presentation/widgets/receipt_dialog.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final isManager = userProfile?.role == 'manager' || userProfile?.role == 'owner';

    // Listen for errors/success
    ref.listen(checkoutControllerProvider, (_, state) {
      state.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout Failed: $err'), backgroundColor: Colors.red),
        ),
        data: (_) async {
           _showPostCheckoutDialog(context, ref, cartState);
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
              IconButton(
                onPressed: () {
                  final parked = ref.watch(parkedCartsProvider);
                  if (parked.isEmpty) return;
                  _showParkedCarts(context, ref, parked);
                },
                icon: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                tooltip: 'Parked Sales',
              ),
              IconButton(
                onPressed: isManager 
                  ? () => ref.read(cartProvider.notifier).clearCart() 
                  : () => _showPermissionDenied(context), 
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              )
            ]
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
                      Text('${item.quantity} x \$${item.product.price.toStringAsFixed(2)}'),
                      if (item.discountAmount > 0)
                        Text(
                          'Discount: ${item.discountType == 'PERCENTAGE' ? '${item.discountAmount}%' : '\$${item.discountAmount}'}',
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit_note),
                        onPressed: isManager 
                          ? () => _showDiscountDialog(context, ref, item)
                          : () => _showPermissionDenied(context),
                        tooltip: 'Apply Discount',
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: isManager 
                          ? () => ref.read(cartProvider.notifier).removeProduct(item.product)
                          : () => _showPermissionDenied(context),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: cartState.items.isEmpty 
                          ? null 
                          : () => _showParkDialog(context, ref, cartState),
                        icon: const Icon(Icons.pause),
                        label: const Text('HOLD'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: cartState.items.isEmpty || checkoutState.isLoading 
                          ? null 
                            : () async {
                                final session = ref.read(sessionProvider).value;
                                final selectedCustomer = ref.read(selectedCustomerProvider);
                                
                                if (cartState.paymentMethod == 'CREDIT' && selectedCustomer == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a customer for Credit sale'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                
                                final order = await ref.read(checkoutControllerProvider.notifier).checkout(cartState, session?.remoteId);
                                if (order != null && context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => ReceiptDialog(order: order),
                                  );
                                }
                              },
                        child: checkoutState.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('PAY & PRINT'),
                      ),
                    ),
                  ],
                ),
                // Payment Method Selector
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: cartState.paymentMethod,
                    underline: Container(),
                    items: ['CASH', 'MOBILE_MONEY', 'CARD', 'CREDIT', 'SPLIT']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(cartProvider.notifier).updatePaymentMethod(val);
                      }
                    },
                  ),
                  if (cartState.paymentMethod == 'SPLIT')
                    IconButton(
                      icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                      onPressed: () => _showSplitPaymentDialog(context, ref, cartState),
                      tooltip: 'Configure Splits',
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
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: selectedCustomer == null
                ? const Text('No customer selected', style: TextStyle(color: Colors.grey, fontSize: 13))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedCustomer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(selectedCustomer.phone ?? 'No phone', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
          ),
          TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const CustomerSelectionDialog(),
            ),
            child: Text(selectedCustomer == null ? 'SELECT' : 'CHANGE', style: const TextStyle(fontSize: 12)),
          ),
          if (selectedCustomer != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              onPressed: () => ref.read(selectedCustomerProvider.notifier).state = null,
            ),
        ],
      ),
    );
  }

  void _showParkDialog(BuildContext context, WidgetRef ref, CartState cart) {
    final controller = TextEditingController(text: 'Customer ${DateTime.now().minute}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Park Sale'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reference/Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(parkedCartsProvider.notifier).parkCart(cart, controller.text);
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showParkedCarts(BuildContext context, WidgetRef ref, List<CartState> parked) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Parked Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: parked.length,
                itemBuilder: (context, index) {
                  final cart = parked[index];
                  return ListTile(
                    title: Text(cart.name ?? 'Unnamed'),
                    subtitle: Text('${cart.items.length} items - \$${cart.totalAmount.toStringAsFixed(2)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref.read(cartProvider.notifier).replaceCart(cart);
                      ref.read(parkedCartsProvider.notifier).removeParkedCart(cart);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permission Denied: Manager role required.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSplitPaymentDialog(BuildContext context, WidgetRef ref, CartState cart) {
    final total = cart.totalAmount;
    final Map<String, double> currentSplits = Map.from(cart.paymentSplits);
    
    // Initialize if empty
    if (currentSplits.isEmpty) {
      currentSplits['CASH'] = total;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final allocated = currentSplits.values.fold(0.0, (sum, v) => sum + v);
          final remaining = (total - allocated).clamp(0.0, total);

          return AlertDialog(
            title: const Text('Split Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Remaining: \$${remaining.toStringAsFixed(2)}', style: TextStyle(color: remaining > 0 ? Colors.red : Colors.green)),
                const Divider(),
                ...['CASH', 'MOBILE_MONEY', 'CARD'].map((method) {
                  return Row(
                    children: [
                      Expanded(child: Text(method)),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(prefixText: '\$'),
                          onChanged: (val) {
                            setState(() {
                              currentSplits[method] = double.tryParse(val) ?? 0.0;
                            });
                          },
                          controller: TextEditingController(text: currentSplits[method]?.toStringAsFixed(2) ?? '0.00')
                            ..selection = TextSelection.fromPosition(TextPosition(offset: (currentSplits[method]?.toStringAsFixed(2) ?? '0.00').length)),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: remaining == 0 
                  ? () {
                      ref.read(cartProvider.notifier).updatePaymentSplits(currentSplits);
                      Navigator.pop(context);
                    }
                  : null,
                child: const Text('Confirm'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showPostCheckoutDialog(BuildContext context, WidgetRef ref, CartState cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sale Successful!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total: \$${cart.totalAmount.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final tenantName = userProfile?.memberships
                      .firstWhere((m) => m.tenantId == ref.read(activeTenantProvider))
                      .tenantName ?? 
                  'Scalario POS';
              await ReceiptService.generateAndPrintReceipt(cart, tenantName);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.print),
            label: const Text('PRINT RECEIPT'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, WidgetRef ref, dynamic item) {
    final controller = TextEditingController(text: item.discountAmount.toString());
    var type = item.discountType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Discount: ${item.product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              Row(
                children: [
                  const Text('Type:'),
                  Radio<String>(value: 'FIXED', groupValue: type, onChanged: (v) => setState(() => type = v!)),
                  const Text('\$'),
                  Radio<String>(value: 'PERCENTAGE', groupValue: type, onChanged: (v) => setState(() => type = v!)),
                  const Text('%'),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text) ?? 0.0;
                ref.read(cartProvider.notifier).updateItemDiscount(item.product.remoteId!, amount, type);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
