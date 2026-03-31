import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_helpers.dart';

void showSplitPaymentDialog(
    BuildContext context, WidgetRef ref, CartState cart) {
  final total = cart.totalAmount;
  final Map<String, double> currentSplits = Map.from(cart.paymentSplits);

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
                'Total : ${fcfa(total)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Restant : ${fcfa(remaining)}',
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
                        decoration:
                            const InputDecoration(suffixText: 'FCFA'),
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
