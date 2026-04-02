import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_helpers.dart';

void showSplitPaymentDialog(
    BuildContext context, WidgetRef ref, CartState cart) {
  showDialog(
    context: context,
    builder: (_) => _SplitPaymentDialog(cart: cart, ref: ref),
  );
}

class _SplitPaymentDialog extends StatefulWidget {
  final CartState cart;
  final WidgetRef ref;
  const _SplitPaymentDialog({required this.cart, required this.ref});

  @override
  State<_SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends State<_SplitPaymentDialog> {
  static const _methods = ['CASH', 'MOBILE_MONEY', 'CARD'];
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, double> _splits;

  @override
  void initState() {
    super.initState();
    _splits = Map.from(widget.cart.paymentSplits);
    if (_splits.isEmpty) _splits['CASH'] = widget.cart.totalAmount;
    _controllers = {
      for (final m in _methods)
        m: TextEditingController(
            text: (_splits[m] ?? 0.0).toStringAsFixed(0))
    };
    for (final m in _methods) {
      _controllers[m]!.addListener(() {
        setState(
            () => _splits[m] = double.tryParse(_controllers[m]!.text) ?? 0.0);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _allocated =>
      _splits.values.fold(0.0, (s, v) => s + v);
  double get _remaining =>
      (widget.cart.totalAmount - _allocated).clamp(0.0, widget.cart.totalAmount);

  String _label(String m) => switch (m) {
        'CASH' => 'Espèces',
        'MOBILE_MONEY' => 'Mobile Money',
        'CARD' => 'Carte bancaire',
        _ => m,
      };

  IconData _icon(String m) => switch (m) {
        'CASH' => Icons.payments_outlined,
        'MOBILE_MONEY' => Icons.phone_android_outlined,
        'CARD' => Icons.credit_card_outlined,
        _ => Icons.attach_money,
      };

  @override
  Widget build(BuildContext context) {
    final done = _remaining == 0;

    return Dialog(
      shape: kSheetDialogShape,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            const SheetDialogHeader(
              icon: Icons.call_split_outlined,
              iconColor: kSheetBlue,
              title: 'Paiement mixte',
              subtitle: 'Répartissez le montant total',
            ),
            const SizedBox(height: 16),

            // ── Total / Remaining summary ─────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kSheetSlate50,
                border: Border.all(color: kSheetSlate200, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 11, color: kSheetSlate500)),
                        Text(
                          fcfa(widget.cart.totalAmount),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kSheetSlate900),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: kSheetSlate200),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Restant',
                              style: TextStyle(
                                  fontSize: 11, color: kSheetSlate500)),
                          Text(
                            fcfa(_remaining),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: done ? kSheetGreen : kSheetRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Method inputs ─────────────────────────────────────────────
            ...List.generate(_methods.length, (i) {
              final m = _methods[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kSheetBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_icon(m), size: 18, color: kSheetBlue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_label(m),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kSheetSlate900)),
                    ),
                    SizedBox(
                      width: 115,
                      child: TextField(
                        controller: _controllers[m],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          suffixText: 'FCFA',
                          filled: true,
                          fillColor: kSheetSlate50,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: kSheetSlate200, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: kSheetSlate200, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: kSheetBlue, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            SheetActionRow(
              confirmLabel: 'Confirmer',
              onConfirm: done
                  ? () {
                      widget.ref
                          .read(cartProvider.notifier)
                          .updatePaymentSplits(_splits);
                      Navigator.pop(context);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
